#!/usr/bin/env bash
# One-time local setup: generates .env with random secrets.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

ENV_FILE=".env"

if [[ -f "$ENV_FILE" ]]; then
  echo "$ENV_FILE already exists, leaving it untouched."
  exit 0
fi

if ! command -v openssl >/dev/null 2>&1; then
  echo "openssl is required to generate secrets but was not found." >&2
  exit 1
fi

POSTGRES_PASSWORD=$(openssl rand -hex 24)
JWT_SECRET=$(openssl rand -hex 32)

cat > "$ENV_FILE" <<EOF
POSTGRES_PASSWORD=$POSTGRES_PASSWORD
JWT_SECRET=$JWT_SECRET
EOF

chmod 600 "$ENV_FILE"

echo "Wrote $ENV_FILE with a freshly generated POSTGRES_PASSWORD and JWT_SECRET."
echo "Next: docker compose up --build"
