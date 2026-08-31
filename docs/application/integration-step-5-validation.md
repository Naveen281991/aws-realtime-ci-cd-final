# Step 5 — PostgreSQL/RDS + Alembic Validation

Implemented:

- Private RDS PostgreSQL 17 instance.
- Encrypted GP3 storage.
- Automated backups.
- No public RDS access.
- RDS security group accepts port 5432 only from ECS tasks.
- RDS master password managed by AWS Secrets Manager.
- ECS receives RDS endpoint/database/user runtime values.
- Added a dedicated Alembic migration runner script.
- Documented migration ordering.

Not yet wired:

- CodeBuild/CodePipeline execution of the migration runner.
- Final DATABASE_URL population from the RDS endpoint and application database credentials.

Those belong to the deployment phase so migrations can be executed exactly once per deployment before ECS traffic is shifted.
