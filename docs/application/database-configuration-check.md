# Database Configuration Check

Before applying RDS changes, verify the FastAPI settings map cleanly to these variables:

- `POSTGRES_SERVER`
- `POSTGRES_PORT`
- `POSTGRES_DB`
- `POSTGRES_USER`
- `POSTGRES_PASSWORD`
- `DATABASE_URL`

If the application constructs its database URL from the component variables, the ECS runtime can use the RDS values directly and the secret-backed `DATABASE_URL` can remain as the canonical compatibility path.

Do not commit a production database password.
