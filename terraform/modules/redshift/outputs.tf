output "cluster_identifier" {
  description = "Identificador del clúster de Redshift."
  value       = aws_redshift_cluster.main.cluster_identifier
}

output "cluster_endpoint" {
  description = "Endpoint de conexión de Redshift."
  value       = aws_redshift_cluster.main.endpoint
}

output "database_name" {
  description = "Nombre de la base de datos."
  value       = aws_redshift_cluster.main.database_name
}

output "redshift_role_arn" {
  description = "ARN del rol IAM de Redshift (necesario para los CREATE EXTERNAL SCHEMA en SQL)."
  value       = aws_iam_role.redshift.arn
}