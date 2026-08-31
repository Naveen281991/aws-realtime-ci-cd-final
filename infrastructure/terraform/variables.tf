variable "aws_region" {
  description = "AWS region used by the deployment."
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Deployment environment name."
  type        = string
  default     = "dev"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.environment))
    error_message = "environment must contain only lowercase letters, digits, and hyphens."
  }
}

variable "github_connection_arn" {
  description = "AWS CodeConnections ARN used by CodePipeline to access the GitHub repository."
  type        = string

  validation {
    condition     = can(regex("^arn:aws[a-zA-Z-]*:codeconnections:[^:]+:[0-9]{12}:connection/[0-9a-f-]+$", var.github_connection_arn))
    error_message = "github_connection_arn must be a valid AWS CodeConnections connection ARN."
  }
}

variable "github_repository" {
  description = "GitHub repository in owner/name format."
  type        = string

  validation {
    condition     = can(regex("^[^/]+/[^/]+$", var.github_repository))
    error_message = "github_repository must use owner/name format."
  }
}

variable "github_branch" {
  description = "Git branch monitored by CodePipeline."
  type        = string
  default     = "main"
}

variable "admin_cidr" {
  description = "Reserved administrator CIDR for future restricted administrative access."
  type        = string
  default     = "0.0.0.0/0"

  validation {
    condition     = can(cidrhost(var.admin_cidr, 0))
    error_message = "admin_cidr must be a valid CIDR block."
  }
}

variable "first_superuser_email" {
  description = "Email address for the initial FastAPI administrator."
  type        = string
  default     = "admin@example.com"

  validation {
    condition     = can(regex("^[^@[:space:]]+@[^@[:space:]]+\\.[^@[:space:]]+$", var.first_superuser_email))
    error_message = "first_superuser_email must be a valid email address."
  }
}
