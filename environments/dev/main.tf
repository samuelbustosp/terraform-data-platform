module "network" {

  source = "../../modules/network"


  project_name = var.project_name

  environment = var.environment

  vpc_cidr = var.vpc_cidr


  private_subnet_cidrs = var.private_subnet_cidrs
}

resource "aws_s3_bucket" "data_lake_raw" {
  bucket        = "coderhouse-datalake-raw-${var.project_name}-${var.project_author}-2026"
  force_destroy = true

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

module "identity" {

  source = "../../modules/identity"


  project_name = var.project_name

  environment = var.environment


  data_bucket_arn = aws_s3_bucket.data_lake_raw.arn
}

module "kinesis" {
  source = "../../modules/kinesis"

  project_name = var.project_name
  environment  = var.environment

  stream_name = "${var.project_name}-${var.environment}-stream"

  shard_count = 2

  bucket_name = aws_s3_bucket.data_lake_raw.bucket

  buffer_size_mb      = 5
  buffer_interval_sec = 60
}

module "flink" {
  source = "../../modules/flink"

  project_name = var.project_name
  environment  = var.environment

  stream_arn  = module.kinesis.stream_arn
  bucket_name = aws_s3_bucket.data_lake_raw.bucket

  jar_key = "flink/urban-sensors-flink.jar"
}
