# Step 6 — Deployment Pipeline Validation

## Deployment flow

```text
Source
  ↓
CodeBuild
  ├── lint
  ├── type-check
  ├── tests
  ├── Docker build
  ├── push immutable image
  ├── synchronize DATABASE_URL
  ├── run one-off ECS migration task
  │     ├── alembic upgrade head
  │     └── python -m app.initial_data
  └── imagedefinitions.json
          ↓
      CodePipeline ECS Deploy
          ↓
       ECS Fargate
          ↓
          ALB
```

## Migration failure behavior

The CodeBuild phase exits non-zero if the migration task cannot start, times out, or exits with a non-zero container exit code. CodePipeline therefore does not execute the ECS deployment action.

## Secret handling

- RDS owns the master password in AWS Secrets Manager.
- CodeBuild reads it only to construct `DATABASE_URL`.
- The application `DATABASE_URL` secret is updated in Secrets Manager.
- The migration task and ECS service consume the secret at runtime.
- No production database password is stored in Git, Terraform source, Docker layers, or build artifacts.

## Image handling

- `${CODEBUILD_RESOLVED_SOURCE_VERSION}` is the deployment image tag.
- `latest` exists only as the Terraform bootstrap image.
- `imagedefinitions.json` always points ECS deployment at the immutable source revision tag.
