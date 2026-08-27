
variable "project_name" {
  description = "Nombre del proyecto."
  type        = string
}

variable "environment" {
  description = "Entorno de despliegue."
  type        = string
}

variable "stream_arn" {
  description = "ARN del Kinesis Data Stream."
  type        = string
}

variable "bucket_name" {
  description = "Bucket S3 utilizado por Flink."
  type        = string
}

variable "jar_key" {
  description = "Ruta del JAR dentro del bucket S3"
  type        = string
}

