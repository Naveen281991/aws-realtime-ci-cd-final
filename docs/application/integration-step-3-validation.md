# Step 3 — Docker/ECS/ALB Validation

The deployment contract is now FastAPI-specific.

- Application port: `8000`
- ALB target port: `8000`
- FastAPI health endpoint: `/api/v1/utils/health-check/`
- ECS container name: `aws-enterprise-cicd-app`
- Docker image is built from the repository-root `Dockerfile`

Terraform files modified:
- `infrastructure/terraform/alb.tf`
- `infrastructure/terraform/ecs.tf`

Potential old references found in Terraform:
- `infrastructure/terraform/ecs-security.tf contains 3000`
- `infrastructure/terraform/ecs.tf contains 3000`
- `infrastructure/terraform/alb.tf contains 3000`
