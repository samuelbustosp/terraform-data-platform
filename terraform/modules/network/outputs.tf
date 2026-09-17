output "vpc_id" {

  description = "ID of the VPC."

  value = aws_vpc.main.id
}


output "private_subnet_ids" {

  description = "IDs of private subnets."

  value = [
    for subnet in aws_subnet.private :
    subnet.id
  ]
}