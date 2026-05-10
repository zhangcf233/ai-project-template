# AI Project Template

## 极简基础设施模型

本仓库采用极简 bootstrap 配置模型，仅使用两个 environment secrets：

- `SERVERS`：Environment Variable（逗号分隔服务器列表，如 `"10.0.0.1,10.0.0.2"`）
- `ROOT_SSH_KEY`：Environment Secret，仅用于 bootstrap 的 root SSH 私钥

> 两个环境 `staging` 与 `production` 必须分别配置独立的 `SERVERS` 和 `ROOT_SSH_KEY`，严禁跨环境复用。

## Bootstrap 与 Deploy 边界

- **Bootstrap（高权限）**：仅人工 `workflow_dispatch` 触发，使用 root key 做初始化。
- **Deploy（低权限）**：仅使用 `deploy` 用户执行日常自动部署，不允许 root key 参与。

## Workflows

- `.github/workflows/bootstrap-server.yml`
  - 手动触发
  - 选择 `staging` / `production`
  - 从对应 GitHub Environment 读取 `SERVERS` + `ROOT_SSH_KEY`
  - 执行 `deploy/bootstrap_server.sh` 初始化多台服务器

- `.github/workflows/production-deploy.yml`
  - `main` 触发
  - 依赖 `environment: production` 的人工审批保护

## 安全模型

- root key 仅用于 bootstrap，不参与 deploy。
- deploy 阶段禁止 root SSH。
- 不删除 volume，不做破坏性清理。
- 镜像统一 GHCR。
- 环境变量来自 GitHub Secrets / Environment Secrets，且不使用“完整 env 文本”单密钥模式。


## 参数配置说明

已移除 `env/*.env.example` 示例文件，统一改为文档维护参数清单：`docs/secrets.md`。

- staging environment 内推荐使用无前缀 secret 命名（如 `SERVER_HOST`、`APP_PORT`）。


> 当前阶段：暂时仅保留初始化服务器工作流（bootstrap-server），staging 自动部署工作流已下线。

- `DEPLOY_SSH_PUBLIC_KEY`：Environment Secret，deploy 用户公钥（bootstrap 会写入 authorized_keys）。
