provider "aws" {
  region = "us-east-1"
}

# Bucket S3
resource "aws_s3_bucket" "example" {
  bucket = "meu-bucket-com-email-alerta"
}

# SNS Topic
resource "aws_sns_topic" "s3_notifications" {
  name = "s3-events-topic"
}

# Assinatura de E-mail
resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.s3_notifications.arn
  protocol  = "email"
  endpoint  = "santosnune@gmail.com"  # <-- Altere para seu e-mail real
}

# Permissão para o S3 publicar no SNS
resource "aws_sns_topic_policy" "sns_policy" {
  arn    = aws_sns_topic.s3_notifications.arn
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "AllowS3Publish",
        Effect    = "Allow",
        Principal = {
          Service = "s3.amazonaws.com"
        },
        Action   = "SNS:Publish",
        Resource = aws_sns_topic.s3_notifications.arn,
        Condition = {
          StringEquals = {
            "aws:SourceArn" = aws_s3_bucket.example.arn
          }
        }
      }
    ]
  })
}

# Notificações de evento do Bucket S3
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.example.id

  topic {
    topic_arn = aws_sns_topic.s3_notifications.arn
    events    = ["s3:ObjectCreated:*", "s3:ObjectRemoved:*"]
  }

  depends_on = [aws_sns_topic_policy.sns_policy]
}
