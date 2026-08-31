# Step 1 — Repository Integration

The FastAPI full-stack application is now the application source of the AWS CI/CD repository.

## Final ownership

- `backend/` — FastAPI application, tests, migrations, and Python dependencies.
- `frontend/` — Bun/Vite frontend.
- `packages/` — shared frontend packages.
- `Dockerfile` — repository-root production image definition for the FastAPI full-stack application.
- `buildspec.yml` — retained as the AWS CodeBuild entry point; application-specific commands are updated in the next integration step.
- `infrastructure/terraform/` — retained AWS infrastructure definition.
- `docs/` — retained CI/CD documentation plus FastAPI application documentation.

## Removed from the application source

- Legacy Node.js `application/` service.
- Legacy root Node.js `Dockerfile`.
- Legacy CodeDeploy `appspec.yml` and deployment scripts.
- Duplicate `full-stack-fastapi-template/` directory.
- Root Node.js lockfile that was not associated with the FastAPI application.

## Deliberately not copied

- Git metadata.
- Local `.env` files.
- Terraform state files.
- FastAPI project's GitHub Actions workflows, because AWS CodePipeline/CodeBuild is the repository's CI/CD system.

## Important boundary

This step changes repository ownership and structure only. AWS runtime configuration, CodeBuild commands, ECS port/health checks, secrets, database migration execution, and deployment behavior are handled in subsequent steps.
