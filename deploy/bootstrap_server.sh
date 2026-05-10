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

ROOT_KEY_FILE="$(mktemp)"
DEPLOY_KEY_FILE="$(mktemp)"
trap 'rm -f "$ROOT_KEY_FILE" "$DEPLOY_KEY_FILE"' EXIT

printf '%s\n' "$ROOT_SSH_KEY" > "$ROOT_KEY_FILE"
printf '%s\n' "$DEPLOY_SSH_KEY" > "$DEPLOY_KEY_FILE"
chmod 600 "$ROOT_KEY_FILE" "$DEPLOY_KEY_FILE"

DEPLOY_PUB_KEY="$(ssh-keygen -y -f "$DEPLOY_KEY_FILE")"
APP_DIR="/opt/apps/${REPO_NAME}"

IFS=',' read -r -a SERVER_ARRAY <<< "$SERVERS"
for SERVER in "${SERVER_ARRAY[@]}"; do
  SERVER="$(echo "$SERVER" | xargs)"
  [[ -z "$SERVER" ]] && continue
  echo "[bootstrap][$ENV_NAME] init server: $SERVER"

  ssh -o StrictHostKeyChecking=accept-new -i "$ROOT_KEY_FILE" root@"$SERVER" \
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
sort -u /home/deploy/.ssh/authorized_keys -o /home/deploy/.ssh/authorized_keys
chown -R deploy:deploy /home/deploy/.ssh
chmod 700 /home/deploy/.ssh
chmod 600 /home/deploy/.ssh/authorized_keys

if id -nG deploy | grep -qw sudo; then
  deluser deploy sudo || true
fi

if ! command -v docker >/dev/null 2>&1; then
  curl -fsSL https://get.docker.com | sh
fi
if ! docker compose version >/dev/null 2>&1; then
  apt-get update
  apt-get install -y docker-compose-plugin
fi
usermod -aG docker deploy

mkdir -p "$APP_DIR" "$APP_DIR/deploy-state"
chown -R deploy:deploy "$APP_DIR"

su - deploy -c "docker compose version"
echo "bootstrap ok"
REMOTE
done

echo "bootstrap finished: $ENV_NAME"
