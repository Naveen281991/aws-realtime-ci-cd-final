# Step 2 — FastAPI CodeBuild Integration

`buildspec.yml` now performs the FastAPI CI/CD flow:

1. Installs `uv` and Python 3.14.
2. Installs the locked workspace dependencies and development tools.
3. Starts an isolated PostgreSQL container for tests.
4. Runs Ruff.
5. Runs mypy.
6. Runs the complete pytest suite.
7. Authenticates to ECR.
8. Builds the repository-root FastAPI/full-stack Docker image with BuildKit.
9. Pushes the immutable source revision tag and `latest`.
10. Generates `imagedefinitions.json` for the ECS CodePipeline deploy action.

The database credentials and application secrets in this file are CI-only test values. They are not production credentials and must not be reused by ECS.

Production runtime secrets, ECS health checks, ports, migrations, and task-definition configuration are intentionally handled in later integration steps.
