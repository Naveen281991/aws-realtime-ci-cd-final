# AWS Enterprise Real-Time CI/CD Platform

## Overview

This project implements a production-oriented CI/CD platform on AWS that automatically builds, tests, and deploys a full-stack FastAPI + React (Bun) application to Amazon ECS Fargate.

It demonstrates real-world DevOps practices including:

- Infrastructure as Code with Terraform
- Automated testing (Ruff, mypy, pytest)
- Docker image builds and ECR pushes
- Continuous deployment to ECS Fargate
- Application Load Balancer + health checks
- Amazon RDS PostgreSQL
- Secrets Manager for sensitive configuration
- IAM least-privilege roles
- CodePipeline + CodeBuild orchestration

## Architecture

```
GitHub (main)
     │
     ▼
AWS CodePipeline
     │
     ├─ Source (CodeConnections)
     │
     ▼
AWS CodeBuild
     │
     ├─ Install uv + Python
     ├─ Start ephemeral Postgres for tests
     ├─ Ruff + mypy + pytest
     ├─ Docker build (multi-stage: frontend + backend)
     ├─ Push image to Amazon ECR
     ├─ Run production DB migrations (ECS task)
     └─ Produce imagedefinitions.json
     │
     ▼
Amazon ECR
     │
     ▼
Amazon ECS Fargate (service)
     │
     ▼
Application Load Balancer
     │
     ▼
Live FastAPI application (+ React frontend)
```

Supporting services:

- Amazon RDS PostgreSQL (private subnets)
- AWS Secrets Manager (SECRET_KEY, DATABASE_URL, superuser credentials)
- Amazon CloudWatch Logs
- VPC with public + private subnets

## Technologies

- **Application**: FastAPI, SQLModel, React (Vite + Bun), PostgreSQL
- **CI/CD**: AWS CodePipeline, AWS CodeBuild, Amazon ECR, Amazon ECS Fargate
- **Networking**: VPC, ALB, Security Groups
- **Data**: Amazon RDS PostgreSQL
- **Secrets / Config**: AWS Secrets Manager
- **IaC**: Terraform (>= 1.5 recommended)
- **Local Dev**: Docker Compose, uv, Bun

## Project Structure

```
.
├── backend/                 # FastAPI application
├── frontend/                # React frontend (Bun)
├── infrastructure/terraform # All AWS resources
├── buildspec.yml            # CodeBuild definition
├── Dockerfile               # Multi-stage production image
├── compose.yml              # Local development
└── README.md
```

## Prerequisites

1. AWS account with permissions to create VPC, ECS, ECR, RDS, CodePipeline, CodeBuild, IAM, Secrets Manager, ALB, etc.
2. Terraform >= 1.5 (tested with 1.9+)
3. AWS CLI configured (`aws configure`)
4. GitHub repository (this one or a fork)
5. AWS CodeConnections connection to GitHub (see setup below)

## Quick Start – Local Development

```bash
# 1. Create local environment file (required by compose.yml)
cp .env.example .env
# Defaults work for local development. Change SECRET_KEY / passwords for anything beyond testing.

# 2. Start Postgres + Mailpit
docker compose up -d db mailpit

# 3. Backend
cd backend
uv sync
uv run bash scripts/prestart.sh
uv run fastapi dev
# → http://localhost:8000/docs

# 4. Frontend (separate terminal)
cd frontend
bun install
bun run dev
# → http://localhost:5173
```

## Infrastructure Deployment (Terraform)

### 1. Create GitHub CodeConnections connection

In the AWS Console:

1. Go to **Developer Tools → Connections**
2. Create a connection to GitHub
3. Authorize and note the Connection ARN

### 2. Configure variables

Create `infrastructure/terraform/terraform.tfvars`:

```hcl
aws_region             = "us-east-1"
environment            = "dev"
github_connection_arn  = "arn:aws:codeconnections:us-east-1:ACCOUNT_ID:connection/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
github_repository      = "Naveen281991/aws-realtime-ci-cd"   # or your fork
github_branch          = "main"
first_superuser_email  = "admin@yourdomain.com"
# admin_cidr           = "x.x.x.x/32"   # optional, for future restricted access
```

### 3. Deploy

```bash
cd infrastructure/terraform

terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

### 4. Important outputs

After apply, note:

- ALB DNS name
- ECR repository URL
- CodePipeline name
- RDS endpoint (private)

## CI/CD Flow

1. Push to the monitored branch (`main` by default).
2. CodePipeline detects the change via CodeConnections.
3. CodeBuild:
   - Installs dependencies with `uv`
   - Spins up a temporary Postgres container
   - Runs linting, type checking, and unit tests
   - Builds the multi-stage Docker image (frontend assets + FastAPI)
   - Pushes the image tagged with the commit SHA + `latest` to ECR
   - Runs a one-off ECS task to apply Alembic migrations against the production RDS
   - Writes `imagedefinitions.json`
4. CodePipeline deploys the new image to the ECS service.
5. ALB health checks and the container health check validate the deployment.

## Application Endpoints

- `/` – Frontend
- `/api/v1/...` – FastAPI routes
- `/api/v1/utils/health-check/` – Health endpoint used by ECS & ALB
- `/docs` – Interactive OpenAPI docs

## Cleanup

```bash
cd infrastructure/terraform
terraform destroy
```

**Warning**: RDS has `deletion_protection = true` and will take a final snapshot by default. Adjust if needed for non-production environments.

## Known Notes / Hardening Suggestions

- ECS tasks run in public subnets with public IPs for simplicity (outbound internet for ECR/Secrets). For stricter security move tasks to private subnets + NAT Gateway.
- Consider adding CloudWatch alarms, ECS circuit-breaker, and deployment circuit breakers.
- ECR lifecycle policy can be added to prune old images.
- The `admin_cidr` variable is reserved for future restricted management access.

## License

See [LICENSE](LICENSE).

---

This repository was adapted from the excellent full-stack FastAPI template and extended with a complete AWS Terraform + CodePipeline implementation.
