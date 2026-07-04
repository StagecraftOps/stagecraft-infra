# A dead-letter queue so a poison message (one that repeatedly fails
# processing) doesn't loop forever — it's moved here after 5 failed receives
# and can be inspected/replayed manually.
resource "aws_sqs_queue" "dlq" {
  name                      = "${var.name}-webhooks-dlq"
  message_retention_seconds = 1209600 # 14 days — keep failed messages longer than the main queue
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
