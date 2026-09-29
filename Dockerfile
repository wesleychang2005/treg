FROM node:22-bookworm-slim AS frontend
WORKDIR /src
COPY package.json ./
COPY frontend ./frontend
COPY scripts/build-dashboard.sh ./scripts/build-dashboard.sh
COPY src/treg/web ./src/treg/web
RUN bash scripts/build-dashboard.sh

FROM python:3.12-slim-bookworm
LABEL "language"="python"
LABEL "framework"="fastapi"
WORKDIR /src
RUN apt-get update \
 && apt-get install -y --no-install-recommends curl ca-certificates build-essential \
 && rm -rf /var/lib/apt/lists/*
COPY --from=ghcr.io/astral-sh/uv:0.12.3 /uv /usr/local/bin/uv
COPY pyproject.toml uv.lock README.md LICENSE alembic.ini hatch_build.py ./
COPY src ./src
COPY scripts ./scripts
COPY --from=frontend /src/src/treg/web/dashboard ./src/treg/web/dashboard
COPY --from=frontend /src/src/treg/web/vendor ./src/treg/web/vendor
RUN uv sync --locked --no-dev --extra server \
 && apt-get purge -y --auto-remove build-essential \
 && rm -rf /var/lib/apt/lists/* /root/.cache /tmp/*
ENV PATH="/src/.venv/bin:$PATH"
EXPOSE 8080
CMD ["python", "-m", "treg"]
