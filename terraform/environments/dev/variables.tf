variable "region" {
  description = "AWS region where the infrastructure will be deployed."
  type        = string
}

variable "project_name" {
  description = "Name of the project used as  a prefix for AWS resources."
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, test or prod)."
  type        = string
}

variable "project_author" {
  description = "Name of the autor or owner of the infrastructure project."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for VPC."
  type        = string
}


variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets."
  type        = list(string)
}

variable "redshift_admin_password" {
  description = "Master password para el cluster de Redshift."
  type        = string
  sensitive   = true
}