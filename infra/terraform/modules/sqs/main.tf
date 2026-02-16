resource "aws_sqs_queue" "events" {
  name                      = "${var.project_name}-${var.environment}-events-queue"
  delay_seconds             = 0
  max_message_size          = 262144
  message_retention_seconds = 86400
  receive_wait_time_seconds = 10
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.events_dlq.arn
    maxReceiveCount     = 5
  })

  tags = var.tags
}

resource "aws_sqs_queue" "events_dlq" {
  name = "${var.project_name}-${var.environment}-events-dlq"
  tags = var.tags
}

resource "aws_sqs_queue" "ai_jobs" {
  name                      = "${var.project_name}-${var.environment}-ai-jobs-queue"
  delay_seconds             = 0
  visibility_timeout_seconds = 300 # Tempo para a IA processar
  max_message_size          = 262144
  message_retention_seconds = 345600
  receive_wait_time_seconds = 20
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.ai_jobs_dlq.arn
    maxReceiveCount     = 3
  })

  tags = var.tags
}

resource "aws_sqs_queue" "ai_jobs_dlq" {
  name = "${var.project_name}-${var.environment}-ai-jobs-dlq"
  tags = var.tags
}
