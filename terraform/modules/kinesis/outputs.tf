output "stream_name" {
  description = "Name of the Kinesis Data Stream"
  value       = aws_kinesis_stream.main.name
}

output "stream_arn" {
  description = "ARN of the Kinesis Data Stream"
  value       = aws_kinesis_stream.main.arn
}

output "firehose_name" {
  description = "Name of the Kinesis Data Firehose"
  value       = aws_kinesis_firehose_delivery_stream.main.name
}

output "firehose_arn" {
  description = "ARN of the Kinesis Data Firehose"
  value       = aws_kinesis_firehose_delivery_stream.main.arn
}
