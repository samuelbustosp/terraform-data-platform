terraform {
  backend "s3" {

    bucket = "terraform-state-pre-entrega-1-sbustos-2026"

    key = "dev/terraform.tfstate"

    region = "us-east-2"

    dynamodb_table = "terraform-locks"

    encrypt = true
  }
}
