resource "aws_iam_role" "data_processing" {

  name = "${var.project_name}-${var.environment}-data-processing-role"


  assume_role_policy = jsonencode({

    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = [
            "lambda.amazonaws.com"
          ]
        }

        Action = "sts:AssumeRole"
      }
    ]
  })


  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_iam_policy" "data_processing_s3" {

  name = "${var.project_name}-${var.environment}-s3-processing-policy"


  policy = jsonencode({

    Version = "2012-10-17"

    Statement = [

      {
        Effect = "Allow"

        Action = [
          "s3:ListBucket"
        ]

        Resource = [
          var.data_bucket_arn
        ]
      },


      {
        Effect = "Allow"

        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]

        Resource = [
          "${var.data_bucket_arn}/*"
        ]
      }

    ]
  })
}

resource "aws_iam_role_policy_attachment" "data_processing" {

  role = aws_iam_role.data_processing.name

  policy_arn = aws_iam_policy.data_processing_s3.arn
}


resource "aws_iam_role" "audit" {
  name = "${var.project_name}-${var.environment}-audit-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = [
            "lambda.amazonaws.com"
          ]
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_iam_policy" "audit_read_only" {
  name = "${var.project_name}-${var.environment}-audit-read-only"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "s3:ListBucket",
          "s3:GetObject"
        ]

        Resource = [
          var.data_bucket_arn,
          "${var.data_bucket_arn}/*"
        ]
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "audit" {
  role       = aws_iam_role.audit.name
  policy_arn = aws_iam_policy.audit_read_only.arn
}