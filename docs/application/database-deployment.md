# Step 5 — PostgreSQL/RDS + Alembic

## Database architecture

```text
ECS FastAPI
    |
    | TCP 5432
    v
RDS PostgreSQL
    |
    +-- private subnets
    +-- encrypted storage
    +-- automated backups
    +-- no public access
```

The RDS security group accepts PostgreSQL traffic only from the ECS task security group.

## Runtime configuration

The ECS task receives:

- `POSTGRES_SERVER` from the RDS endpoint.
- `POSTGRES_PORT` from the RDS instance.
- `POSTGRES_DB` from the RDS database name.
- `POSTGRES_USER` from the RDS database username.
- `DATABASE_URL` from AWS Secrets Manager.

The final `DATABASE_URL` must use the actual RDS endpoint and password mechanism supported by the application.

## RDS master password

RDS manages its master password through AWS Secrets Manager because `manage_master_user_password = true`.

Do not copy that password into Git or Terraform source.

## Alembic

Database schema changes are versioned in the FastAPI repository's Alembic migration directory.

Production deployment must run:

```bash
alembic upgrade head
```

before the new ECS task revision receives production traffic.

## Important deployment ordering

```text
Build image
   |
   v
Push image to ECR
   |
   v
Run Alembic migrations
   |
   v
Deploy ECS task revision
   |
   v
ALB health check
   |
   v
Production traffic
```

Migration execution is deliberately separated from the ECS application container startup so multiple ECS tasks do not race to perform migrations.

## Current scope

This step creates the RDS infrastructure and migration runner. CodeBuild now launches a one-off ECS Fargate migration task using the exact image being deployed. The task runs Alembic migrations and initializes the first superuser before the ECS service is updated.
