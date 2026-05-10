# Secrets Parameters

本文档说明 GitHub Environments（`staging` / `production`）的最小化必需配置。

## 最小化 Secrets（每个环境都要有）

- `SERVERS`：逗号分隔服务器列表（示例：`10.0.0.1,10.0.0.2`）
- `ROOT_SSH_KEY`：仅 Bootstrap 使用的 root 私钥
- `DEPLOY_SSH_KEY`：Deploy 用户私钥（Bootstrap 会动态导出公钥写入 authorized_keys）

> 两个环境必须分别配置，不允许跨环境共享引用。

## Bootstrap Workflow

目标：`.github/workflows/bootstrap-server.yml`

- 仅 `workflow_dispatch` 手动触发
- 可选择 `staging` / `production`
- 根据所选 environment 自动读取对应 secrets
- 自动解析 `SERVERS` 并循环初始化全部服务器

## Deploy Workflows

- staging：`.github/workflows/deploy.yml`（`push develop` 自动触发）
- production：`.github/workflows/production-deploy.yml`（`push main`，依赖 environment approval）
