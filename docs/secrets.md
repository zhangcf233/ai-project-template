# Secrets Parameters

本文档说明当前仓库在 GitHub Environments 中需要配置的参数（`staging` / `production`）。

## 配置原则

- 所有运行参数都来自 GitHub Environment Variables / Secrets。
- 参数必须按环境隔离保存，禁止跨环境直接复用引用。
- `SERVERS` 使用 **Environment Variable**（便于审计服务器 IP 列表）。
- SSH 密钥使用 **Environment Secret**。

## bootstrap-server.yml（高权限，手动触发）

目标 workflow：`.github/workflows/bootstrap-server.yml`

每个 Environment（staging / production）都需要配置：

- Variable: `SERVERS`
  - 说明：逗号分隔服务器 IP 列表
  - 示例：`10.0.0.1,10.0.0.2`
- Secret: `ROOT_SSH_KEY`
  - 说明：仅 bootstrap 阶段使用的 root SSH 私钥
- Secret: `DEPLOY_SSH_PUBLIC_KEY`
  - 说明：deploy 用户公钥，bootstrap 时写入 `/home/deploy/.ssh/authorized_keys`

说明：

- 该 workflow 仅用于服务器初始化，不参与日常 deploy。
- 即使 staging / production 使用相同 key，也必须分别配置在各自 environment 中。

## production-deploy.yml（低权限 + 人工审批）

目标 workflow：`.github/workflows/production-deploy.yml`

- 保持 `environment: production` 审批机制。
- 生产参数继续按该 workflow 当前定义的 secrets 配置。

## 当前阶段说明

- 当前阶段仅保留初始化服务器工作流（`bootstrap-server`）。
- staging 自动部署工作流已暂时下线。
