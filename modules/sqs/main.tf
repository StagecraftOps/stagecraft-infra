
resource "aws_sqs_queue" "dlq" {
  name                      = "${var.name}-webhooks-dlq"
  message_retention_seconds = 1209600
}

resource "aws_sqs_queue" "this" {
  name                       = "${var.name}-webhooks"
  visibility_timeout_seconds = var.visibility_timeout_seconds
  message_retention_seconds  = var.message_retention_seconds

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 5
  })

  tags = { Name = "${var.name}-webhooks" }
}
