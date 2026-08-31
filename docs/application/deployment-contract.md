# FastAPI AWS Deployment Contract

## Container

- Container name: `aws-enterprise-cicd-app`
- Application port: `8000`
- Application protocol: HTTP
- Production image source: Amazon ECR
- ECS launch type: Fargate

## Load balancer

The ALB target group must forward HTTP traffic to container port `8000`.

## Health check

The target group health check must use:

`/api/v1/utils/health-check/`

The health-check endpoint must return a successful HTTP response when the application is ready to receive traffic.

## CI/CD image contract

CodeBuild generates:

`imagedefinitions.json`

The image definition must reference the same ECS container name used by the task definition:

`aws-enterprise-cicd-app`

## Scope boundary

This contract intentionally does not define production secrets or database migration execution. Those are handled separately so application connectivity and deployment behavior remain independently verifiable.
