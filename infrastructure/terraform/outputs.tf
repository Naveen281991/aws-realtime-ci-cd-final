output "vpc_id" {
  description = "ID of the CI/CD VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = aws_subnet.public.id
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}

output "artifact_bucket_name" {
  description = "S3 bucket used for CI/CD artifacts"
  value       = aws_s3_bucket.artifacts.id
}

output "artifact_bucket_arn" {
  description = "ARN of the CI/CD artifact bucket"
  value       = aws_s3_bucket.artifacts.arn
}

output "ecr_repository_name" {
  description = "ECR repository name for the application"
  value       = aws_ecr_repository.application.name
}

output "ecr_repository_url" {
  description = "ECR repository URL for the application"
  value       = aws_ecr_repository.application.repository_url
}

output "ecr_repository_arn" {
  description = "ECR repository ARN for the application"
  value       = aws_ecr_repository.application.arn
}


output "alb_dns_name" {
  description = "Public DNS name of the application load balancer"
  value       = aws_lb.application.dns_name
}

output "target_group_arn" {
  description = "ARN of the ECS application target group"
  value       = aws_lb_target_group.application.arn
}


output "fastapi_secret_arns" {
  description = "ARNs of the FastAPI runtime secrets that must be populated in AWS Secrets Manager"
  value = {
    secret_key               = aws_secretsmanager_secret.secret_key.arn
    database_url             = aws_secretsmanager_secret.database_url.arn
    first_superuser          = aws_secretsmanager_secret.first_superuser.arn
    first_superuser_password = aws_secretsmanager_secret.first_superuser_password.arn
  }
}
