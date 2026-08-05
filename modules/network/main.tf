
resource "aws_vpc" "main" {

  cidr_block = var.vpc_cidr

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "${var.project_name}-vpc"
    Environment = var.environment
  }
}

# For each porque queremos dos subredes sin repetir codigo
resource "aws_subnet" "private" {

  for_each = {
    private-1 = var.private_subnet_cidrs[0]
    private-2 = var.private_subnet_cidrs[1]
  }

  vpc_id = aws_vpc.main.id

  cidr_block = each.value

  availability_zone = each.key == "private-1" ? "us-east-1a" : "us-east-1b"


  tags = {
    Name        = "${var.project_name}-${each.key}"
    Environment = var.environment
  }
}

resource "aws_route_table" "private" {

  vpc_id = aws_vpc.main.id


  tags = {
    Name = "${var.project_name}-private-route-table"
  }
}

resource "aws_route_table_association" "private" {

  for_each = aws_subnet.private

  subnet_id = each.value.id

  route_table_id = aws_route_table.private.id
}

#gatewat
resource "aws_vpc_endpoint" "s3" {

  vpc_id = aws_vpc.main.id


  service_name = "com.amazonaws.us-east-1.s3"


  vpc_endpoint_type = "Gateway"


  route_table_ids = [
    aws_route_table.private.id
  ]


  tags = {
    Name = "${var.project_name}-s3-endpoint"
  }
}