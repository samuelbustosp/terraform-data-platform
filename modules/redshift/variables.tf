variable "project_name" {
  description = "Nombre del proyecto."
  type        = string
}

variable "environment" {
  description = "Ambiente de despliegue (dev, prod)."
  type        = string
}

variable "vpc_id" {
  description = "ID de la VPC donde residirá el clúster."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR de la VPC para reglas de seguridad."
  type        = string
}

variable "subnet_ids" {
  description = "IDs de las subredes privadas para el Subnet Group de Redshift."
  type        = list(string)
}

variable "kinesis_stream_arn" {
  description = "ARN del Kinesis Data Stream para Streaming Ingestion."
  type        = string
}

variable "data_bucket_arn" {
  description = "ARN del bucket S3 del Data Lake (para leer datos de Iceberg)."
  type        = string
}

variable "glue_database_name" {
  description = "Nombre de la base de datos de Glue Catalog."
  type        = string
  default     = "lakehouse_db"
}

variable "database_name" {
  description = "Nombre de la base de datos inicial de Redshift."
  type        = string
  default     = "analytics_db"
}

variable "admin_username" {
  description = "Usuario administrador del clúster Redshift."
  type        = string
  default     = "adminuser"
}

variable "admin_password" {
  description = "Contraseña del administrador de Redshift."
  type        = string
  sensitive   = true
}

variable "node_type" {
  description = "Tipo de nodo de Redshift (ra3.large para entornos de prueba/dev)."
  type        = string
  default     = "ra3.large"
}