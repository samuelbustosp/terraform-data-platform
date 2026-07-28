variable "region" {
  description = "AWS region where the infrastructure will be deployed."
  type        = string
}

variable "project_name" {
  description = "Name of the project used as  a prefix for AWS resources."
  type        = string
}

variable "environment" {
  description = "Deployment enviroment (dev, test or prod)."
  type        = string
}