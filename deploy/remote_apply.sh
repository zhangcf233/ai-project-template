#!/usr/bin/env bash
set -euo pipefail

ENV_NAME="${1:-}"
APP_DIR="${2:-/opt/ai-project-template}"
IMAGE_REPO="${3:-}"
IMAGE_TAG="${4:-}"
APP_PORT="${5:-}"
GHCR_USER="${6:-}"
GHCR_TOKEN="${7:-}"

if [[ -z "$ENV_NAME" || -z "$IMAGE_REPO" || -z "$IMAGE_TAG" ]]; then
  echo "Usage: deploy/remote_apply.sh <env_name> <app_dir> <image_repo> <image_tag> [app_port] [ghcr_user] [ghcr_token]"
  exit 1
fi

case "$ENV_NAME" in
  staging)
    ENV_FILE="$APP_DIR/.env.staging"
    COMPOSE_FILE="$APP_DIR/docker-compose.staging.yml"
    PORT_KEY="STAGING_PORT"
    DEFAULT_PORT="8080"
    ;;
  production)
    ENV_FILE="$APP_DIR/.env.production"
    COMPOSE_FILE="$APP_DIR/docker-compose.prod.yml"
    PORT_KEY="PROD_PORT"
    DEFAULT_PORT="80"
    ;;
  *)
    echo "Unknown env_name: $ENV_NAME"
    exit 1
    ;;
esac

PORT_VALUE="${APP_PORT:-$DEFAULT_PORT}"

mkdir -p "$APP_DIR"
cat > "$ENV_FILE" <<EOT
IMAGE_REPO=$IMAGE_REPO
IMAGE_TAG=$IMAGE_TAG
${PORT_KEY}=$PORT_VALUE
EOT

if [[ -n "$GHCR_USER" && -n "$GHCR_TOKEN" ]]; then
  echo "$GHCR_TOKEN" | docker login ghcr.io -u "$GHCR_USER" --password-stdin
fi

bash "$APP_DIR/deploy/deploy.sh" "$ENV_NAME" "$ENV_FILE" "$COMPOSE_FILE"
