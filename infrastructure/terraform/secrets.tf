resource "aws_secretsmanager_secret" "secret_key" {
  name                    = "aws-enterprise-cicd/app/SECRET_KEY"
  description             = "FastAPI JWT signing secret"
  recovery_window_in_days = 7

  tags = {
    Name = "aws-enterprise-cicd-app-secret-key"
  }
}

resource "aws_secretsmanager_secret" "database_url" {
  name                    = "aws-enterprise-cicd/app/DATABASE_URL"
  description             = "FastAPI PostgreSQL connection URL"
  recovery_window_in_days = 7

  tags = {
    Name = "aws-enterprise-cicd-app-database-url"
  }
}

resource "aws_secretsmanager_secret" "first_superuser" {
  name                    = "aws-enterprise-cicd/app/FIRST_SUPERUSER"
  description             = "Initial FastAPI administrator email"
  recovery_window_in_days = 7

  tags = {
    Name = "aws-enterprise-cicd-app-first-superuser"
  }
}

resource "aws_secretsmanager_secret" "first_superuser_password" {
  name                    = "aws-enterprise-cicd/app/FIRST_SUPERUSER_PASSWORD"
  description             = "Initial FastAPI administrator password"
  recovery_window_in_days = 7

  tags = {
    Name = "aws-enterprise-cicd-app-first-superuser-password"
  }
}

resource "aws_iam_role_policy" "ecs_secrets" {
  name = "AWS-CICD-ECS-SecretsManager-Read"
  role = aws_iam_role.ecs_task_execution.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"
      Action = [
        "secretsmanager:GetSecretValue"
      ]
      Resource = [
        aws_secretsmanager_secret.secret_key.arn,
        aws_secretsmanager_secret.database_url.arn,
        aws_secretsmanager_secret.first_superuser.arn,
        aws_secretsmanager_secret.first_superuser_password.arn
      ]
    }]
  })
}

resource "aws_iam_role_policy" "codebuild_database_secrets" {
  name = "AWS-CICD-CodeBuild-Database-Secrets"
  role = aws_iam_role.codebuild.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = aws_db_instance.postgres.master_user_secret[0].secret_arn
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:PutSecretValue"
        ]
        Resource = aws_secretsmanager_secret.database_url.arn
      }
    ]
  })
}

resource "random_password" "secret_key" {
  length  = 64
  special = true
}

resource "random_password" "first_superuser_password" {
  length           = 32
  special          = true
  override_special = "!@#$%^&*()-_=+[]{}"
}

resource "aws_secretsmanager_secret_version" "secret_key" {
  secret_id     = aws_secretsmanager_secret.secret_key.id
  secret_string = random_password.secret_key.result
}

resource "aws_secretsmanager_secret_version" "first_superuser" {
  secret_id     = aws_secretsmanager_secret.first_superuser.id
  secret_string = var.first_superuser_email
}

resource "aws_secretsmanager_secret_version" "first_superuser_password" {
  secret_id     = aws_secretsmanager_secret.first_superuser_password.id
  secret_string = random_password.first_superuser_password.result
}

data "aws_secretsmanager_secret_version" "rds_master" {
  secret_id = aws_db_instance.postgres.master_user_secret[0].secret_arn

  depends_on = [aws_db_instance.postgres]
}

locals {
  rds_master_credentials = jsondecode(data.aws_secretsmanager_secret_version.rds_master.secret_string)
  bootstrap_database_url = format(
    "postgresql://%s:%s@%s:%d/%s",
    urlencode(local.rds_master_credentials.username),
    urlencode(local.rds_master_credentials.password),
    aws_db_instance.postgres.address,
    aws_db_instance.postgres.port,
    aws_db_instance.postgres.db_name,
  )
}

resource "aws_secretsmanager_secret_version" "database_url" {
  secret_id     = aws_secretsmanager_secret.database_url.id
  secret_string = local.bootstrap_database_url

  depends_on = [aws_db_instance.postgres]
}
