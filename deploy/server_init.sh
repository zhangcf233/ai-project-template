#!/usr/bin/env bash
set -euo pipefail

APP_DIR="${1:-/opt/ai-project-template}"
APP_USER="${2:-deploy}"
SSH_PUBLIC_KEY="${3:-}"

if [[ "$(id -u)" -eq 0 ]]; then
  echo "请使用 sudo 执行本脚本，不要直接以 root 登录执行。"
fi

if ! id "$APP_USER" >/dev/null 2>&1; then
  sudo useradd -m -s /bin/bash "$APP_USER"
fi

sudo usermod -aG docker "$APP_USER" || true

if [[ -n "$SSH_PUBLIC_KEY" ]]; then
  sudo -u "$APP_USER" mkdir -p "/home/$APP_USER/.ssh"
  sudo -u "$APP_USER" touch "/home/$APP_USER/.ssh/authorized_keys"
  if ! sudo -u "$APP_USER" grep -qxF "$SSH_PUBLIC_KEY" "/home/$APP_USER/.ssh/authorized_keys"; then
    echo "$SSH_PUBLIC_KEY" | sudo -u "$APP_USER" tee -a "/home/$APP_USER/.ssh/authorized_keys" >/dev/null
  fi
  sudo chmod 700 "/home/$APP_USER/.ssh"
  sudo chmod 600 "/home/$APP_USER/.ssh/authorized_keys"
fi

if ! command -v docker >/dev/null 2>&1; then
  curl -fsSL https://get.docker.com | sudo sh
fi

if ! docker compose version >/dev/null 2>&1; then
  sudo apt-get update
  sudo apt-get install -y docker-compose-plugin
fi

sudo mkdir -p "$APP_DIR" "$APP_DIR/.deploy-state/staging" "$APP_DIR/.deploy-state/production"
sudo chown -R "$APP_USER":"$APP_USER" "$APP_DIR"

echo "server init done: app_dir=$APP_DIR app_user=$APP_USER"
