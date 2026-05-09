#!/usr/bin/env bash
set -euo pipefail

ENV_NAME="${1:-}"
ENV_FILE="${2:-}"
COMPOSE_FILE="${3:-}"

if [[ -z "$ENV_NAME" || -z "$ENV_FILE" || -z "$COMPOSE_FILE" ]]; then
  echo "Usage: deploy/rollback.sh <env_name> <env_file> <compose_file>"
  exit 1
fi

STATE_DIR=".deploy-state/$ENV_NAME"
PREVIOUS_TAG_FILE="$STATE_DIR/previous_tag"

if [[ ! -f "$PREVIOUS_TAG_FILE" ]]; then
  echo "No previous tag found for rollback: $PREVIOUS_TAG_FILE"
  exit 1
fi

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Missing env file: $ENV_FILE"
  exit 1
fi

PREVIOUS_TAG="$(cat "$PREVIOUS_TAG_FILE")"

set -a
source "$ENV_FILE"
set +a

if [[ -z "${IMAGE_REPO:-}" ]]; then
  echo "IMAGE_REPO is missing in $ENV_FILE"
  exit 1
fi

cat > "$ENV_FILE" <<EOT
IMAGE_REPO=$IMAGE_REPO
IMAGE_TAG=$PREVIOUS_TAG
EOT

docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" pull
docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" up -d

echo "$PREVIOUS_TAG" > "$STATE_DIR/current_tag"
echo "[$ENV_NAME] rollback completed. current tag=$PREVIOUS_TAG"
