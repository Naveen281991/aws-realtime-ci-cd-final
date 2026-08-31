# Step 4 — Secrets and Runtime Configuration

Implemented:

- AWS Secrets Manager resources for four FastAPI runtime secrets.
- ECS task execution permission limited to those four secret ARNs.
- ECS task definition now injects secrets at startup.
- Non-secret runtime configuration is defined in ECS.
- ECS container health check now calls the FastAPI health endpoint.
- ECS security group now allows ALB traffic on TCP/8000.
- No production secret values are stored in Terraform configuration.

Not finalized yet:

- PostgreSQL/RDS endpoint and credentials.
- Production `DATABASE_URL` value.
- Database migration execution strategy.
- SMTP credentials, if email is enabled in production.
