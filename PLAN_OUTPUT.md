# PLAN_OUTPUT.md

## Terraform Plan

El siguiente resultado corresponde a la ejecución del comando:

```bash
terraform plan
```

desde el directorio:

```text
environments/dev
```

Este plan corresponde a la infraestructura base de la plataforma de datos junto con los nuevos componentes de **ingesta real-time** implementados para la Pre-entrega 2.

---

## Resources to be created

Terraform planifica la creación de **20 recursos**:

```text
Plan: 20 to add, 0 to change, 0 to destroy.
```

### S3 Data Lake

Se crea el bucket S3 destinado al almacenamiento de los datos crudos:

```text
aws_s3_bucket.data_lake_raw
```

Bucket:

```text
coderhouse-datalake-raw-pre-entrega1-sbustos-2026
```

---

### IAM - Identity

Se crean los roles y políticas necesarios para la infraestructura:

```text
module.identity.aws_iam_policy.audit_read_only
module.identity.aws_iam_policy.data_processing_s3

module.identity.aws_iam_role.audit
module.identity.aws_iam_role.data_processing

module.identity.aws_iam_role_policy_attachment.audit
module.identity.aws_iam_role_policy_attachment.data_processing
```

Estos recursos permiten separar los permisos de auditoría de los permisos utilizados para procesamiento de datos.

---

### Network

Se crea la infraestructura de red:

```text
module.network.aws_vpc.main

module.network.aws_subnet.private["private-1"]
module.network.aws_subnet.private["private-2"]

module.network.aws_route_table.private

module.network.aws_route_table_association.private["private-1"]
module.network.aws_route_table_association.private["private-2"]

module.network.aws_vpc_endpoint.s3
```

Características principales:

* VPC: `10.0.0.0/16`
* Private Subnet 1: `10.0.1.0/24`
* Private Subnet 2: `10.0.2.0/24`
* Availability Zones: `us-east-1a` y `us-east-1b`
* S3 Gateway Endpoint

---

# Real-Time Ingestion

La principal incorporación de esta Pre-entrega es el módulo de ingesta:

```text
module.kinesis
```

Este módulo implementa **Kinesis Data Stream**, **Kinesis Data Firehose**, IAM y observabilidad mediante CloudWatch.

---

## Kinesis Data Stream

Se crea el siguiente stream:

```text
module.kinesis.aws_kinesis_stream.main
```

Configuración:

```text
Stream Name:        pre-entrega1-dev-stream
Stream Mode:        PROVISIONED
Shard Count:        2
Retention Period:   24 hours
Encryption:         KMS
KMS Key:            alias/aws/kinesis
```

El stream utiliza dos shards para proporcionar capacidad de procesamiento y permitir demostrar la distribución de registros mediante diferentes `PartitionKey`.

---

## Kinesis Data Firehose

Se crea el delivery stream:

```text
module.kinesis.aws_kinesis_firehose_delivery_stream.main
```

Nombre:

```text
ingesta-pre-entrega1-dev-stream
```

Configuración:

```text
Source:             Kinesis Data Stream
Destination:        Amazon S3
Buffer Size:        5 MB
Buffer Interval:    60 seconds
Compression:        GZIP
```

El destino S3 utiliza el prefijo dinámico:

```text
ingesta/year=!{timestamp:yyyy}/
```

Los errores de entrega se almacenan utilizando:

```text
ingesta-errores/year=!{timestamp:yyyy}/
```

La configuración de buffering de 5 MB / 60 segundos permite observar rápidamente los archivos generados durante las pruebas de desarrollo.

---

## IAM Role para Firehose

Firehose utiliza un rol IAM específico:

```text
module.kinesis.aws_iam_role.firehose
```

y una política asociada:

```text
module.kinesis.aws_iam_role_policy.firehouse
```

El rol proporciona los permisos necesarios para:

* Leer registros desde Kinesis Data Stream.
* Escribir los datos en Amazon S3.
* Escribir logs en CloudWatch.

---

## CloudWatch - Observabilidad

Se crean dos alarmas de CloudWatch para monitorear el throughput del Kinesis Data Stream.

### Read Throughput

```text
module.kinesis.aws_cloudwatch_metric_alarm.read_throughput_exceeded
```

Métrica:

```text
ReadProvisionedThroughputExceeded
```

### Write Throughput

```text
module.kinesis.aws_cloudwatch_metric_alarm.write_throughput_exceeded
```

Métrica:

```text
WriteProvisionedThroughputExceeded
```

Ambas alarmas utilizan:

```text
Period:             60 seconds
Statistic:          Sum
Threshold:          0
Evaluation Periods: 1
```

Esto permite detectar situaciones en las que el stream supera la capacidad de lectura o escritura provisionada.

---

# Terraform Plan Output

El resultado completo del comando `terraform plan` es:

```text
Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # aws_s3_bucket.data_lake_raw will be created
  + resource "aws_s3_bucket" "data_lake_raw" {
      + bucket                      = "coderhouse-datalake-raw-pre-entrega1-sbustos-2026"
      + force_destroy               = true
      + tags                        = {
          + "Environment" = "dev"
          + "Project"     = "pre-entrega1"
        }
    }

  # module.identity.aws_iam_policy.audit_read_only will be created
  + resource "aws_iam_policy" "audit_read_only" {
      + name = "pre-entrega1-dev-audit-read-only"
      + tags_all = {
          + "Environment" = "dev"
          + "Project"     = "pre-entrega1"
        }
    }

  # module.identity.aws_iam_policy.data_processing_s3 will be created
  + resource "aws_iam_policy" "data_processing_s3" {
      + name = "pre-entrega1-dev-s3-processing-policy"
      + tags_all = {
          + "Environment" = "dev"
          + "Project"     = "pre-entrega1"
        }
    }

  # module.identity.aws_iam_role.audit will be created
  + resource "aws_iam_role" "audit" {
      + name = "pre-entrega1-dev-audit-role"
      + tags = {
          + "Environment" = "dev"
          + "Project"     = "pre-entrega1"
        }
    }

  # module.identity.aws_iam_role.data_processing will be created
  + resource "aws_iam_role" "data_processing" {
      + name = "pre-entrega1-dev-data-processing-role"
      + tags = {
          + "Environment" = "dev"
          + "Project"     = "pre-entrega1"
        }
    }

  # module.identity.aws_iam_role_policy_attachment.audit will be created
  + resource "aws_iam_role_policy_attachment" "audit" {
      + role = "pre-entrega1-dev-audit-role"
    }

  # module.identity.aws_iam_role_policy_attachment.data_processing will be created
  + resource "aws_iam_role_policy_attachment" "data_processing" {
      + role = "pre-entrega1-dev-data-processing-role"
    }

  # module.kinesis.aws_cloudwatch_metric_alarm.read_throughput_exceeded will be created
  + resource "aws_cloudwatch_metric_alarm" "read_throughput_exceeded" {
      + alarm_name          = "pre-entrega1-dev-stream-read-throughput-exceeded"
      + comparison_operator = "GreaterThanThreshold"
      + dimensions = {
          + "StreamName" = "pre-entrega1-dev-stream"
        }
      + evaluation_periods = 1
      + metric_name        = "ReadProvisionedThroughputExceeded"
      + namespace           = "AWS/Kinesis"
      + period              = 60
      + statistic           = "Sum"
      + threshold           = 0
      + treat_missing_data  = "notBreaching"
    }

  # module.kinesis.aws_cloudwatch_metric_alarm.write_throughput_exceeded will be created
  + resource "aws_cloudwatch_metric_alarm" "write_throughput_exceeded" {
      + alarm_name          = "pre-entrega1-dev-stream-write-throughput-exceeded"
      + comparison_operator = "GreaterThanThreshold"
      + dimensions = {
          + "StreamName" = "pre-entrega1-dev-stream"
        }
      + evaluation_periods = 1
      + metric_name        = "WriteProvisionedThroughputExceeded"
      + namespace           = "AWS/Kinesis"
      + period              = 60
      + statistic           = "Sum"
      + threshold           = 0
      + treat_missing_data  = "notBreaching"
    }

  # module.kinesis.aws_iam_role.firehose will be created
  + resource "aws_iam_role" "firehose" {
      + name = "firehose-kinesis-dev"
      + tags_all = {
          + "Environment" = "dev"
          + "Project"     = "pre-entrega1"
        }
    }

  # module.kinesis.aws_iam_role_policy.firehouse will be created
  + resource "aws_iam_role_policy" "firehouse" {
      + name = "firehose-kinesis-policy"
    }

  # module.kinesis.aws_kinesis_firehose_delivery_stream.main will be created
  + resource "aws_kinesis_firehose_delivery_stream" "main" {
      + destination = "extended_s3"
      + name        = "ingesta-pre-entrega1-dev-stream"

      + extended_s3_configuration {
          + bucket_arn          = "arn:aws:s3:::coderhouse-datalake-raw-pre-entrega1-sbustos-2026"
          + buffering_interval  = 60
          + buffering_size      = 5
          + compression_format  = "GZIP"
          + custom_time_zone    = "UTC"
          + error_output_prefix = "ingesta-errores/year=!{timestamp:yyyy}/"
          + prefix              = "ingesta/year=!{timestamp:yyyy}/"
          + s3_backup_mode      = "Disabled"

          + cloudwatch_logging_options {
              + enabled         = true
              + log_group_name  = "/aws/kinesis-firehose/pre-entrega1-dev-stream"
              + log_stream_name = "S3Delivery"
            }
        }

      + kinesis_source_configuration {
          + kinesis_stream_arn = (known after apply)
          + role_arn           = (known after apply)
        }
    }

  # module.kinesis.aws_kinesis_stream.main will be created
  + resource "aws_kinesis_stream" "main" {
      + encryption_type  = "KMS"
      + kms_key_id       = "alias/aws/kinesis"
      + name             = "pre-entrega1-dev-stream"
      + retention_period = 24
      + shard_count      = 2

      + stream_mode_details {
          + stream_mode = "PROVISIONED"
        }
    }

  # module.network.aws_route_table.private will be created
  + resource "aws_route_table" "private" {
      + tags = {
          + "Name" = "pre-entrega1-private-route-table"
        }
    }

  # module.network.aws_route_table_association.private["private-1"] will be created
  + resource "aws_route_table_association" "private" {
      + subnet_id = (known after apply)
    }

  # module.network.aws_route_table_association.private["private-2"] will be created
  + resource "aws_route_table_association" "private" {
      + subnet_id = (known after apply)
    }

  # module.network.aws_subnet.private["private-1"] will be created
  + resource "aws_subnet" "private" {
      + availability_zone = "us-east-1a"
      + cidr_block        = "10.0.1.0/24"
      + map_public_ip_on_launch = false
    }

  # module.network.aws_subnet.private["private-2"] will be created
  + resource "aws_subnet" "private" {
      + availability_zone = "us-east-1b"
      + cidr_block        = "10.0.2.0/24"
      + map_public_ip_on_launch = false
    }

  # module.network.aws_vpc.main will be created
  + resource "aws_vpc" "main" {
      + cidr_block           = "10.0.0.0/16"
      + enable_dns_hostnames = true
      + enable_dns_support   = true
    }

  # module.network.aws_vpc_endpoint.s3 will be created
  + resource "aws_vpc_endpoint" "s3" {
      + service_name      = "com.amazonaws.us-east-1.s3"
      + vpc_endpoint_type = "Gateway"
    }

Plan: 20 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + audit_role_arn           = (known after apply)
  + bucket_name              = "coderhouse-datalake-raw-pre-entrega1-sbustos-2026"
  + data_processing_role_arn = (known after apply)
  + firehose_arn             = (known after apply)
  + firehose_name            = "ingesta-pre-entrega1-dev-stream"
  + private_subnets_id       = [
      + (known after apply),
      + (known after apply),
    ]
  + stream_arn               = (known after apply)
  + stream_name               = "pre-entrega1-dev-stream"
  + vpc_id                    = (known after apply)

Note: You didn't use the -out option to save this plan, so Terraform can't guarantee to take exactly these actions if you run "terraform apply" now.
```

---

## Validation

Luego del despliegue se realizó una prueba de ingesta utilizando un producer desarrollado en Python con Boto3.

El producer envía:

```text
100 registros
```

utilizando diferentes `PartitionKey`:

```text
user-0
user-1
...
user-9
```

Esto permite distribuir los registros entre los dos shards disponibles y evita utilizar una única clave de partición que pueda generar un **Hot Shard**.

Durante la ejecución se observaron registros enviados a ambos shards:

```text
#001 -> shard shardId-000000000001
#002 -> shard shardId-000000000001
#003 -> shard shardId-000000000000
...
#100 -> shard shardId-000000000001
```

Resultado:

```text
Listo: 100 registros enviados.
```

---

## S3 Delivery Validation

Los registros fueron posteriormente procesados por Kinesis Data Firehose y almacenados en el Data Lake de Amazon S3.

La validación se realizó mediante:

```bash
aws s3 ls s3://coderhouse-datalake-raw-pre-entrega1-sbustos-2026/ --recursive
```

Resultado:

```text
2026-08-11 15:24:57        434 ingesta/year=2026/ingesta-pre-entrega1-dev-stream-1-2026-08-11-18-23-56-a8eba03b-4aeb-431b-8c80-a52a5548f32f.gz
2026-08-11 15:24:57        339 ingesta/year=2026/ingesta-pre-entrega1-dev-stream-1-2026-08-11-18-23-56-bc7ba76f-c615-4ff6-b138-058c6ccfb63e.gz
```

Esto confirma el flujo:

```text
Python Producer
      │
      ▼
Kinesis Data Stream
      │
      ▼
Kinesis Data Firehose
      │
      ▼
Amazon S3
      │
      ▼
Bronze / Raw Data
```

---

## Final Infrastructure

La infraestructura implementada para este checkpoint queda compuesta por:

```text
                    ┌─────────────────────┐
                    │   Python Producer   │
                    │     Boto3 / CLI     │
                    └──────────┬──────────┘
                               │
                               ▼
                    ┌─────────────────────┐
                    │ Kinesis Data Stream │
                    │   2 PROVISIONED     │
                    │       Shards        │
                    └──────────┬──────────┘
                               │
                               ▼
                    ┌─────────────────────┐
                    │ Kinesis Data        │
                    │ Firehose            │
                    │ 5 MB / 60 seconds  │
                    └──────────┬──────────┘
                               │
                               ▼
                    ┌─────────────────────┐
                    │    Amazon S3        │
                    │   Data Lake Raw     │
                    │  Bronze Layer       │
                    └─────────────────────┘

                         │
                         ▼

                 ┌──────────────────────┐
                 │     CloudWatch       │
                 │                      │
                 │ Read Throughput      │
                 │ Write Throughput     │
                 └──────────────────────┘
```

La prueba confirma que la infraestructura de ingesta real-time se encuentra funcionando correctamente y que los eventos enviados al Kinesis Data Stream son entregados posteriormente por Firehose al bucket S3.
