output "bucket_name" {
  description = "Name of the s3 bucket."
  value       = module.storage.bucket_name
}

output "bucket_arn" {
  description = "ARN of the s3 bucket."
  value       = module.storage.bucket_arn
}

output "data_processing_role_arn" {
  description = "ARN of the data processing role."
  value       = module.identity.data_processing_role_arn
}

output "audit_role_arn" {
  description = "ARN of the audit IAM role."
  value       = module.identity.audit_role_arn
}

output "vpc_id" {
  description = "VPC ID."
  value       = module.network.vpc_id
}

output "private_subnets_id" {
  description = "Private subnets IDs."
  value       = module.network.private_subnet_ids
}

output "stream_name" {
  description = "Name of the Kinesis Data Stream"
  value       = module.kinesis.stream_name
}

output "stream_arn" {
  description = "ARN of the Kinesis Data Stream"
  value       = module.kinesis.stream_arn
}

output "firehose_name" {
  description = "Name of the Kinesis Data Firehose"
  value       = module.kinesis.firehose_name
}

output "firehose_arn" {
  description = "ARN of the Kinesis Data Firehose"
  value       = module.kinesis.firehose_arn
}

# ==============================================================================
# FLINK OUTPUTS
# ==============================================================================

output "flink_application_name" {
  description = "Nombre de la aplicación Managed Apache Flink"
  value       = module.flink.application_name
}

output "flink_application_arn" {
  description = "ARN de la aplicación Managed Apache Flink"
  value       = module.flink.application_arn
}

output "flink_role_arn" {
  description = "ARN del rol de ejecución de Flink"
  value       = module.flink.role_arn
}

output "flink_log_group_name" {
  description = "Grupo de logs en CloudWatch para Flink"
  value       = module.flink.log_group_name
}

# ==============================================================================
# LAKEHOUSE GLUE OUTPUTS
# ==============================================================================

output "lakehouse_database_name" {
  description = "Nombre de la base de datos de Glue para el Lakehouse"
  value       = aws_glue_catalog_database.lakehouse_db.name
}

# ==============================================================================
# REDSHIFT OUTPUTS
# ==============================================================================

output "redshift_cluster_endpoint" {
  description = "Endpoint del cluster de Redshift"
  value       = module.redshift.cluster_endpoint
}

output "redshift_role_arn" {
  description = "ARN del rol IAM asociado a Redshift (usar en scripts SQL)"
  value       = module.redshift.redshift_role_arn
}