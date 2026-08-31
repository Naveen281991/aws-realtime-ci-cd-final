# Step 4 — FastAPI Production Secrets

## Where the values come from

### `SECRET_KEY`

You do **not** obtain this from FastAPI or AWS. It is an application signing secret that we generate ourselves.

Generate one locally:

```bash
openssl rand -hex 32
```

Use the generated value only for this application's production environment.

### `FIRST_SUPERUSER`

This is the email address of the initial administrator account.

Example:

```text
admin@your-domain.com
```

You choose this value. It does not come from AWS.

### `FIRST_SUPERUSER_PASSWORD`

This is the initial administrator password.

Generate a strong random value locally, for example:

```bash
openssl rand -base64 32
```

Do not commit it to Git or put it in `buildspec.yml`.

### `DATABASE_URL`

This is not generated yet.

It must point to the PostgreSQL database that will run in AWS. Its final value depends on the RDS/database infrastructure, which is handled in the next database phase.

Example shape:

```text
postgresql://USERNAME:PASSWORD@RDS_ENDPOINT:5432/DATABASE_NAME
```

The username/password will come from the database configuration, not from FastAPI.

## What Step 4 creates

Terraform creates four empty AWS Secrets Manager entries:

- `aws-enterprise-cicd/app/SECRET_KEY`
- `aws-enterprise-cicd/app/DATABASE_URL`
- `aws-enterprise-cicd/app/FIRST_SUPERUSER`
- `aws-enterprise-cicd/app/FIRST_SUPERUSER_PASSWORD`

Terraform does **not** store the secret values.

ECS retrieves these values at task startup through its task execution role.

## Populate the secrets

After `terraform apply`, use AWS CLI from a trusted machine:

```bash
aws secretsmanager put-secret-value   --secret-id aws-enterprise-cicd/app/SECRET_KEY   --secret-string 'PASTE_GENERATED_SECRET_KEY_HERE'
```

```bash
aws secretsmanager put-secret-value   --secret-id aws-enterprise-cicd/app/FIRST_SUPERUSER   --secret-string 'admin@your-domain.com'
```

```bash
aws secretsmanager put-secret-value   --secret-id aws-enterprise-cicd/app/FIRST_SUPERUSER_PASSWORD   --secret-string 'PASTE_GENERATED_PASSWORD_HERE'
```

`DATABASE_URL` should be populated after the PostgreSQL/RDS endpoint and credentials are finalized.

## Security rule

Do not put production values into:

- Git
- `.env` committed to Git
- `buildspec.yml`
- Dockerfile
- Terraform `.tf` files
- Terraform `.tfvars` files

The repository contains only references to Secrets Manager ARNs.

## Important

Changing `FIRST_SUPERUSER_PASSWORD` later does not automatically change the password of an already-created database user. The application creates the initial superuser when the database is initialized. Existing user credentials are managed in the application database.
