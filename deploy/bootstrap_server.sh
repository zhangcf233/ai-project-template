#!/usr/bin/env bash
set -euo pipefail

SERVERS="${1:-}"
ROOT_SSH_KEY="${2:-}"
DEPLOY_SSH_KEY="${3:-}"
ENV_NAME="${4:-}"
REPO_NAME="${5:-ai-project-template}"

if [[ -z "$SERVERS" || -z "$ROOT_SSH_KEY" || -z "$DEPLOY_SSH_KEY" || -z "$ENV_NAME" ]]; then
  echo "Usage: deploy/bootstrap_server.sh <servers_csv> <root_ssh_key> <deploy_ssh_key> <env_name> [repo_name]"
  exit 1
fi

if [[ "$ENV_NAME" != "staging" && "$ENV_NAME" != "production" ]]; then
  echo "ENV_NAME must be staging or production"
  exit 1
fi

KEY_FILE="$(mktemp)"
trap 'rm -f "$KEY_FILE"' EXIT

printf '%s\n' "$ROOT_SSH_KEY" > "$KEY_FILE"
chmod 600 "$KEY_FILE"

DEPLOY_PUB_KEY="$DEPLOY_SSH_KEY"
APP_DIR="/opt/apps/${REPO_NAME}"

IFS=',' read -r -a SERVER_ARRAY <<< "$SERVERS"
for SERVER in "${SERVER_ARRAY[@]}"; do
  SERVER="$(echo "$SERVER" | xargs)"
  [[ -z "$SERVER" ]] && continue
  echo "[bootstrap][$ENV_NAME] init server: $SERVER"

  ssh -o StrictHostKeyChecking=accept-new -i "$KEY_FILE" root@"$SERVER" \
    "DEPLOY_PUB_KEY='$DEPLOY_PUB_KEY' APP_DIR='$APP_DIR' bash -s" <<'REMOTE'
set -euo pipefail

if ! id deploy >/dev/null 2>&1; then
  useradd -m -s /bin/bash deploy
fi

mkdir -p /home/deploy/.ssh
touch /home/deploy/.ssh/authorized_keys
if ! grep -qxF "$DEPLOY_PUB_KEY" /home/deploy/.ssh/authorized_keys; then
  echo "$DEPLOY_PUB_KEY" >> /home/deploy/.ssh/authorized_keys
fi
chown -R deploy:deploy /home/deploy/.ssh
chmod 700 /home/deploy/.ssh
chmod 600 /home/deploy/.ssh/authorized_keys

if ! command -v docker >/dev/null 2>&1; then
  curl -fsSL https://get.docker.com | sh
fi
if ! docker compose version >/dev/null 2>&1; then
  apt-get update
  apt-get install -y docker-compose-plugin
fi
usermod -aG docker deploy || true

mkdir -p "$APP_DIR" "$APP_DIR/deploy-state"
chown -R deploy:deploy /opt/apps

echo "bootstrap ok"
REMOTE

done

echo "bootstrap finished: $ENV_NAME"
