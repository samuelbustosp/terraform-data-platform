variable "project_name" {
  description = "Name of the project."
  type        = string
}

variable "environment" {
  description = "Environment name (dev, prod, etc)."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets."
  type        = list(string)
}