#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TF_DIR="${ROOT_DIR}/infrastructure/terraform"

command -v terraform >/dev/null || {
  echo "ERROR: terraform is required for pre-deployment validation."
  exit 1
}

echo "== Terraform format check =="
terraform -chdir="${TF_DIR}" fmt -check -recursive

echo "== Terraform initialization (validation only) =="
terraform -chdir="${TF_DIR}" init -backend=false -input=false

echo "== Terraform validation =="
terraform -chdir="${TF_DIR}" validate

echo "== FastAPI Python syntax check =="
python -m compileall -q "${ROOT_DIR}/backend/app"

echo "== Buildspec YAML check =="
python - "${ROOT_DIR}/buildspec.yml" <<'PY'
from pathlib import Path
import sys
import yaml

path = Path(sys.argv[1])
with path.open(encoding="utf-8") as file:
    yaml.safe_load(file)
print(f"Valid YAML: {path}")
PY

echo "== Required deployment contract checks =="
grep -q 'containerPort = 8000' "${TF_DIR}/ecs.tf"
grep -q 'container_port   = 8000' "${TF_DIR}/alb.tf"
grep -q '/api/v1/utils/health-check/' "${TF_DIR}/alb.tf"
grep -q 'alembic upgrade head' "${ROOT_DIR}/buildspec.yml"

echo "Pre-deployment validation passed."
