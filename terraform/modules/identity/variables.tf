variable "project_name" {
  description = "Name of the project."
  type        = string
}

variable "environment" {
  description = "Environment name."
  type        = string
}

variable "data_bucket_arn" {
  description = "ARN of the S3 bucket used by data processing services."
  type        = string
}