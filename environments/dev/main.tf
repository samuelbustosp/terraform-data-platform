module "network" {
  source = "../../modules/network"

  project_name         = var.project_name
  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  private_subnet_cidrs = var.private_subnet_cidrs
}

module "storage" {
  source = "../../modules/storage"

  project_name = var.project_name
  environment  = var.environment
  bucket_name  = "coderhouse-datalake-raw-${var.project_name}-${var.project_author}-2026"
}

# Refactorización con bloques moved para preservar el estado existente sin recrear el bucket
moved {
  from = aws_s3_bucket.data_lake_raw
  to   = module.storage.aws_s3_bucket.data_lake
}

moved {
  from = aws_s3_bucket_versioning.data_lake_versioning
  to   = module.storage.aws_s3_bucket_versioning.data_lake_versioning
}

module "identity" {
  source = "../../modules/identity"

  project_name    = var.project_name
  environment     = var.environment
  data_bucket_arn = module.storage.bucket_arn
}

module "kinesis" {
  source = "../../modules/kinesis"

  project_name = var.project_name
  environment  = var.environment

  stream_name = "${var.project_name}-${var.environment}-stream"
  shard_count = 2

  bucket_name         = module.storage.bucket_name
  buffer_size_mb      = 5
  buffer_interval_sec = 60
}

module "flink" {
  source = "../../modules/flink"

  project_name = var.project_name
  environment  = var.environment

  stream_arn  = module.kinesis.stream_arn
  bucket_name = module.storage.bucket_name

  jar_key = "flink/urban-sensors-flink.jar"
}

resource "aws_glue_catalog_database" "lakehouse_db" {
  name        = "lakehouse_db"
  description = "Base de datos para las tablas de Iceberg"
}