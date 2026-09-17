variable "environment" {
  description = "The environment for the Kinesis resources."
  type        = string
  default     = "dev"
}

variable "stream_name" {
  description = "Name of the Kinesis Stream"
  type        = string
}

variable "shard_count" {
  description = "Number of the shards for the Kinesis Stream."
  type        = number
  default     = 2
}

variable "project_name" {
  description = "Name of the project."
  type        = string
}

variable "bucket_name" {
  description = "Name of the destination S3 Bucket for Firehose."
  type        = string
}

variable "buffer_size_mb" {
  description = "Buffer size in mb."
  type        = number
  default     = 5
}

variable "buffer_interval_sec" {
  description = "Buffer interval in sec."
  type        = number
  default     = 60
}

