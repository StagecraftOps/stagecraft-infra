variable "name" {
  type = string
}

variable "visibility_timeout_seconds" {
  description = "Must be >= the SQS consumer's VisibilityTimeout in stagecraft-worker/app/sqs_consumer.py (currently 60s)"
  type        = number
  default     = 60
}

variable "message_retention_seconds" {
  type    = number
  default = 345600 # 4 days
}
