resource "aws_iam_role" "ecs_task_execution" {
  name = "AWS-CICD-ECS-TaskExecution-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"

      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }

      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    Name = "AWS-CICD-ECS-TaskExecution-Role"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_cluster" "main" {
  name = "aws-enterprise-cicd-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "aws-enterprise-cicd-cluster"
  }
}

resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/aws-enterprise-cicd-app"
  retention_in_days = 7

  tags = {
    Name = "aws-enterprise-cicd-app-logs"
  }
}

resource "aws_ecs_task_definition" "application" {
  family                   = "aws-enterprise-cicd-app"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  cpu    = "256"
  memory = "512"

  execution_role_arn = aws_iam_role.ecs_task_execution.arn

  container_definitions = jsonencode([
    {
      name      = "aws-enterprise-cicd-app"
      image     = "${aws_ecr_repository.application.repository_url}:latest"
      essential = true

      environment = [
        {
          name  = "PROJECT_NAME"
          value = "AWS Enterprise FastAPI"
        },
        {
          name  = "FASTAPI_ENV"
          value = "production"
        },
        {
          name  = "FRONTEND_HOST"
          value = "http://${aws_lb.application.dns_name}"
        },
        {
          name  = "POSTGRES_SERVER"
          value = aws_db_instance.postgres.address
        },
        {
          name  = "POSTGRES_PORT"
          value = tostring(aws_db_instance.postgres.port)
        },
        {
          name  = "POSTGRES_DB"
          value = aws_db_instance.postgres.db_name
        },
        {
          name  = "POSTGRES_USER"
          value = aws_db_instance.postgres.username
        }
      ]

      secrets = [
        {
          name      = "SECRET_KEY"
          valueFrom = aws_secretsmanager_secret.secret_key.arn
        },
        {
          name      = "DATABASE_URL"
          valueFrom = aws_secretsmanager_secret.database_url.arn
        },
        {
          name      = "FIRST_SUPERUSER"
          valueFrom = aws_secretsmanager_secret.first_superuser.arn
        },
        {
          name      = "FIRST_SUPERUSER_PASSWORD"
          valueFrom = aws_secretsmanager_secret.first_superuser_password.arn
        }
      ]

      portMappings = [
        {
          containerPort = 8000
          hostPort      = 8000
          protocol      = "tcp"
        }
      ]

      healthCheck = {
        command = [
          "CMD-SHELL",
          "python -c \"import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/api/v1/utils/health-check/', timeout=3)\""
        ]

        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }

      logConfiguration = {
        logDriver = "awslogs"

        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])

  tags = {
    Name = "aws-enterprise-cicd-app-task"
  }
}