# AI Project Template

这是一个以 AI-first DevOps 为目标的基础模板，当前最小示例为 **Nginx 服务**，通过 GitHub Actions 构建并推送到 GHCR，然后按分支自动/审批部署。

## Branch Strategy

- `develop`：staging 环境，push 后自动部署。
- `main`：production 环境，需通过 GitHub Environment 的人工审批后部署。

如需初始化分支：

```bash
git checkout -b develop
git push -u origin develop
git checkout main
git push -u origin main
```

## Deployment Flow

1. push 到 `develop`。
2. GitHub Actions 构建镜像并推送到 `ghcr.io/<org>/ai-project-template:<sha>`。
3. staging workflow 调用 `deploy/deploy.sh` 部署到测试服务器。
4. 合并到 `main` 后触发 production workflow。
5. production 通过 `environment: production` 执行人工审批后部署。

## Secrets

请在 GitHub 仓库中配置：

- `STAGING_ENV_FILE`：完整 `.env` 内容（如 `STAGING_PORT` 等）。
- `PRODUCTION_ENV_FILE`：完整 `.env` 内容（如 `PROD_PORT` 等）。

> 注意：敏感信息必须来自 GitHub Secrets，不要提交到仓库。

## Rollback

- 部署脚本会在 `.deploy-state/<env>/` 中记录 `current_tag` 与 `previous_tag`。
- 回滚时执行 `deploy/rollback.sh`，回到上一镜像 tag。
