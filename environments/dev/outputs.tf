output "bucket_name" {
  description = "Name of the s3 bucket."
  value       = aws_s3_bucket.data_lake_raw.bucket
}

output "data_processing_role_arn" {

  description = "ARN of the data processing role."

  value = module.identity.data_processing_role_arn
}

output "audit_role_arn" {

  description = "ARN of the audit IAM role."

  value = module.identity.audit_role_arn
}

output "vpc_id" {
  description = "VPC ID."

  value = module.network.vpc_id
}

output "private_subnets_id" {
  description = "Private subnets IDs."

  value = module.network.private_subnet_ids
}