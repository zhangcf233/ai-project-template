#!/usr/bin/env bash
set -euo pipefail

ENV_NAME="${1:-}"
ENV_FILE="${2:-}"
COMPOSE_FILE="${3:-}"

if [[ -z "$ENV_NAME" || -z "$ENV_FILE" || -z "$COMPOSE_FILE" ]]; then
  echo "Usage: deploy/deploy.sh <env_name> <env_file> <compose_file>"
  exit 1
fi

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Missing env file: $ENV_FILE"
  exit 1
fi

set -a
source "$ENV_FILE"
set +a

if [[ -z "${IMAGE_REPO:-}" || -z "${IMAGE_TAG:-}" ]]; then
  echo "IMAGE_REPO or IMAGE_TAG is missing in $ENV_FILE"
  exit 1
fi

STATE_DIR=".deploy-state/$ENV_NAME"
mkdir -p "$STATE_DIR"

if [[ -f "$STATE_DIR/current_tag" ]]; then
  cp "$STATE_DIR/current_tag" "$STATE_DIR/previous_tag"
fi

echo "$IMAGE_TAG" > "$STATE_DIR/current_tag"

docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" pull
docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" up -d

echo "[$ENV_NAME] deploy completed. current tag=$IMAGE_TAG"
