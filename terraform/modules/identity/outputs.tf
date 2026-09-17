output "data_processing_role_arn" {

  description = "ARN of the data processing IAM role."

  value = aws_iam_role.data_processing.arn
}

output "audit_role_arn" {

  description = "ARN of the audit IAM role."

  value = aws_iam_role.audit.arn
}