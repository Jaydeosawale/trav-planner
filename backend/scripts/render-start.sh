#!/usr/bin/env bash
set -euo pipefail
alembic upgrade head
python -m seeds.bootstrap_catalogue
python -m seeds.bootstrap_geography
exec uvicorn app.main:app --host 0.0.0.0 --port "${PORT:-10000}" --proxy-headers
