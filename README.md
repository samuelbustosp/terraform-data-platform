# Terraform Data Platform

## Description
Este proyecto implementa la infraestructura base de una plataforma de datos en AWS utilizando Terraform y una arquitectura modular.

La solución incluye componentes de red, gestión de identidades (IAM), almacenamiento en Amazon S3 y un backend remoto para almacenar el estado de Terraform.

---

## Project Structure
```
terraform-data-platform/
│
├── bootstrap/
│   ├── main.tf
│   ├── provider.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── terraform.tfvars
│
├── modules/
│   ├── network/
│   └── identity/
│
└── environments/
    └── dev/
        ├── backend.tf
        ├── main.tf
        ├── provider.tf
        ├── variables.tf
        ├── outputs.tf
        └── terraform.tfvars
```

---
## Prerequisites
- Terraform >= 1.0
- AWS CLI
- Cuenta de AWS
- Credenciales configuradas mediante:

```bash
aws configure
```

---

## Bootstrap

El directorio `bootstrap` crea los recursos necesarios para almacenar el estado remoto de Terraform.

Recursos creados:

- Bucket S3 para el archivo `.tfstate`
- Tabla DynamoDB para el bloqueo del estado (State Lock)

Ejecutar:

```bash
cd bootstrap

terraform init
terraform plan
terraform apply
```

---

## Development Environment

Una vez creado el backend remoto, desplegar la infraestructura principal.

```bash
cd environments/dev

terraform init -reconfigure
terraform plan
terraform apply
```

---

## Resources Created

### Network

- VPC
- 2 Private Subnets
- Private Route Table
- Route Table Associations
- S3 Gateway Endpoint

### Storage

- Data Lake Bucket (Amazon S3)

### Identity

- IAM Role para procesamiento de datos
- IAM Policy para acceso de lectura/escritura al Data Lake
- IAM Role para auditoría
- IAM Policy de solo lectura

### Backend

- Remote State en Amazon S3
- State Lock mediante DynamoDB

---

## Useful Commands

```bash
terraform fmt -recursive
terraform validate
terraform plan
terraform apply
terraform destroy
```

---

## Outputs

El proyecto expone los siguientes outputs:

- bucket_name
- data_processing_role_arn
- audit_role_arn
- vpc_id
- private_subnet_ids