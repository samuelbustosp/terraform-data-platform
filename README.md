# Terraform Data Platform - Lakehouse con Apache Iceberg, AWS Glue & Amazon Redshift

## Descripción

Este proyecto implementa la infraestructura completa de una plataforma de datos moderna (**Lakehouse**) en AWS utilizando **Terraform** bajo una arquitectura modular, orientada a streaming en tiempo real y gobernanza centralizada.

La solución abarca desde la ingesta continua de eventos de telemetría de sensores urbanos hasta el procesamiento stateful en streaming con **Apache Flink**, la persistencia transaccional en formato de tablas abiertas **Apache Iceberg** (gobernadas en **AWS Glue Data Catalog**) y la analítica avanzada in-stream de ultra-baja latencia con **Amazon Redshift Streaming Ingestion (RSI)** y **Materialized Views**, permitiendo consultas federadas híbridas que unifican datos en tiempo real con históricos.

### Componentes Principales

* **Networking:** Amazon VPC con subnets privadas y S3 Gateway Endpoint (`modules/network`).
* **Almacenamiento Dedicado:** Módulo modular de Data Lake en Amazon S3 con versionado habilitado (`modules/storage`).
* **Seguridad e Identidad:** Roles y políticas de IAM granulares bajo el principio de mínimo privilegio con alcance por prefijo y plano de control (`modules/identity`).
* **Ingesta Real-Time:** Amazon Kinesis Data Streams (2 shards provisionados, cifrado KMS) y Kinesis Data Firehose (`modules/kinesis`).
* **Procesamiento Streaming:** AWS Managed Service for Apache Flink (Flink 1.20) con ventanas Tumbling y agregación stateful (`modules/flink`).
* **Capa Lakehouse (Persistencia Transaccional):** Apache Iceberg Sink integrado con AWS Glue Data Catalog y almacenamiento en Amazon S3.
* **Analítica In-Stream de Baja Latencia:** Amazon Redshift (nodo `ra3.large`) con Streaming Ingestion directa sobre Kinesis y Materialized Views (`modules/redshift`).
* **Consultas Federadas Híbridas:** Redshift Spectrum sobre AWS Glue Data Catalog para cruce analítico entre eventos en caliente y tablas históricas Iceberg.
* **Motor Analítico Serverless:** Amazon Athena para consultas ad-hoc directas sobre tablas Iceberg.
* **Observabilidad:** Amazon CloudWatch Logs, CloudWatch Alarms y vistas de sistema de Redshift (`SYS_STREAM_SCAN_STATES`, `SVV_MV_INFO`).
* **Infraestructura como Código (IaC):** 100% automatizado con Terraform.

---

## Arquitectura

```text
                        ┌────────────────────────────────────┐
                        │      Python Producer (Telemetría)  │
                        │       (scripts/sensor_producer.py) │
                        └─────────────────┬──────────────────┘
                                          │ PutRecord (JSON)
                                          ▼
                        ┌────────────────────────────────────┐
                        │        Amazon Kinesis Stream       │
                        │      (pre-entrega1-dev-stream)     │
                        │      2 Shards / Cifrado KMS        │
                        └─────────┬────────────────┬─────────┘
                                  │                │
            ┌─────────────────────┘                └────────────────────────┐
            │                                                               │ Redshift Streaming Ingestion
            ▼                                                               │ (Direct Shard Scan)
 ┌──────────────────────┐                                                   ▼
 │ Managed Service for  │                                        ┌────────────────────────────┐
 │     Apache Flink     │                                        │       Amazon Redshift      │
 │   (Flink 1.20 Job)   │                                        │      (Clúster RA3.large)   │
 └──────────┬───────────┘                                        └──────────────┬─────────────┘
            │ Iceberg Sink (2PC)                                                │
            ▼                                                                   │
 ┌──────────────────────┐                                                       │
 │  AWS Glue Catalog    │◀──────────────────────────────────────────────────────┤ External Schema (Iceberg)
 │    (lakehouse_db)    │                  Redshift Spectrum                    │ lakehouse_catalog
 │   sensor_aggregates  │                                                       │
 └──────────┬───────────┘                                                       ▼
            │                                                    ┌────────────────────────────┐
            ▼                                                    │     Materialized View      │
 ┌──────────────────────┐                                        │ mv_sensor_telemetry_stream │
 │      Amazon S3       │                                        │ (JSON Parse + Typings)     │
 │  (Lakehouse Storage) │                                        └──────────────┬─────────────┘
 │ Parquet + Metadatos  │                                                       │
 └──────────────────────┘                                                       ▼
                                                                 ┌────────────────────────────┐
                                                                 │      CONSULTA FEDERADA     │
                                                                 │  JOIN: Stream + Iceberg    │
                                                                 └────────────────────────────┘
```

---

## Estructura Modular del Proyecto

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
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── storage/                      <-- Módulo dedicado de almacenamiento S3
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── identity/                     <-- IAM con Least Privilege por prefijo y plano de control
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── kinesis/
│   │   ├── main.tf
│   │   ├── cloudwatch.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── flink/                        <-- Managed Flink con outputs completos y permisos Glue
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── redshift/                     <-- Clúster RA3.large, roles IAM Kinesis/Glue, Subnet Group y SG
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
│
├── scripts/
│   ├── producer.py
│   ├── sensor_producer.py
│   └── redshift_streaming_ingestion.sql  <-- Script SQL consolidado de Ingesta, MV, JOIN y RBAC
│
├── CheckPoint_Redshift_Bustos_Samuel.md  <-- Documento técnico para exportar a PDF (Pre-entrega 6)
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

## Mejoras de Seguridad y Diseño Modular (Entregas Anteriores)

### 1. Seguridad IAM: Alcance de Recursos S3 por Prefijo Específico
En cumplimiento estricto del principio de mínimo privilegio (*Least Privilege*), las políticas de IAM de procesamiento (`data_processing_s3`) y auditoría (`audit_read_only`) en `modules/identity/main.tf` restringen el acceso a nivel de prefijo específico en lugar del comodín global `/*`:
* `arn:aws:s3:::bucket/raw/*`
* `arn:aws:s3:::bucket/processed/*`
* `arn:aws:s3:::bucket/lakehouse/*`
* `arn:aws:s3:::bucket/ingesta/*`

### 2. Rol de Auditoría Orientado a Plano de Control
Se refactorizó el `assume_role_policy` del rol de auditoría (`aws_iam_role.audit`) en `modules/identity/main.tf` para que no utilice entidades de servicios de aplicación (como Lambda), sino que se configure como un **rol del plano de control / seguridad** asumible por la cuenta de AWS / administradores de seguridad:
```hcl
assume_role_policy = jsonencode({
  Version = "2012-10-17"
  Statement = [
    {
      Effect    = "Allow"
      Principal = {
        AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      }
      Action    = "sts:AssumeRole"
    }
  ]
})
```

### 3. Modularización Completa del Almacenamiento (`modules/storage`)
Se migró la declaración del bucket S3 principal desde el environment `dev/` hacia un módulo dedicado `modules/storage/`, exponiendo `bucket_name`, `bucket_arn` y `bucket_id` para garantizar una arquitectura 100% modular y reutilizable.

### 4. Outputs Expuestos en Módulo Flink
En `modules/flink/outputs.tf` se exponen todos los atributos clave de la aplicación de streaming:
* `application_name`, `application_arn`, `application_version_id`
* `role_arn`, `role_name`
* `log_group_name`, `log_stream_name`

---

## Capa Lakehouse: Apache Iceberg + AWS Glue Data Catalog

En esta fase se implementó la persistencia transaccional del pipeline de streaming, asegurando que la salida procesada por Flink se almacene como tablas formales de **Apache Iceberg**, registradas y gobernadas por **AWS Glue Data Catalog**.

### 1. Infraestructura Declarativa (Terraform)

* **Base de Datos en AWS Glue (`aws_glue_catalog_database`):**
  Se define el metastore lógico `lakehouse_db` en `environments/dev/main.tf`:
  ```hcl
  resource "aws_glue_catalog_database" "lakehouse_db" {
    name        = "lakehouse_db"
    description = "Base de datos para las tablas de Iceberg"
  }
  ```

* **Versionado de S3 (`aws_s3_bucket_versioning`):**
  Se encuentra habilitado dentro de `modules/storage/main.tf` para respaldar la coherencia de metadatos y el control de versiones de Iceberg.

* **Permisos IAM Granulares para Flink (`aws_iam_role_policy`):**
  Se añadieron los permisos requeridos sobre Glue y S3 al rol de ejecución de Managed Flink en `modules/flink/main.tf`:
  ```hcl
  resource "aws_iam_role_policy" "flink_glue" {
    name = "${var.project_name}-${var.environment}-flink-glue-policy"
    role = aws_iam_role.flink.id

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "glue:GetDatabase",
            "glue:GetTable",
            "glue:GetTables",
            "glue:CreateTable",
            "glue:UpdateTable",
            "glue:DeleteTable",
            "glue:GetPartition",
            "glue:GetPartitions",
            "glue:CreatePartition",
            "glue:BatchCreatePartition"
          ]
          Resource = [
            "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:catalog",
            "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:database/default",
            "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:database/lakehouse_db",
            "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/lakehouse_db/*"
          ]
        }
      ]
    })
  }
  ```

---

## Procesamiento en Streaming y Sink de Iceberg (Apache Flink)

La aplicación de Flink (`UrbanSensorsJob.java`) procesa en tiempo real los eventos de sensores urbanos (`temperature`, `humidity`, `air_quality_index`, `timestamp`), calcula agregaciones por ventana tumbling de 1 minuto y escribe los resultados en formato Iceberg.

### 1. Catálogo Glue e IcebergSink en Java

* **Carga de Catálogo:** Se instancia `CatalogLoader.custom` apuntando a `org.apache.iceberg.aws.glue.GlueCatalog` con I/O optimizado en S3 (`org.apache.iceberg.aws.s3.S3FileIO`).
* **Definición de Esquema:** Si la tabla `sensor_aggregates` no existe en Glue, Flink la crea automáticamente con tipos de datos nativos de Iceberg.
* **Mapeo a `RowData` y Sink:** Se convierten los objetos `SensorAggregate` a `GenericRowData` y se envían al `FlinkSink.forRowData`.

```java
// Configuración del Catálogo Glue
Map<String, String> catalogProps = new HashMap<>();
catalogProps.put("type", "iceberg");
catalogProps.put("catalog-impl", "org.apache.iceberg.aws.glue.GlueCatalog");
catalogProps.put("warehouse", "s3://" + lakehouseBucket + "/lakehouse/");
catalogProps.put("io-impl", "org.apache.iceberg.aws.s3.S3FileIO");

CatalogLoader catalogLoader = CatalogLoader.custom(
    "glue_catalog",
    catalogProps,
    new org.apache.hadoop.conf.Configuration(),
    "org.apache.iceberg.aws.glue.GlueCatalog"
);

TableIdentifier tableId = TableIdentifier.of("lakehouse_db", "sensor_aggregates");

// Crear tabla si no existe
Catalog catalog = catalogLoader.loadCatalog();
if (!catalog.tableExists(tableId)) {
    Schema schema = new Schema(
        Types.NestedField.required(1, "sensor_id", Types.StringType.get()),
        Types.NestedField.required(2, "avg_temperature", Types.DoubleType.get()),
        Types.NestedField.required(3, "avg_air_quality", Types.DoubleType.get()),
        Types.NestedField.required(4, "event_count", Types.LongType.get()),
        Types.NestedField.required(5, "event_time_millis", Types.LongType.get())
    );
    catalog.createTable(tableId, schema);
}

TableLoader tableLoader = TableLoader.fromCatalog(catalogLoader, tableId);

// Conversión y Sink
DataStream<RowData> rowDataStream = aggregatedEvents.map(new ToRowDataMapper());

FlinkSink.forRowData(rowDataStream)
    .tableLoader(tableLoader)
    .append();
```

### 2. Checkpointing y Consistencia ACID

Iceberg utiliza un protocolo de commit en dos fases (*Two-Phase Commit*) integrado con el mecanismo de **Checkpointing de Flink**:
* Durante la ventana activa, Flink escribe archivos de datos Parquet directamente en `s3://.../lakehouse/data/`.
* Al completarse cada Checkpoint (configurado a 60 segundos), el operador de commit de Iceberg genera los manifiestos `.avro` y el archivo de metadatos `.metadata.json`, actualizando de forma atómica el puntero en AWS Glue Data Catalog.
* Esto garantiza que los lectores externos (Athena) solo vean datos confirmados, evitando lecturas sucias y logrando semántica *Exactly-Once*.

---

## Estrategia de Particionado y Partition Pruning

### ¿Por qué es crucial el Particionado en Apache Iceberg?
En arquitecturas Lakehouse analíticas, las tablas acumulan millones de eventos. Sin una estrategia de particionado, cualquier consulta SQL requeriría un escaneo completo de la tabla (*Full Table Scan*), incrementando la latencia y los costos de computación.

### Estrategia Recomendada:
1. **Particionado Temporal (`event_time_millis`):** 
   En datasets de series temporales de sensores, se particiona comúnmente a nivel de día o mes mediante particiones ocultas de Iceberg (`days(event_time)`).
2. **Particionado Categórico (`sensor_id`):** 
   Permite aislar las métricas por sensor o zona urbana.

### Conexión con Partition Pruning:
Apache Iceberg almacena estadísticas de mínimos y máximos (*min/max column stats*) y listas de archivos dentro de los manifiestos de metadatos (archivos `.avro` en la carpeta `metadata/`).

Cuando un usuario o dashboard ejecuta una consulta con predicados en Amazon Athena:
```sql
SELECT * 
FROM "lakehouse_db"."sensor_aggregates"
WHERE sensor_id = 'sensor_zona_1'
  AND event_time_millis >= 1788195400000;
```
El motor consulta directamente el árbol de metadatos de Iceberg y aplica **Partition Pruning** y **File Pruning**. Athena lee únicamente los archivos Parquet específicos que contienen los datos solicitados, ignorando el 90%+ del dataset restante.

---

## Guía de Ejecución y Validación

### 1. Compilar el JAR de Flink

```bash
cd flink
mvn clean package -DskipTests
```

### 2. Subir el JAR a Amazon S3

```bash
aws s3 cp target/urban-sensors-flink-1.0-SNAPSHOT.jar s3://coderhouse-datalake-raw-pre-entrega1-sbustos-2026/flink/urban-sensors-flink.jar
```

### 3. Desplegar la Infraestructura con Terraform

```bash
cd ../environments/dev
terraform init
terraform apply -auto-approve
```

### 4. Iniciar la Aplicación de Flink

```bash
aws kinesisanalyticsv2 start-application \
  --application-name pre-entrega1-dev-flink \
  --run-configuration '{"ApplicationRestoreConfiguration":{"ApplicationRestoreType":"SKIP_RESTORE_FROM_SNAPSHOT"}}' \
  --region us-east-1
```

Verificar que el estado sea `"RUNNING"`:
```bash
aws kinesisanalyticsv2 describe-application \
  --application-name pre-entrega1-dev-flink \
  --region us-east-1 \
  --query "ApplicationDetail.ApplicationStatus" \
  --output text
```

### 5. Ingesta de Eventos

#### A. Envío Individual mediante AWS CLI (`aws kinesis put-record`):
Para validar la ingesta directa desde línea de comandos:
```bash
aws kinesis put-record \
  --stream-name pre-entrega1-dev-stream \
  --partition-key sensor_zona_1 \
  --data '{"sensor_id": "sensor_zona_1", "temperature": 26.5, "humidity": 65.0, "air_quality_index": 80, "timestamp": "2026-08-31 14:00:00"}' \
  --region us-east-1
```

#### B. Envío Masivo Continuo mediante Python Producer:
```bash
python scripts/sensor_producer.py
```
*(Dejar corriendo durante 1.5 - 2 minutos para completar la ventana tumbling y el checkpoint).*

### 6. Validación de Resultados

* **Verificar la tabla en AWS Glue Catalog:**
  ```bash
  aws glue get-table --database-name lakehouse_db --name sensor_aggregates --region us-east-1
  ```

* **Listar archivos Parquet y Metadata en S3:**
  ```bash
  aws s3 ls s3://coderhouse-datalake-raw-pre-entrega1-sbustos-2026/lakehouse/ --recursive
  ```

* **Consultar desde Amazon Athena:**
  ```sql
  SELECT 
      sensor_id,
      avg_temperature,
      avg_air_quality,
      event_count,
      from_unixtime(event_time_millis / 1000) AS window_timestamp
  FROM "lakehouse_db"."sensor_aggregates"
  ORDER BY event_time_millis DESC;
  ```

---

## Evidencias de Ejecución

### 1. Consulta SQL en Amazon Athena
```text
+---------------+--------------------+-------------------+-------------+-------------------+
| sensor_id     | avg_temperature    | avg_air_quality   | event_count | event_time_millis |
+---------------+--------------------+-------------------+-------------+-------------------+
| sensor_zona_4 | 25.186666666666667 | 99.88888888888889 | 9           | 1788195420000     |
| sensor_zona_3 | 26.874444444444446 | 86.0              | 9           | 1788195420001     |
| sensor_zona_2 | 29.77              | 123.6666666666666 | 3           | 1788195420001     |
| sensor_zona_5 | 31.895             | 67.75             | 8           | 1788195420001     |
| sensor_zona_1 | 29.1625            | 93.0              | 4           | 1788195420001     |
+---------------+--------------------+-------------------+-------------+-------------------+
```

### 2. Estructura de Metadatos y Datos en S3
```text
lakehouse/lakehouse_db.db/sensor_aggregates/data/00000-0-...-00002.parquet
lakehouse/lakehouse_db.db/sensor_aggregates/data/00000-0-...-00003.parquet
lakehouse/lakehouse_db.db/sensor_aggregates/data/00000-0-...-00004.parquet
lakehouse/lakehouse_db.db/sensor_aggregates/metadata/00000-...metadata.json
lakehouse/lakehouse_db.db/sensor_aggregates/metadata/00001-...metadata.json
lakehouse/lakehouse_db.db/sensor_aggregates/metadata/00002-...metadata.json
lakehouse/lakehouse_db.db/sensor_aggregates/metadata/00003-...metadata.json
lakehouse/lakehouse_db.db/sensor_aggregates/metadata/snap-...avro
```

---

## Capa Analítica Avanzada In-Stream: Amazon Redshift (Pre-entrega 6)

En esta fase se incorporó **Amazon Redshift** como motor analítico de baja latencia acoplado de forma nativa tanto a **Amazon Kinesis Data Streams** (Hot Path) como a **AWS Glue Data Catalog / Apache Iceberg** (Cold/Warm Path).

### 1. Infraestructura de Redshift en Terraform (`modules/redshift`)

* **Clúster Provisionado:** Nodo de cómputo `ra3.large` de nodo único (*single-node*) en subredes privadas.
* **Redshift Streaming Ingestion (RSI):** Conexión directa a nivel de shard con Kinesis Data Streams (`pre-entrega1-dev-stream`) para procesamiento sin staging en S3.
* **Seguridad IAM:** Rol `pre-entrega1-dev-redshift-role` con permisos granulares para Kinesis (`DescribeStreamSummary`, `GetShardIterator`, `GetRecords`, `DescribeStream`, `ListShards`), Glue Catalog (`lakehouse_db`) y S3 (`GetObject`, `ListBucket`).

### 2. Definición de Ingesta y Materialized View (`scripts/redshift_streaming_ingestion.sql`)

```sql
-- 1. Esquema externo sobre Kinesis
CREATE EXTERNAL SCHEMA IF NOT EXISTS kinesis_stream_schema
FROM KINESIS
IAM_ROLE 'arn:aws:iam::985879611495:role/pre-entrega1-dev-redshift-role';

-- 2. Materialized View con modelado JSON, tipado estricto y protección contra Schema Drift
CREATE MATERIALIZED VIEW mv_sensor_telemetry_stream
AS
SELECT
    approximate_arrival_timestamp,
    partition_key,
    shard_id,
    sequence_number,
    JSON_EXTRACT_PATH_TEXT(FROM_VARBYTE(kinesis_data, 'utf-8'), 'sensor_id')::VARCHAR(50) AS sensor_id,
    JSON_EXTRACT_PATH_TEXT(FROM_VARBYTE(kinesis_data, 'utf-8'), 'timestamp')::VARCHAR(30) AS event_timestamp,
    JSON_EXTRACT_PATH_TEXT(FROM_VARBYTE(kinesis_data, 'utf-8'), 'temperature')::FLOAT8   AS temperature,
    JSON_EXTRACT_PATH_TEXT(FROM_VARBYTE(kinesis_data, 'utf-8'), 'humidity')::FLOAT8      AS humidity,
    JSON_EXTRACT_PATH_TEXT(FROM_VARBYTE(kinesis_data, 'utf-8'), 'air_quality_index')::INT AS air_quality_index,
    JSON_PARSE(FROM_VARBYTE(kinesis_data, 'utf-8')) AS raw_payload
FROM kinesis_stream_schema."pre-entrega1-dev-stream"
WHERE CAN_JSON_PARSE(FROM_VARBYTE(kinesis_data, 'utf-8'));
```

### 3. Integración Lakehouse y Consulta Federada Híbrida

Se mapea la base de datos `lakehouse_db` de Glue como esquema externo de Redshift Spectrum y se ejecuta un `JOIN` que cruza los datos en tiempo real de la Materialized View con los agregados históricos de la tabla Apache Iceberg:

```sql
-- Esquema externo hacia Glue Data Catalog
CREATE EXTERNAL SCHEMA IF NOT EXISTS lakehouse_catalog
FROM DATA CATALOG
DATABASE 'lakehouse_db'
IAM_ROLE 'arn:aws:iam::985879611495:role/pre-entrega1-dev-redshift-role'
REGION 'us-east-1';

-- Consulta Híbrida: Telemetría en caliente vs. Promedios históricos
SELECT
    s.sensor_id,
    s.event_timestamp                                              AS real_time_timestamp,
    s.temperature                                                  AS real_time_temperature,
    h.avg_temperature                                              AS historical_avg_temp,
    ROUND((s.temperature - h.avg_temperature)::NUMERIC, 2)        AS temp_deviation,
    s.air_quality_index                                            AS real_time_aqi,
    h.avg_air_quality                                              AS historical_avg_aqi,
    ROUND((s.air_quality_index - h.avg_air_quality)::NUMERIC, 2)   AS aqi_deviation
FROM mv_sensor_telemetry_stream s
INNER JOIN lakehouse_catalog.sensor_aggregates h
    ON s.sensor_id = h.sensor_id
ORDER BY s.approximate_arrival_timestamp DESC
LIMIT 50;
```

### 4. Gobernanza RBAC y Observabilidad del Stream

* **Control de Acceso RBAC:** Rol de base de datos `analytics_role` con permisos de solo lectura restringidos exclusivamente a la vista materializada y al esquema de Iceberg:
  ```sql
  CREATE ROLE analytics_role;
  GRANT USAGE ON SCHEMA public TO ROLE analytics_role;
  GRANT SELECT ON mv_sensor_telemetry_stream TO ROLE analytics_role;
  GRANT USAGE ON SCHEMA lakehouse_catalog TO ROLE analytics_role;
  GRANT SELECT ON ALL TABLES IN SCHEMA lakehouse_catalog TO ROLE analytics_role;
  ```
* **Métricas de Lag y Latencia:** Auditoría operativa sobre el escaneo de shards y refresco de vistas:
  ```sql
  SELECT * FROM SYS_STREAM_SCAN_STATES LIMIT 10;
  SELECT * FROM SVV_MV_INFO WHERE name = 'mv_sensor_telemetry_stream';
  ```

---

## Criterios de Aceptación Cumplidos

### Pre-entregas Anteriores (Lakehouse & Streaming Base)
* [x] **Infraestructura Declarativa:** Base de datos en AWS Glue (`lakehouse_db`), módulo dedicado `modules/storage/` con versionado en S3 y políticas IAM granulares por prefijo declaradas 100% en Terraform.
* [x] **Seguridad y Auditoría:** Rol de auditoría refactorizado con confianza de plano de control y políticas restringidas por prefijo.
* [x] **Consistencia Transaccional:** Integración de `IcebergSink` con catálogo de Glue y commits atómicos sincronizados con los checkpoints de Flink.
* [x] **Formato Apache Iceberg:** Generación comprobada de archivos Parquet en `data/` y archivos `.metadata.json` / `.avro` en `metadata/`.
* [x] **Manejo de Concurrencia:** Catálogo de Glue configurado correctamente sin errores de modificación concurrente.
* [x] **Consultabilidad Analítica Serverless:** Tabla validada y consultable exitosamente desde Amazon Athena.
* [x] **Outputs de Flink:** Exposición completa de variables de salida en `modules/flink/outputs.tf`.

### Pre-entrega 6 (Analítica Avanzada In-Stream con Redshift)
* [x] **Redshift Streaming Ingestion (RSI) y Materialized View (35%):** Mapeo de Kinesis Data Streams como objeto externo en Redshift y Materialized View funcional con parseo JSON (`sensor_id`, `event_timestamp`, `temperature`, `humidity`, `air_quality_index`), tipado nativo sin errores de casting y protección de Schema Drift mediante `CAN_JSON_PARSE` y tipo `SUPER`.
* [x] **Integración Lakehouse Iceberg mediante External Schema y JOIN (25%):** Conexión exitosa de Redshift con AWS Glue Data Catalog (`lakehouse_db`) y consulta `JOIN` híbrida unificando el stream en caliente con la tabla histórica Iceberg (`sensor_aggregates`).
* [x] **Optimización Operativa y Estrategia de Refresco (15%):** Adopción de estrategia de refresco incremental y justificación técnica del *Latency Trade-off* (evitando saturación de CPU y contención de bloqueos por refrescos sub-segundo innecesarios).
* [x] **Seguridad e Integración IAM entre Servicios (15%):** Autenticación y autorización IAM nativa bajo el principio de mínimo privilegio (`kinesis:DescribeStream`, `kinesis:GetRecords`, Glue, S3) y gobernanza RBAC con el rol `analytics_role`.
* [x] **Calidad del Entregable Técnico y Evidencias (10%):** Script SQL consolidado y comentado en `scripts/redshift_streaming_ingestion.sql`, documento Markdown [`CheckPoint_Redshift_Bustos_Samuel.md`](CheckPoint_Redshift_Bustos_Samuel.md) listo para exportar a PDF con diagramas, justificaciones de diseño y espacios delimitados para las 4 capturas de pantalla.

