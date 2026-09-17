data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# ==============================================================================
# 1. ROL IAM PARA REDSHIFT (Streaming Ingestion + Glue/Iceberg Spectrum)
# ==============================================================================

resource "aws_iam_role" "redshift" {
  name = "${var.project_name}-${var.environment}-redshift-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "redshift.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-${var.environment}-redshift-role"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Permisos para Redshift Streaming Ingestion (RSI) sobre Kinesis
resource "aws_iam_policy" "redshift_kinesis" {
  name        = "${var.project_name}-${var.environment}-redshift-kinesis-policy"
  description = "Permite a Redshift leer directamente del Kinesis Data Stream"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kinesis:DescribeStreamSummary",
          "kinesis:GetShardIterator",
          "kinesis:GetRecords",
          "kinesis:DescribeStream",
          "kinesis:ListShards",
          "kinesis:ListStreams"
        ]
        Resource = [
          var.kinesis_stream_arn
        ]
      }
    ]
  })
}

# Permisos para consultar Glue Data Catalog y archivos S3 de Iceberg
resource "aws_iam_policy" "redshift_lakehouse" {
  name        = "${var.project_name}-${var.environment}-redshift-lakehouse-policy"
  description = "Permite a Redshift acceder al catalogo Glue y leer datos de Iceberg en S3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "glue:GetDatabase",
          "glue:GetDatabases",
          "glue:GetTable",
          "glue:GetTables",
          "glue:GetPartition",
          "glue:GetPartitions"
        ]
        Resource = [
          "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:catalog",
          "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:database/default",
          "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:database/${var.glue_database_name}",
          "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/${var.glue_database_name}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          var.data_bucket_arn,
          "${var.data_bucket_arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_kinesis" {
  role       = aws_iam_role.redshift.name
  policy_arn = aws_iam_policy.redshift_kinesis.arn
}

resource "aws_iam_role_policy_attachment" "attach_lakehouse" {
  role       = aws_iam_role.redshift.name
  policy_arn = aws_iam_policy.redshift_lakehouse.arn
}

# ==============================================================================
# 2. NETWORKING Y SEGURIDAD PARA REDSHIFT
# ==============================================================================

resource "aws_security_group" "redshift" {
  name        = "${var.project_name}-${var.environment}-redshift-sg"
  description = "Control de trafico para el cluster de Redshift"
  vpc_id      = var.vpc_id

  ingress {
    description = "Puerto Redshift desde dentro de la VPC"
    from_port   = 5439
    to_port     = 5439
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "Salida total a endpoints de AWS (Kinesis, Glue, S3)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-redshift-sg"
    Environment = var.environment
  }
}

resource "aws_redshift_subnet_group" "redshift" {
  name       = "${var.project_name}-${var.environment}-redshift-subnet-group"
  subnet_ids = var.subnet_ids

  tags = {
    Name        = "${var.project_name}-${var.environment}-redshift-subnet-group"
    Environment = var.environment
  }
}

# ==============================================================================
# 3. CLÚSTER REDSHIFT PROVISIONADO
# ==============================================================================

resource "aws_redshift_cluster" "main" {
  cluster_identifier        = "${var.project_name}-${var.environment}-redshift"
  database_name             = var.database_name
  master_username           = var.admin_username
  master_password           = var.admin_password
  node_type                 = var.node_type
  cluster_type              = "single-node"
  cluster_subnet_group_name = aws_redshift_subnet_group.redshift.name
  vpc_security_group_ids    = [aws_security_group.redshift.id]
  iam_roles                 = [aws_iam_role.redshift.arn]

  # Evita demoras y costos al destruir en laboratorios
  skip_final_snapshot       = true
  publicly_accessible       = false

  tags = {
    Name        = "${var.project_name}-${var.environment}-redshift-cluster"
    Environment = var.environment
  }
}