output "application_name" {
  description = "Nombre de la aplicación Managed Service for Apache Flink."
  value       = aws_kinesisanalyticsv2_application.flink.name
}

output "application_arn" {
  description = "ARN de la aplicación Managed Service for Apache Flink."
  value       = aws_kinesisanalyticsv2_application.flink.arn
}

output "application_version_id" {
  description = "Versión actual de la aplicación de Flink."
  value       = aws_kinesisanalyticsv2_application.flink.version_id
}

output "role_arn" {
  description = "ARN del rol IAM de ejecución de Flink."
  value       = aws_iam_role.flink.arn
}

output "role_name" {
  description = "Nombre del rol IAM de ejecución de Flink."
  value       = aws_iam_role.flink.name
}

output "log_group_name" {
  description = "Nombre del grupo de logs en CloudWatch para Flink."
  value       = aws_cloudwatch_log_group.flink.name
}

output "log_stream_name" {
  description = "Nombre del stream de logs en CloudWatch para Flink."
  value       = aws_cloudwatch_log_stream.flink.name
}
