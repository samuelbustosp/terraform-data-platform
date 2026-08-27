# Terraform Data Platform

## Description

Este proyecto implementa la infraestructura de una plataforma de datos en AWS utilizando **Terraform** y una arquitectura modular.

La solución está diseñada para soportar un flujo de **ingesta de datos en tiempo real**, desde la generación de eventos hasta su persistencia en un Data Lake sobre Amazon S3.

La infraestructura incluye:

* Networking mediante Amazon VPC.
* Gestión de identidades y permisos mediante IAM.
* Data Lake sobre Amazon S3.
* Kinesis Data Stream para ingesta real-time.
* Kinesis Data Firehose para la entrega de datos crudos hacia S3.
* Procesamiento stateful en tiempo real mediante **AWS Managed Service for Apache Flink**.
* Observabilidad mediante CloudWatch Logs y CloudWatch Alarms.
* Backend remoto para el estado de Terraform.
* Producers simulados mediante Python y Boto3.

---

## Architecture

```text
                  ┌─────────────────────┐
                  │   Python Producer   │
                  │   (sensor_producer) │
                  └──────────┬──────────┘
                             │
                             │ PutRecord (Event Time JSON)
                             ▼
                  ┌─────────────────────┐
                  │  Kinesis Data       │
                  │      Stream         │
                  │                     │
                  │  PROVISIONED        │
                  │  2 Shards           │
                  │  KMS Encryption     │
                  └──────┬───────┬──────┘
                         │       │
            ┌────────────┘       └────────────┐
            │                                 │
            ▼                                 ▼
 ┌─────────────────────┐           ┌─────────────────────┐
 │ Kinesis Data        │           │ Managed Service for │
 │     Firehose        │           │   Apache Flink      │
 │                     │           │                     │
 │ Buffer: 5 MB / 60s  │           │ Event Time & Watermarks
 │ Compresión GZIP     │           │ Tumbling Window (1m)│
 └──────────┬──────────┘           │ Stateful Aggregation│
            │                      └──────────┬──────────┘
            ▼                                 ▼
 ┌─────────────────────┐           ┌─────────────────────┐
 │     Amazon S3       │           │   CloudWatch Logs   │
 │     Data Lake       │           │  /aws/kinesis-      │
 │     (RAW Zone)      │           │   analytics/...     │
 └─────────────────────┘           └─────────────────────┘
```

---

## Project Structure

```text
terraform-data-platform/
│
├── bootstrap/
│   ├── main.tf
│   ├── provider.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── terraform.tfvars
│
├── flink/
│   ├── pom.xml
│   └── src/main/java/com/coderhouse/flink/
│       ├── UrbanSensorsJob.java
│       ├── SensorEvent.java
│       └── SensorAggregate.java
│
├── modules/
│   ├── network/
│   ├── identity/
│   ├── kinesis/
│   │   ├── main.tf
│   │   ├── cloudwatch.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── flink/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
│
├── scripts/
│   └── sensor_producer.py
│
└── environments/
    └── dev/
        ├── backend.tf
        ├── main.tf
        ├── provider.tf
        ├── variables.tf
        ├── outputs.tf
        └── terraform.tfvars
```

---

## Prerequisites

* Terraform >= 1.0
* AWS CLI v2
* Java 11 / 17 y Apache Maven >= 3.8
* Python 3.x
* Boto3
* Cuenta de AWS con credenciales configuradas mediante `aws configure`

Verificar la identidad utilizada:

```bash
aws sts get-caller-identity
```

---

## Bootstrap

El directorio `bootstrap` crea los recursos necesarios para almacenar el estado remoto de Terraform.

Recursos creados:

* Bucket S3 para el archivo `.tfstate`.
* Mecanismo de bloqueo del estado de Terraform.

Ejecutar:

```bash
cd bootstrap

terraform init
terraform plan
terraform apply
```

---

## Development Environment

Una vez creado el backend remoto, desplegar la infraestructura principal:

```bash
cd environments/dev

terraform init -reconfigure
terraform plan
terraform apply
```

---

## Resources Created

### Network

* VPC.
* 2 Private Subnets.
* Private Route Table.
* Route Table Associations.
* S3 Gateway Endpoint.

### Storage

* Amazon S3 Data Lake Bucket (`coderhouse-datalake-raw-...`).

### Identity

* IAM Role para procesamiento de datos.
* IAM Policy para acceso al Data Lake.
* IAM Role para auditoría.
* IAM Policy de solo lectura.
* IAM Role para Kinesis Firehose.
* IAM Role para Managed Apache Flink.

### Real-Time Ingestion (Kinesis Data Stream & Firehose)

* **Amazon Kinesis Data Stream:** Modo `PROVISIONED`, 2 shards, retención de 24h, cifrado KMS (`pre-entrega1-dev-stream`).
* **Kinesis Data Firehose:** Entrega automatizada a S3 con compresión GZIP, particionamiento dinámico por año (`ingesta/year=!{timestamp:yyyy}/`) y buffer de 5 MB / 60 segundos.

---

## Real-Time Processing (Apache Flink)

Se implementó una solución de procesamiento de flujos de datos en tiempo real mediante **AWS Managed Service for Apache Flink** (Kinesis Analytics v2).

### 1. Lógica de Negocio (Urban Sensors)

La aplicación procesa eventos generados por una red de sensores urbanos de calidad ambiental distribuidos geográficamente (`sensor_zona_1` a `sensor_zona_5`).

Cada evento contiene:
* `sensor_id`: Identificador del sensor / zona.
* `temperature`: Medición de temperatura en °C.
* `humidity`: Porcentaje de humedad relativa.
* `air_quality_index`: Índice de calidad del aire (AQI).
* `timestamp`: Fecha y hora de generación en formato `yyyy-MM-dd HH:mm:ss`.

### 2. Lógica Temporal y Watermarks (Event Time)

* **Event Time:** Se extrae el timestamp del payload del evento (`event.getTimestamp()`) y se convierte a época Unix en milisegundos en UTC.
* **Manejo de Out-of-Orderness:** Se implementa `WatermarkStrategy.forBoundedOutOfOrderness(Duration.ofSeconds(10))` para admitir eventos desordenados o retrasados hasta 10 segundos debido a latencia de red.

```java
DataStream<SensorEvent> timedEvents = sensorEvents.assignTimestampsAndWatermarks(
    WatermarkStrategy
        .<SensorEvent>forBoundedOutOfOrderness(Duration.ofSeconds(10))
        .withTimestampAssigner((event, recordTimestamp) -> LocalDateTime
            .parse(event.getTimestamp(), DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"))
            .toInstant(ZoneOffset.UTC)
            .toEpochMilli())
);
```

### 3. Procesamiento Stateful y Ventanas Temporales

* **Particionamiento por Clave:** Se aplica `keyBy(SensorEvent::getSensorId)` para agrupar el estado por cada sensor de forma independiente.
* **Ventanas Tumbling:** Se define una ventana temporal fija de 1 minuto (`TumblingEventTimeWindows.of(Duration.ofMinutes(1))`).
* **Agregación Incremental:** Se utiliza una `AggregateFunction` (`SensorAggregateFunction`) que acumula sumas y conteos en memoria (*Stateful Memory*), emitiendo al cierre de la ventana el promedio de temperatura, promedio de calidad del aire y conteo total de eventos.

### 4. Configuración de Paralelismo y KPUs

En [`modules/flink/main.tf`](file:///c:/Users/Usuario/Documents/Samuel/Universidad/CURSOS/DATA/Data%20Engineer/Modulo0/terraform-data-plataform/modules/flink/main.tf), la configuración de capacidad se definió para un consumo eficiente y controlado:

* **Runtime:** `FLINK-1_20` (Apache Flink 1.20).
* **Paralelismo:** `1`
* **Paralelismo por KPU:** `1` (1 KPU asignada = 1 vCPU + 4 GB RAM).
* **Auto-Scaling:** `false` (desactivado para control de costos predecibles).

### 5. Tolerancia a Fallos y Checkpointing

* **Checkpoints:** `checkpointing_enabled = true`
* **Intervalo:** Cada 60.000 ms (60 segundos).
* **Pausa mínima entre Checkpoints:** 5.000 ms (5 segundos).
* **Almacenamiento de Estado:** Gestionado en Amazon S3 con persistencia automática de snapshots.

---

## Observabilidad y Monitoreo

* **CloudWatch Log Group:** `/aws/kinesis-analytics/pre-entrega1-dev-flink`
* **Log Stream:** `flink-log-stream`
* **Métricas:** Nivel `APPLICATION` y logs en nivel `INFO` con SLF4J para registrar las métricas agregadas por ventana.

---

## Execution and Validation Guide

### 1. Compilar el Artefacto Flink

```bash
cd flink
mvn clean package
```

### 2. Subir el JAR a S3

```bash
aws s3 cp target/urban-sensors-flink-1.0-SNAPSHOT.jar s3://coderhouse-datalake-raw-pre-entrega1-sbustos-2026/flink/urban-sensors-flink.jar
```

### 3. Desplegar la Infraestructura con Terraform

```bash
cd ../environments/dev
terraform apply -auto-approve
```

### 4. Iniciar la Aplicación de Flink

```bash
aws kinesisanalyticsv2 start-application \
  --application-name pre-entrega1-dev-flink \
  --region us-east-1
```

Verificar que el estado cambie a `"RUNNING"`:

```bash
aws kinesisanalyticsv2 describe-application \
  --application-name pre-entrega1-dev-flink \
  --region us-east-1 \
  --query "ApplicationDetail.ApplicationStatus"
```

### 5. Ejecutar el Productor de Sensores

```bash
python scripts/sensor_producer.py
```

### 6. Validar Resultados en S3 y Logs

* **Validar entrega en S3 (Firehose):**
  ```bash
  aws s3 ls s3://coderhouse-datalake-raw-pre-entrega1-sbustos-2026/ingesta/year=2026/
  ```

* **Validar logs de procesamiento en CloudWatch:**
  ```bash
  aws logs get-log-events \
    --log-group-name "/aws/kinesis-analytics/pre-entrega1-dev-flink" \
    --log-stream-name "flink-log-stream" \
    --region us-east-1 \
    --limit 30
  ```

---

## Checkpoint Validation Checklist

* [x] **Consumo y Deserialización:** Conexión de Flink con Kinesis Data Stream (`KinesisStreamsSource`) y mapeo de modelo JSON con Jackson.
* [x] **Lógica Temporal:** Extracción de Event Time y estrategia de Watermarks con tolerancia a retrasos (`BoundedOutOfOrderness`).
* [x] **Procesamiento Stateful:** `KeyedStream` por sensor, ventanas Tumbling de 1 minuto y cálculo acumulativo de métricas con `AggregateFunction`.
* [x] **Tolerancia a Fallos:** Checkpoints periódicos de 60s habilitados y respaldados en S3.
* [x] **Infraestructura con Terraform:** Módulo `modules/flink/` con `aws_kinesisanalyticsv2_application`, roles de IAM con mínimo privilegio y CloudWatch Logging options.
* [x] **Capacidad y Paralelismo:** Configurado en 1 KPU / Paralelismo 1 con auto-scaling desactivado.
* [x] **Validación End-to-End:** Flujo completo probado desde Python Producer ➔ Kinesis ➔ Firehose/S3 & Flink Real-Time Processor.
