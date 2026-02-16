# ─────────────────────────────────────────────
# S3 Module — Outputs
# ─────────────────────────────────────────────

output "documents_bucket_name" {
  value = aws_s3_bucket.documents.bucket
}

output "documents_bucket_arn" {
  value = aws_s3_bucket.documents.arn
}

output "logs_bucket_name" {
  value = aws_s3_bucket.logs.bucket
}

output "logs_bucket_arn" {
  value = aws_s3_bucket.logs.arn
}
