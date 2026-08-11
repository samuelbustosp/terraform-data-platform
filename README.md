# Terraform Data Platform

## Description

Este proyecto implementa la infraestructura de una plataforma de datos en AWS utilizando **Terraform** y una arquitectura modular.

La solución está diseñada para soportar un flujo de **ingesta de datos en tiempo real**, desde la generación de eventos hasta su persistencia en un Data Lake sobre Amazon S3.

La infraestructura incluye:

* Networking mediante Amazon VPC.
* Gestión de identidades y permisos mediante IAM.
* Data Lake sobre Amazon S3.
* Kinesis Data Stream para ingesta real-time.
* Kinesis Data Firehose para la entrega de datos hacia S3.
* Observabilidad mediante CloudWatch Logs.
* Backend remoto para el estado de Terraform.
* Producers simulados mediante Python y Boto3.

---

## Architecture

```text
                  ┌─────────────────────┐
                  │   Python Producer   │
                  │      Boto3          │
                  └──────────┬──────────┘
                             │
                             │ PutRecord
                             ▼
                  ┌─────────────────────┐
                  │  Kinesis Data       │
                  │      Stream         │
                  │                     │
                  │  PROVISIONED        │
                  │  2 Shards           │
                  │  KMS Encryption     │
                  └──────────┬──────────┘
                             │
                             │
                             ▼
                  ┌─────────────────────┐
                  │ Kinesis Data        │
                  │     Firehose        │
                  │                     │
                  │ Buffer: 5 MB        │
                  │ Interval: 60 sec    │
                  │ GZIP                 │
                  └──────────┬──────────┘
                             │
                             ▼
                  ┌─────────────────────┐
                  │     Amazon S3       │
                  │     Data Lake       │
                  │       RAW           │
                  └─────────────────────┘
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
├── modules/
│   ├── network/
│   ├── identity/
│   └── kinesis/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
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
* AWS CLI
* Python 3.x
* Boto3
* Cuenta de AWS
* Credenciales configuradas mediante:

```bash
aws configure
```

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

* Amazon S3 Data Lake Bucket.

### Identity

* IAM Role para procesamiento de datos.
* IAM Policy para acceso al Data Lake.
* IAM Role para auditoría.
* IAM Policy de solo lectura.

### Real-Time Ingestion

#### Kinesis Data Stream

Se implementó un **Amazon Kinesis Data Stream** utilizando Terraform.

Características:

* Modo `PROVISIONED`.
* 2 shards.
* Retención de datos de 24 horas.
* Encriptación mediante KMS.
* Nombre dinámico basado en el entorno.

Stream utilizado durante la prueba:

```text
pre-entrega1-dev-stream
```

ARN:

```text
arn:aws:kinesis:us-east-1:985879611495:stream/pre-entrega1-dev-stream
```

Los 2 shards permiten distribuir la carga utilizando diferentes `PartitionKeys`.

---

### Kinesis Data Firehose

Se implementó un **Kinesis Data Firehose Delivery Stream** utilizando como fuente el Kinesis Data Stream y como destino el bucket S3 del Data Lake.

Características:

* Source: Kinesis Data Stream.
* Destination: Amazon S3.
* Buffer size: 5 MB.
* Buffer interval: 60 segundos.
* Compresión: GZIP.
* CloudWatch Logs habilitado.
* Prefijo dinámico por año.

Prefijo utilizado:

```text
ingesta/year=!{timestamp:yyyy}/
```

Los errores de entrega utilizan:

```text
ingesta-errores/!{firehose:error-output-type}/year=!{timestamp:yyyy}/
```

Firehose utilizado durante la prueba:

```text
ingesta-pre-entrega1-dev-stream
```

---

## IAM Security

El rol utilizado por Kinesis Firehose permite:

### Kinesis

* `kinesis:DescribeStream`
* `kinesis:GetShardIterator`
* `kinesis:GetRecords`
* `kinesis:ListShards`
* `kinesis:DescribeStreamSummary`

### S3

* `s3:PutObject`
* `s3:GetBucketLocation`
* `s3:ListBucket`
* `s3:AbortMultipartUpload`
* `s3:ListBucketMultipartUploads`
* `s3:ListMultipartUploadParts`

### CloudWatch Logs

* `logs:PutLogEvents`
* `logs:CreateLogGroup`
* `logs:CreateLogStream`

El Kinesis Data Stream utiliza:

```text
EncryptionType: KMS
Key: alias/aws/kinesis
```

---

## Real-Time Producer

Para validar la ingesta se desarrolló un producer en Python utilizando **Boto3**.

El producer genera y envía 100 eventos al Kinesis Data Stream.

Cada evento contiene:

```json
{
  "evento": "click",
  "producto": "A1",
  "user_id": "user-0",
  "ts": "2026-08-11T18:00:00Z"
}
```

### Partition Keys

Para evitar concentrar todos los eventos en un único shard, se utilizan diferentes `PartitionKeys`:

```text
user-0
user-1
user-2
...
user-9
```

La clave utilizada por cada evento se genera mediante:

```python
partition_key = f"user-{i % 10}"
```

De esta manera, los eventos se distribuyen entre los shards disponibles en lugar de utilizar una clave estática.

---

## Producer Execution

Instalar Boto3:

```bash
pip install boto3
```

Ejecutar el producer:

```bash
python producer.py
```

El script envía 100 registros y muestra en consola el shard y sequence number asignados a cada registro.

Ejemplo:

```text
Enviando 100 registros a pre-entrega1-dev-stream...
#001 -> shard shardId-000000000001
#002 -> shard shardId-000000000001
#003 -> shard shardId-000000000000
...
#100 -> shard shardId-000000000001

Listo: 100 registros enviados.
```

La salida confirma que los registros fueron aceptados por Kinesis y distribuidos entre los dos shards.

---

## Data Lake Validation

Después de ejecutar el producer, se verificó la entrega de los datos mediante AWS CLI.

Comando utilizado:

```bash
aws s3 ls s3://coderhouse-datalake-raw-pre-entrega1-sbustos-2026/ --recursive
```

Resultado obtenido:

```text
2026-08-11 15:24:57        434 ingesta/year=2026/ingesta-pre-entrega1-dev-stream-1-2026-08-11-18-23-56-a8eba03b-4aeb-431b-8c80-a52a5548f32f.gz
2026-08-11 15:24:57        339 ingesta/year=2026/ingesta-pre-entrega1-dev-stream-1-2026-08-11-18-23-56-bc7ba76f-c615-4ff6-b138-058c6ccfb63e.gz
```

Los archivos fueron generados por Firehose en formato **GZIP**, confirmando el flujo:

```text
Python Producer
      ↓
Kinesis Data Stream
      ↓
Kinesis Data Firehose
      ↓
Amazon S3 Data Lake
```

---

## Useful Commands

Formatear el código:

```bash
terraform fmt -recursive
```

Validar la configuración:

```bash
terraform validate
```

Generar el plan:

```bash
terraform plan
```

Aplicar la infraestructura:

```bash
terraform apply
```

Destruir la infraestructura:

```bash
terraform destroy
```

Verificar el Kinesis Stream:

```bash
aws kinesis describe-stream-summary \
  --stream-name pre-entrega1-dev-stream \
  --region us-east-1
```

Verificar Firehose:

```bash
aws firehose describe-delivery-stream \
  --delivery-stream-name ingesta-pre-entrega1-dev-stream \
  --region us-east-1
```

Verificar los archivos generados en S3:

```bash
aws s3 ls s3://coderhouse-datalake-raw-pre-entrega1-sbustos-2026/ --recursive
```

---

## Outputs

El proyecto expone los siguientes outputs:

```text
bucket_name
data_processing_role_arn
audit_role_arn
vpc_id
private_subnets_id
stream_name
stream_arn
firehose_name
firehose_arn
```

Ejemplo de outputs generados:

```text
bucket_name = "coderhouse-datalake-raw-pre-entrega1-sbustos-2026"

stream_name = "pre-entrega1-dev-stream"

firehose_name = "ingesta-pre-entrega1-dev-stream"

stream_arn = "arn:aws:kinesis:us-east-1:985879611495:stream/pre-entrega1-dev-stream"

firehose_arn = "arn:aws:firehose:us-east-1:985879611495:deliverystream/ingesta-pre-entrega1-dev-stream"
```

---

## Checkpoint Validation

La prueba de ingesta real-time fue completada exitosamente:

* [x] Kinesis Data Stream creado mediante Terraform.
* [x] Stream configurado en modo `PROVISIONED`.
* [x] 2 shards configurados.
* [x] KMS habilitado.
* [x] Kinesis Firehose configurado.
* [x] Firehose conectado al Kinesis Stream.
* [x] Firehose configurado con destino S3.
* [x] Buffer de 5 MB / 60 segundos.
* [x] Compresión GZIP.
* [x] IAM Role configurado para Firehose.
* [x] Producer Python/Boto3 implementado.
* [x] 100 registros enviados correctamente.
* [x] Partition Keys variables utilizadas.
* [x] Archivos generados en el Data Lake S3.
* [x] Flujo end-to-end validado.
