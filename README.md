# AI Project Template

## 极简基础设施模型

本仓库采用极简、安全配置模型，环境级仅允许以下 3 个 Secrets：

- `SERVERS`：逗号分隔服务器列表，例如 `10.0.0.1,10.0.0.2`
- `ROOT_SSH_KEY`：仅用于 Bootstrap 的 root 私钥
- `DEPLOY_SSH_KEY`：用于 Deploy 用户连接与 Bootstrap 自动导出公钥

> `staging` 与 `production` 必须分别在 GitHub Environments 中独立配置，严禁跨环境复用。

## Bootstrap 说明

- Workflow：`.github/workflows/bootstrap-server.yml`
- 触发方式：`workflow_dispatch`（仅手动触发）
- 环境选择：`staging` / `production`
- 脚本入口：`scripts/bootstrap-server.sh`（内部转发到 `deploy/bootstrap_server.sh`）

Bootstrap 会按 `SERVERS` 自动循环执行，并完成：

- 初始化 `deploy` 用户
- 写入 `/home/deploy/.ssh/authorized_keys`（追加 + 去重，不覆盖）
- 由 `DEPLOY_SSH_KEY` 动态导出公钥（`ssh-keygen -y`）
- 安装 Docker 与 docker compose plugin
- 初始化 `/opt/apps/<repo-name>/deploy-state`
- 验证 `su - deploy -c "docker compose version"`

## Deploy 架构说明

- `develop` 分支：触发 `.github/workflows/deploy.yml` 自动部署到 staging
- `main` 分支：触发 `.github/workflows/production-deploy.yml`，使用 production environment 审批保护

部署镜像统一使用 GHCR：`ghcr.io/<owner>/ai-project-template:<git-sha>`。

## 安全模型说明

- **Bootstrap vs Deploy 强隔离**：
  - Bootstrap 允许 root，仅用于初始化
  - Deploy 仅允许 deploy 用户，禁止 root deploy
- **Environment Isolation**：
  - staging / production 独立 Secrets
  - workflow 通过 `environment:` 读取对应环境密钥
- **回滚能力**：
  - 保留 `deploy-state/current_tag` 与 `deploy-state/previous_tag`
  - 可通过 `deploy/rollback.sh` 执行 tag 回滚

更多参数说明见：`docs/secrets.md`。
