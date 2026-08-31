# Step 7 — Final Validation + Pre-Deployment Testing

## Result

The Step-6 configuration was statically reviewed and the remaining deployment blockers were corrected.

### Corrected before deployment

- Removed the obsolete EC2/CodeDeploy Terraform application path.
- Removed obsolete EC2/CodeDeploy Terraform outputs.
- Removed the committed Terraform state backup from the project artifact.
- Removed copied Git metadata from the project artifact.
- Added CodeBuild permission to read the RDS-managed master secret.
- Added CodeBuild permission to update only the FastAPI `DATABASE_URL` secret.
- Kept ECS on port `8000`.
- Kept the ALB health check on `/api/v1/utils/health-check/`.
- Kept immutable ECR image deployment through `imagedefinitions.json`.
- Kept production migrations as an ECS one-off Fargate task.

## Static checks performed

- Buildspec YAML parsed successfully.
- FastAPI backend Python files compiled successfully after correcting the invalid multi-exception syntax in `backend/app/api/deps.py`.
- ECS application port is `8000`.
- ALB target port is `8000`.
- ALB health endpoint is `/api/v1/utils/health-check/`.
- No Terraform state files remain in the deliverable.
- No `.git` metadata remains in the deliverable.

## Required local validation before `terraform apply`

Run:

```bash
./scripts/validate-pre-deployment.sh
```

The script performs:

```text
terraform fmt -check
terraform init -backend=false
terraform validate
Python compileall
buildspec YAML validation
deployment contract checks
```

## AWS validation order

Do not run `terraform apply` until these prerequisites are ready:

1. AWS credentials are configured for the intended account.
2. The GitHub CodeConnections connection is valid and points to the intended repository.
3. The `admin_cidr` variable is no longer required by the ECS-only infrastructure.
4. The FastAPI `SECRET_KEY`, `FIRST_SUPERUSER`, and `FIRST_SUPERUSER_PASSWORD` secrets are populated.
5. RDS has finished provisioning and its managed master secret is available.
6. The CodeBuild service role can read the RDS master secret and update `DATABASE_URL`.
7. ECS task execution can read the four FastAPI runtime secrets.
8. The selected AWS account and region are correct.

## First deployment test

The first AWS deployment should be treated as a controlled validation:

```text
terraform plan
    ↓
terraform apply
    ↓
wait for RDS available
    ↓
populate FastAPI secrets
    ↓
start CodePipeline
    ↓
CodeBuild tests
    ↓
Docker build
    ↓
ECR push
    ↓
migration task
    ↓
ECS deployment
    ↓
ALB health checks
    ↓
application smoke test
```

## Important limitation

Terraform CLI was not available in the current execution environment, so `terraform fmt`, `terraform init`, and `terraform validate` could not be executed here. The repository includes the validation script so those checks can be run on the machine/CI runner that has Terraform installed.

No AWS resources were created or modified during this validation step.

## Application defect fixed during validation

`backend/app/api/deps.py` contained invalid Python syntax: `except InvalidTokenError, ValidationError:`. It is now the valid Python 3 form: `except (InvalidTokenError, ValidationError):`. This defect would have stopped CodeBuild before tests could run.
