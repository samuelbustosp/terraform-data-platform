# Terraform Data Platform

## Description

This project contains the initial Terraform scaffolding for a cloud-based data platform. The goal is to provide a clean and maintainable structure that can later be extended with services such as Amazon Kinesis, Amazon Managed Service for Apache Flink, S3, IAM and CloudWatch.

## Project Structure

- provider.tf: Terraform and AWS provider configuration.
- variables.tf: Input variables used across the project.
- main.tf: Main infrastructure resources.
- outputs.tf: Output values.
- terraform.tfvars: Example variable values.
- .gitignore: Excludes Terraform generated files.

## Getting Started

Initialize Terraform:

```bash
terraform init
```

Validate the configuration:

```bash
terraform validate
```

Generate an execution plan:

```bash
terraform plan
```

## AWS Naming Convention

AWS resources follow the convention:

```
<project-name>-<environment>-<resource>
```

Example:

```
data-platform-dev-data-lake
```

This convention makes resources easier to identify and organize across different environments.

## Why separate the files?

Splitting the configuration into multiple files improves readability and maintainability.

- provider.tf isolates provider configuration.
- variables.tf centralizes input variables.
- main.tf contains infrastructure resources.
- outputs.tf exposes useful values.
- terraform.tfvars stores environment-specific values.

This structure scales much better than placing everything inside a single main.tf file.