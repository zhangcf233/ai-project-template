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

## How to find IMAGE_REPO

你问的 `IMAGE_REPO=ghcr.io/your-org/ai-project-template`，其中 `your-org` 需要替换成你实际的 GitHub **用户或组织名**。

本仓库当前 workflow 构建时使用：

- `IMAGE_REPO=ghcr.io/${{ github.repository_owner }}/ai-project-template`

因此你的实际镜像仓库地址就是：

- `ghcr.io/<你的 GitHub owner>/ai-project-template`

可通过以下方式确认：

1. 打开 GitHub 仓库主页，查看 `owner/repo`（例如 `acme/ai-project-template`），则 owner 为 `acme`。
2. 在 GitHub 右上角头像菜单进入 `Your profile` 或组织页，打开 `Packages`，查看是否出现 `ai-project-template` 镜像。
3. 首次 push 后可在包详情页看到完整 pull 地址（即最终 `IMAGE_REPO`）。

## Port Policy

在你说的「staging 和 production 分别在两台服务器」这个前提下，端口通常可以统一为 `80:80`，不需要额外做 `STAGING_PORT/PROD_PORT` 配置。

当前模板已改为 compose 内固定 `80:80`：

- 测试机（staging）监听 80
- 生产机（production）监听 80

只有在以下场景才建议再引入端口变量：

- 同一台服务器同时跑多套环境（端口冲突）
- 前面已有反向代理占用了 80/443
- 需要临时灰度端口验证

## Secrets

请在 GitHub 仓库中配置：

- `STAGING_ENV_FILE`：完整 `.env` 内容（至少包含 `IMAGE_REPO`、`IMAGE_TAG`）。
- `PRODUCTION_ENV_FILE`：完整 `.env` 内容（至少包含 `IMAGE_REPO`、`IMAGE_TAG`）。

推荐示例（写入 GitHub Secrets 的内容，而不是提交仓库）：

```env
IMAGE_REPO=ghcr.io/<你的 GitHub owner>/ai-project-template
IMAGE_TAG=<由 workflow 写入，例如 commit sha>
```

> 注意：敏感信息必须来自 GitHub Secrets，不要提交到仓库。

## Rollback

- 部署脚本会在 `.deploy-state/<env>/` 中记录 `current_tag` 与 `previous_tag`。
- 回滚时执行 `deploy/rollback.sh`，回到上一镜像 tag。
