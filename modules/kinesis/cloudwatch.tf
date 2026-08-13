resource "aws_cloudwatch_metric_alarm" "write_throughput_exceeded" {
  alarm_name = "${var.stream_name}-write-throughput-exceeded"

  alarm_description = "Alarma cuando Kinesis supera el throughput de escritura provisionado."

  namespace   = "AWS/Kinesis"
  metric_name = "WriteProvisionedThroughputExceeded"

  dimensions = {
    StreamName = var.stream_name
  }

  statistic           = "Sum"
  period              = 60
  evaluation_periods  = 1
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"

  treat_missing_data = "notBreaching"
}


resource "aws_cloudwatch_metric_alarm" "read_throughput_exceeded" {
  alarm_name = "${var.stream_name}-read-throughput-exceeded"

  alarm_description = "Alarma cuando Kinesis supera el throughput de lectura provisionado."

  namespace   = "AWS/Kinesis"
  metric_name = "ReadProvisionedThroughputExceeded"

  dimensions = {
    StreamName = var.stream_name
  }

  statistic           = "Sum"
  period              = 60
  evaluation_periods  = 1
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"

  treat_missing_data = "notBreaching"
}