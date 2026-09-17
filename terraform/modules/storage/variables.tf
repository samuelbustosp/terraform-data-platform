variable "project_name" {
  description = "Nombre del proyecto."
  type        = string
}

variable "environment" {
  description = "Entorno de despliegue (dev, test, prod)."
  type        = string
}

variable "bucket_name" {
  description = "Nombre único del bucket S3 para el Data Lake."
  type        = string
}

variable "versioning_status" {
  description = "Estado del versionado para el bucket S3 (Enabled o Suspended)."
  type        = string
  default     = "Enabled"
}
