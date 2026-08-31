# Copy this file to terraform.tfvars and fill in the values.

aws_region = "us-east-1"

environment = "dev"

# Required: ARN of the CodeConnections (formerly CodeStar Connections) connection to GitHub.
# Create it in the AWS Console under Developer Tools → Connections.
github_connection_arn = "arn:aws:codeconnections:us-east-1:407036964001:connection/a4ee57a9-6f18-4e0f-9c8c-637916578769"

# Required: GitHub repository in owner/name format
github_repository = "Naveen281991/aws-realtime-ci-cd"

github_branch = "main"

# Email used for the initial FastAPI superuser account
first_superuser_email = "admin@example.com"

# Optional: restrict future administrative access (currently unused for open ALB)
# admin_cidr = "203.0.113.10/32"
# Example AWS CLI command:
# aws codeconnections list-connections --region us-east-1