# ─────────────────────────────────────────────
# S3 Module — Buckets
# ─────────────────────────────────────────────

# ─── Bucket de Documentos (CSVs, PDFs) ──────

resource "aws_s3_bucket" "documents" {
  bucket = "${var.project_name}-${var.environment}-documents"

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-documents"
  })
}

resource "aws_s3_bucket_versioning" "documents" {
  bucket = aws_s3_bucket.documents.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "documents" {
  bucket = aws_s3_bucket.documents.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "documents" {
  bucket = aws_s3_bucket.documents.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "documents" {
  bucket = aws_s3_bucket.documents.id

  # CSVs de upload — mover para IA após 90 dias
  rule {
    id     = "csv-uploads-lifecycle"
    status = "Enabled"

    filter {
      prefix = "uploads/"
    }

    transition {
      days          = 90
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 365
      storage_class = "GLACIER"
    }
  }

  # PDFs gerados — manter 5 anos (conformidade fiscal)
  rule {
    id     = "pdf-reports-lifecycle"
    status = "Enabled"

    filter {
      prefix = "reports/"
    }

    transition {
      days          = 180
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 730
      storage_class = "GLACIER"
    }

    expiration {
      days = 1825 # 5 anos
    }
  }
}

# ─── Bucket de Logs (audit trail) ───────────

resource "aws_s3_bucket" "logs" {
  bucket = "${var.project_name}-${var.environment}-logs"

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-logs"
  })
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "logs" {
  bucket = aws_s3_bucket.logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    id     = "logs-lifecycle"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    expiration {
      days = 365
    }
  }
}
