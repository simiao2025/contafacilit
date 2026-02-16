output "events_queue_url" {
  value = aws_sqs_queue.events.url
}

output "events_queue_arn" {
  value = aws_sqs_queue.events.arn
}

output "ai_jobs_queue_url" {
  value = aws_sqs_queue.ai_jobs.url
}

output "ai_jobs_queue_arn" {
  value = aws_sqs_queue.ai_jobs.arn
}
