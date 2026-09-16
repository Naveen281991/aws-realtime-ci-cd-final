# Dockerfile

FROM oven/bun:1 AS frontend-build

WORKDIR /app

COPY package.json bun.lock ./
COPY frontend/package.json ./frontend/

WORKDIR /app/frontend

RUN bun install

COPY frontend/ ./

ARG VITE_API_URL=
ENV VITE_API_URL=${VITE_API_URL}

RUN bun run build


FROM python:3.14

ENV PYTHONUNBUFFERED=1
ENV UV_COMPILE_BYTECODE=1
ENV UV_LINK_MODE=copy
ENV PATH="/app/.venv/bin:$PATH"

COPY --from=ghcr.io/astral-sh/uv:0.9.26 /uv /uvx /bin/

WORKDIR /app

RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    uv sync --frozen --no-install-workspace --package app

COPY backend/scripts /app/backend/scripts
COPY backend/pyproject.toml backend/alembic.ini /app/backend/
COPY backend/app /app/backend/app

COPY --from=frontend-build /app/frontend/dist /app/frontend

RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    uv sync --frozen --package app

WORKDIR /app/backend

CMD ["fastapi", "run", "--workers", "4"]