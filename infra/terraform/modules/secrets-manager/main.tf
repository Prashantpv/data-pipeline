locals {
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

resource "aws_secretsmanager_secret" "this" {
  name                    = var.secret_name
  recovery_window_in_days = 30

  tags = merge(local.common_tags, {
    Name = var.secret_name
  })
}

resource "aws_secretsmanager_secret_version" "this" {
  secret_id     = aws_secretsmanager_secret.this.id
  secret_string = var.secret_value
}
