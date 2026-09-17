# Proyecto Final Capstone: Sistema de Streaming End-to-End Desplegado
## Data Platform en AWS con Apache Flink, Apache Iceberg, AWS Glue & Amazon Redshift

**Carrera:** Data Engineering  
**Alumno:** Samuel Bustos Puntis  
**Repositorio Oficial:** [https://github.com/samuelbustosp/terraform-data-platform](https://github.com/samuelbustosp/terraform-data-platform)  
**Entregable Final:** `Samuel_Bustos_Capstone_RealTime.pdf` | Documento DAAT: `DAAT_Samuel_Bustos_Capstone_RealTime.docx`

---

## 1. Descripción de la Plataforma

Este proyecto implementa la solución capstone de una **Plataforma de Datos de Streaming End-to-End** en AWS utilizando **Terraform** bajo una arquitectura modular y automatizada. La plataforma resuelve la ingesta, procesamiento continuo con estado (*stateful stream processing*), persistencia transaccional y analítica federada de eventos de telemetría urbana en tiempo real.

La arquitectura se fundamenta en un patrón analítico dual (**Dual-Path Streaming Architecture**):

1. **Hot Path (Analítica Operativa de Ultra-Baja Latencia):** Redshift Streaming Ingestion (RSI) consume registros directamente desde los shards de **Amazon Kinesis Data Streams** hacia **Materialized Views (MV)** en **Amazon Redshift**, alcanzando latencias de consulta de segundos sin pasar por almacenamiento intermedio.
2. **Cold / Warm Path (Lakehouse Transaccional y Agregaciones Stateful):** **Amazon Managed Service for Apache Flink (Flink 1.20)** consume el stream de Kinesis aplicando procesamiento basado estrictamente en **Event Time y Watermarks** (`TumblingEventTimeWindows`), confirmando las agregaciones por ventana de 1 minuto en tablas abiertas **Apache Iceberg** alojadas en **Amazon S3** y gobernadas por **AWS Glue Data Catalog**.
3. **Capa Analítica Unificada Federada:** A través de Redshift Spectrum, analistas y científicos de datos consultan en una misma sesión SQL (`JOIN`) las anomalías y desviaciones de la telemetría en vivo frente a los promedios históricos consolidados en el Lakehouse Iceberg.

---

## 2. Diagrama de Arquitectura

```text
                        ┌────────────────────────────────────────────────────────┐
                        │              Productor Python (Telemetría)             │
                        │             (scripts/sensor_producer.py)               │
                        └───────────────────────────┬────────────────────────────┘
                                                    │ PutRecord (JSON UTC)
                                                    ▼
                        ┌────────────────────────────────────────────────────────┐
                        │             Amazon Kinesis Data Streams                │
                        │              (pre-entrega1-dev-stream)                 │
                        │       2 Shards / Cifrado KMS / Retención 24h           │
                        └─────────────┬────────────────────────────┬─────────────┘
                                      │                            │
             ┌────────────────────────┘                            └────────────────────────┐
             │ Consumo continuo por Shards                                                  │ Redshift Streaming Ingestion
             │ (GetRecords / Credit-based)                                                  │ (Direct Shard Scan sin S3)
             ▼                                                                              ▼
  ┌─────────────────────────────────────┐                                        ┌─────────────────────────────────────┐
  │   Managed Service for Apache Flink   │                                        │           Amazon Redshift           │
  │        (Apache Flink 1.20 Job)      │                                        │          (Clúster RA3.large)        │
  │   - Watermarks (10s OutOfOrderness) │                                        │         Base: analytics_db          │
  │   - Ventana Tumbling Event Time 1m  │                                        └──────────────────┬──────────────────┘
  │   - Checkpoints cada 60s (RocksDB)  │                                                           │
  └──────────────────┬──────────────────┘                                                           │
                     │ Iceberg Sink (2PC)                                                           │
                     ▼                                                                              │
  ┌─────────────────────────────────────┐                                                           │
  │        AWS Glue Data Catalog        │◀──────────────────────────────────────────────────────────┤ Redshift Spectrum
  │          (lakehouse_db)             │                                                           │ External Schema: lakehouse_catalog
  │      Tabla: sensor_aggregates       │                                                           │
  └──────────────────┬──────────────────┘                                                           ▼
                     │ Metadatos + Punteros                                      ┌─────────────────────────────────────┐
                     ▼                                                           │          Materialized View          │
  ┌─────────────────────────────────────┐                                        │     mv_sensor_telemetry_stream      │
  │         Amazon S3 Lakehouse         │                                        │  - CAN_JSON_PARSE (Schema Drift)    │
  │ (coderhouse-datalake-raw-...-2026)  │                                        │  - Tipado nativo + Payload SUPER    │
  │        Archivos Parquet + Avro      │                                        └──────────────────┬──────────────────┘
  └─────────────────────────────────────┘                                                           │
                                                                                                    ▼
                                                                                 ┌─────────────────────────────────────┐
                                                                                 │          CONSULTA FEDERADA          │
                                                                                 │      JOIN: Stream + Lakehouse       │
                                                                                 │   Desviaciones Temp & AQI en Vivo   │
                                                                                 └─────────────────────────────────────┘
```

---

## 3. Estructura Oficial del Repositorio

El proyecto cumple de forma estricta con la estructura de carpetas requerida para la entrega final:

```text
terraform-data-platform/
│
├── flink-app/                                   <- Código fuente Java de Apache Flink
│   ├── pom.xml                                  <- Flink 1.20, Iceberg 1.7.1, AWS SDK v2
│   ├── src/main/java/com/coderhouse/flink/
│   │   ├── UrbanSensorsJob.java                 <- Pipeline Event Time, Watermarks, Iceberg Sink
│   │   ├── SensorEvent.java                     <- POJO con parser robusto de epoch millis
│   │   └── SensorAggregate.java                 <- Acumulador con timestamp de fin de ventana
│   └── target/
│       └── urban-sensors-flink-1.0-SNAPSHOT.jar <- Binario compilado y desplegado a S3
│
├── sql/                                         <- Scripts SQL analíticos para Redshift
│   └── redshift_streaming_ingestion.sql         <- Script consolidado en 4 fases (RSI, Iceberg, JOIN, RBAC)
│
├── terraform/                                   <- Infraestructura como Código (IaC)
│   ├── bootstrap/                               <- S3 bucket remoto de tfstate y tabla DynamoDB locks
│   │   ├── main.tf
│   │   ├── provider.tf
│   │   ├── variables.tf
│   │   └── terraform.tfvars
│   ├── environments/
│   │   └── dev/                                 <- Entorno dev con orquestación de todos los módulos
│   │       ├── backend.tf                       <- Remote backend S3 con DynamoDB lock
│   │       ├── main.tf                          <- Wiring de modules: network, storage, identity, kinesis, flink, redshift
│   │       ├── provider.tf                      <- AWS Provider v5.100
│   │       ├── variables.tf
│   │       ├── outputs.tf
│   │       └── terraform.tfvars
│   └── modules/
│       ├── network/                             <- VPC, Subnets privadas, Route Tables, S3 Endpoint
│       ├── storage/                             <- S3 Data Lake modular con versionado
│       ├── identity/                            <- Roles IAM Least Privilege por prefijo de S3
│       ├── kinesis/                             <- Kinesis Stream (2 shards, KMS), Firehose, CloudWatch Alarms
│       ├── flink/                               <- Managed Service for Apache Flink 1.20, Checkpointing y Logging
│       └── redshift/                            <- Clúster RA3.large, RSI IAM, Subnet Group, Security Group
│
├── scripts/                                     <- Productores y utilidades
│   ├── sensor_producer.py                       <- Generador de telemetría continua de sensores urbanos
│   └── convert_md_to_docx.py                    <- Conversor automatizado del informe técnico a Word
│
├── DAAT_Samuel_Bustos_Capstone_RealTime.md      <- Documento de Arquitectura y Auditoría Técnica en Markdown
├── DAAT_Samuel_Bustos_Capstone_RealTime.docx    <- Documento formal en Word listo para anexar capturas
└── README.md                                    <- Documentación general del repositorio
```

---

## 4. Aspectos Técnicos Destacados de la Solución

### 4.1. Manejo de Temporalidad: Event Time y Watermarks en Apache Flink
El sistema procesa eventos fundamentándose en la estampa de tiempo real de los sensores (`timestamp`), independientemente de los retrasos en la red:
* **Watermark Strategy:** Configurado con `WatermarkStrategy.<SensorEvent>forBoundedOutOfOrderness(Duration.ofSeconds(10))`, permitiendo procesar eventos que arriben con hasta 10 segundos de retraso.
* **Control de Inactividad (`withIdleness`):** Se aplica `.withIdleness(Duration.ofMinutes(1))` para garantizar que si un shard de Kinesis no recibe tráfico continuo, el avance del Watermark global no se congele y las ventanas temporales puedan cerrarse.
* **Ventanas Tumbling:** Se definen ventanas no solapadas de 1 minuto (`TumblingEventTimeWindows.of(Time.minutes(1))`).
* **Precisión de Metadatos:** La función de procesamiento de ventana (`SensorWindowProcessFunction`) asigna el fin exacto de la ventana de Event Time (`context.window().getEnd()`) al campo `event_time_millis` persistido en Apache Iceberg.

### 4.2. Tolerancia a Fallos, Estado Stateful y Semántica Exactly-Once
* **Snapshots Distribuidos (Chandy-Lamport):** Flink ejecuta checkpoints asíncronos cada 60.000 ms hacia Amazon S3 con una pausa mínima de 5.000 ms.
* **Two-Phase Commit (2PC) en Iceberg:** Los archivos Parquet generados en S3 durante una ventana abierta no son confirmados en los metadatos de Iceberg hasta que el checkpoint global concluye satisfactoriamente (`notifyCheckpointComplete`). En caso de fallo de un TaskManager, Flink reinicia desde el último checkpoint confirmado y rebobina los Shard Iterators de Kinesis a los números de secuencia exactos, evitando por diseño registros duplicados o incompletos (*Exactly-Once Processing*).
* **Deduplicación en Redshift:** Redshift Streaming Ingestion mantiene seguimiento inmutable de los números de secuencia y shard IDs procesados, previniendo ingesta duplicada en la vista materializada.

### 4.3. Flujo de Presión (Backpressure) y Resiliencia
* **Contrapresión en Flink:** El control de flujo basado en créditos (*credit-based flow control*) de Flink propaga la lentitud desde el sumidero de S3/Glue hacia los búferes de entrada del `KinesisSource`.
* **Kinesis como Shock Absorber:** Al frenarse las llamadas a `GetRecords`, **Amazon Kinesis actúa como el amortiguador desacoplado definitivo**, reteniendo de forma durable los registros hasta por 24 horas sin pérdida de datos ni consumo adicional de memoria en los nodos de cómputo.
* **Aislamiento en Redshift:** El escaneo directo de shards por parte de Redshift es 100% independiente de Flink. Si Redshift realiza consultas masivas, el lag resultante no degrada el flujo hacia el Data Lake.

### 4.4. Seguridad IAM Estricta (Zero Wildcards en Producción)
En cumplimiento del criterio de aceptación global de seguridad:
* **Sin permisos `*` en producción:** Se eliminaron todos los recursos comodín en las políticas de IAM. Los permisos de CloudWatch Logs en Flink y Firehose se encuentran estrictamente acotados al ARN de sus respectivos Log Groups (`"${aws_cloudwatch_log_group.flink.arn}:*"`).
* **Control de Acceso Basado en Roles (RBAC):** Se define el rol `analytics_role` en Redshift para restringir el acceso del equipo analítico únicamente a consultas `SELECT` sobre la vista materializada y las tablas federadas de Iceberg, aislando las credenciales del usuario administrador (`adminuser`).
* **Alcance Granular de S3:** Las políticas de acceso a almacenamiento delimitan los permisos a nivel de prefijo (`/raw/*`, `/processed/*`, `/lakehouse/*`, `/ingesta/*`).

---

## 5. Matriz de Parámetros Críticos

| Servicio | Parámetro | Valor Configurado | Justificación de Ingeniería |
| :--- | :--- | :--- | :--- |
| **Kinesis Data Streams** | Shard Count | `2 Shards` | Rendimiento de 2 MB/s y 2.000 reg/s con distribución uniforme por `sensor_id`. |
| **Kinesis Data Streams** | Retention Period | `24 horas` | Ventana de absorción de caídas temporales de procesamiento sin sobrecosto de almacenamiento. |
| **Kinesis Data Streams** | Cifrado | `KMS (alias/aws/kinesis)` | Cifrado transparente en reposo para cumplimiento normativo. |
| **Apache Flink** | Runtime | `FLINK-1_20` | Compatibilidad total con Apache Iceberg 1.7.1 y AWS Glue Catalog. |
| **Apache Flink** | Paralelismo / KPU | `1 KPU (Paralelismo 1)` | Dimensionamiento balanceado para cargas de laboratorio sin gasto innecesario. |
| **Apache Flink** | Checkpoint Interval | `60.000 ms` | Frecuencia de sincronización de snapshots en S3 y commits transaccionales en Iceberg. |
| **Apache Flink** | Temporalidad | `Event Time` | Agrupación temporal según el timestamp del sensor con tolerancia de 10s de desorden. |
| **Apache Iceberg** | Metastore | `AWS Glue Catalog` | Catálogo serverless gobernado y compatible con Redshift Spectrum y Athena. |
| **Amazon Redshift** | Tipo de Nodo | `ra3.large (Single-Node)` | Separación de cómputo y almacenamiento con Redshift Managed Storage (RMS). |
| **Amazon Redshift** | Política de Refresco | `Programada / 60s` | Refresco incremental acotado que preserva el rendimiento transaccional del motor. |

---

## 6. Guía de Reproducibilidad Paso a Paso para el Auditor

Para desplegar y verificar el stack completo de forma 100% automatizada:

### 6.1. Requisitos Previos
* AWS CLI configurado con credenciales de administrador en la región `us-east-1`.
* Terraform v1.5+ instalado.
* Java 17 (JDK) y Apache Maven 3.9+ instalados.
* Python 3.10+ con librería `boto3`.

### 6.2. Despliegue de Infraestructura y Pipeline

```bash
# 1. Clonar el repositorio
git clone https://github.com/samuelbustosp/terraform-data-platform.git
cd terraform-data-platform

# 2. Compilar el JAR de Flink con Event Time y Watermarks
cd flink-app
mvn clean package -DskipTests
cd ..

# 3. Inicializar y desplegar el bucket S3 del Data Lake
cd terraform/environments/dev
terraform init
terraform apply -target="module.storage" -auto-approve

# 4. Subir el binario de Flink a S3
aws s3 cp ../../../flink-app/target/urban-sensors-flink-1.0-SNAPSHOT.jar s3://coderhouse-datalake-raw-pre-entrega1-sbustos-2026/flink/urban-sensors-flink.jar

# 5. Desplegar el resto de la infraestructura (VPC, Kinesis, Flink, Glue, Redshift)
terraform apply -auto-approve

# 6. Iniciar la aplicación de Apache Flink (se crea en estado READY)
aws kinesisanalyticsv2 start-application \
    --application-name pre-entrega1-dev-flink \
    --region us-east-1

# 7. Ejecutar el productor de telemetría continua (en una terminal separada)
cd ../../../scripts
python sensor_producer.py
```

### 6.3. Validación Analítica en Amazon Redshift (Query Editor v2)
Conectarse al clúster `pre-entrega1-dev-redshift` en la base `analytics_db` y ejecutar de forma secuencial las fases contenidas en `sql/redshift_streaming_ingestion.sql`:
1. **Fase 1 (Hot Path):** Creación del esquema externo Kinesis y la Materialized View `mv_sensor_telemetry_stream`. Forzar refresco y validar filas con `approximate_arrival_timestamp`.
2. **Fase 2 (Lakehouse Iceberg):** Creación del esquema federado `lakehouse_catalog` hacia Glue y consulta directa a `sensor_aggregates`.
3. **Fase 3 (JOIN Híbrido):** Cruce federado calculando en vivo `temp_deviation` y `aqi_deviation` entre el stream caliente y el histórico consolidado.
4. **Fase 4 (Observabilidad y RBAC):** Consulta de estado de refresco en `SVV_MV_INFO`, escaneo de shards en `SYS_STREAM_SCAN_STATES` y creación de `analytics_role`.

### 6.4. Desmantelamiento y Cero Costo
```bash
cd terraform/environments/dev
terraform destroy -auto-approve
```

---

## 7. Entregables del Proyecto

1. **Documento DAAT en Markdown:** [DAAT_Samuel_Bustos_Capstone_RealTime.md](DAAT_Samuel_Bustos_Capstone_RealTime.md)
2. **Documento DAAT en Word (.docx):** [DAAT_Samuel_Bustos_Capstone_RealTime.docx](DAAT_Samuel_Bustos_Capstone_RealTime.docx)
3. **Informe Final en PDF:** `Samuel_Bustos_Capstone_RealTime.pdf` (generado exportando el documento Word con las capturas de ejecución anexadas).
