resource "aws_iam_role" "codebuild" {
  name = "AWS-CICD-CodeBuild-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"

      Principal = {
        Service = "codebuild.amazonaws.com"
      }

      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    Name = "AWS-CICD-CodeBuild-Role"
  }
}

resource "aws_iam_role_policy" "codebuild" {
  name = "AWS-CICD-CodeBuild-Policy"
  role = aws_iam_role.codebuild.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "CloudWatchLogs"
        Effect = "Allow"

        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]

        Resource = "*"
      },
      {
        Sid    = "ECRAuthentication"
        Effect = "Allow"

        Action = [
          "ecr:GetAuthorizationToken"
        ]

        Resource = "*"
      },
      {
        Sid    = "ECRPush"
        Effect = "Allow"

        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:CompleteLayerUpload",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart"
        ]

        Resource = aws_ecr_repository.application.arn
      },
      {
        Sid    = "STSIdentity"
        Effect = "Allow"

        Action = [
          "sts:GetCallerIdentity"
        ]

        Resource = "*"
      },
      {
        Sid    = "ECSMigration"
        Effect = "Allow"

        Action = [
          "ecs:RegisterTaskDefinition",
          "ecs:DeregisterTaskDefinition",
          "ecs:RunTask",
          "ecs:DescribeTasks"
        ]

        Resource = "*"
      },
      {
        Sid    = "PassECSTaskExecutionRole"
        Effect = "Allow"

        Action = [
          "iam:PassRole"
        ]

        Resource = aws_iam_role.ecs_task_execution.arn
      },
      {
        Sid    = "ReadRDSMasterSecret"
        Effect = "Allow"

        Action = [
          "secretsmanager:GetSecretValue"
        ]

        Resource = aws_db_instance.postgres.master_user_secret[0].secret_arn
      },
      {
        Sid    = "UpdateDatabaseUrlSecret"
        Effect = "Allow"

        Action = [
          "secretsmanager:PutSecretValue"
        ]

        Resource = aws_secretsmanager_secret.database_url.arn
      },
      {
        Sid    = "CodePipelineArtifactRead"
        Effect = "Allow"

        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion"
        ]

        Resource = "${aws_s3_bucket.artifacts.arn}/*"
      },
      {
        Sid    = "CodePipelineArtifactWrite"
        Effect = "Allow"

        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject"
        ]

        Resource = "${aws_s3_bucket.artifacts.arn}/*"
      }
    ]
  })
}

resource "aws_cloudwatch_log_group" "codebuild" {
  name              = "/aws/codebuild/AWS-Enterprise-CICD-Build"
  retention_in_days = 14

  tags = {
    Name = "AWS-Enterprise-CICD-Build"
  }
}

resource "aws_codebuild_project" "application" {
  name          = "AWS-Enterprise-CICD-Build"
  description   = "Build, test, containerize and publish the application to Amazon ECR"
  service_role  = aws_iam_role.codebuild.arn
  build_timeout = 20

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:7.0"
    type                        = "LINUX_CONTAINER"
    privileged_mode             = true
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = var.aws_region
    }

    environment_variable {
      name  = "ECR_REPOSITORY"
      value = aws_ecr_repository.application.name
    }

    environment_variable {
      name  = "CONTAINER_NAME"
      value = "aws-enterprise-cicd-app"
    }

    environment_variable {
      name  = "ECS_CLUSTER"
      value = aws_ecs_cluster.main.name
    }

    environment_variable {
      name  = "ECS_TASK_EXECUTION_ROLE_ARN"
      value = aws_iam_role.ecs_task_execution.arn
    }

    environment_variable {
      name  = "ECS_SECURITY_GROUP_ID"
      value = aws_security_group.ecs.id
    }

    environment_variable {
      name  = "ECS_SUBNET_A"
      value = aws_subnet.public.id
    }

    environment_variable {
      name  = "ECS_SUBNET_B"
      value = aws_subnet.public_b.id
    }

    environment_variable {
      name  = "DATABASE_URL_SECRET_ARN"
      value = aws_secretsmanager_secret.database_url.arn
    }

    environment_variable {
      name  = "RDS_MASTER_SECRET_ARN"
      value = aws_db_instance.postgres.master_user_secret[0].secret_arn
    }

    environment_variable {
      name  = "ECR_REPOSITORY_URI"
      value = aws_ecr_repository.application.repository_url
    }

    environment_variable {
      name  = "SECRET_KEY_ARN"
      value = aws_secretsmanager_secret.secret_key.arn
    }

    environment_variable {
      name  = "FIRST_SUPERUSER_ARN"
      value = aws_secretsmanager_secret.first_superuser.arn
    }

    environment_variable {
      name  = "FIRST_SUPERUSER_PASSWORD_ARN"
      value = aws_secretsmanager_secret.first_superuser_password.arn
    }

    environment_variable {
      name  = "POSTGRES_SERVER"
      value = aws_db_instance.postgres.address
    }

    environment_variable {
      name  = "POSTGRES_PORT"
      value = tostring(aws_db_instance.postgres.port)
    }

    environment_variable {
      name  = "POSTGRES_DB"
      value = aws_db_instance.postgres.db_name
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec.yml"
  }

  logs_config {
    cloudwatch_logs {
      group_name  = aws_cloudwatch_log_group.codebuild.name
      stream_name = "build"
    }
  }

  tags = {
    Name = "AWS-Enterprise-CICD-Build"
  }
}