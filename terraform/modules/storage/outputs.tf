output "bucket_id" {
  description = "ID del bucket S3."
  value       = aws_s3_bucket.data_lake.id
}

output "bucket_name" {
  description = "Nombre del bucket S3 del Data Lake."
  value       = aws_s3_bucket.data_lake.bucket
}

output "bucket_arn" {
  description = "ARN del bucket S3 del Data Lake."
  value       = aws_s3_bucket.data_lake.arn
}
