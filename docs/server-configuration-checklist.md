# Server Configuration Checklist

本文用于确认把当前仓库部署到 **staging / production 两台服务器** 前，还需要补齐的配置项。

> 结论先行：当前仓库的 workflow 里直接执行 `deploy/deploy.sh`，如果继续使用 `ubuntu-latest`，部署会发生在 GitHub 托管 Runner，而不是你的服务器。要真正部署到服务器，需要将 deploy job 跑在目标服务器（通常是 self-hosted runner）。

## 1. GitHub 与分支保护配置

- [ ] 创建并长期使用 `develop`（staging）与 `main`（production）分支。
- [ ] 为 `main` 启用分支保护（至少要求 PR 合并，禁止直接 push）。
- [ ] 在 GitHub `Settings -> Environments -> production` 配置 **Required reviewers**，确保 production 人工审批。

## 2. Secrets 与环境变量（全部走 GitHub Secrets）

按你的规则，敏感信息必须来自 GitHub Secrets。**不建议再使用整份 `.env` 文件作为单个 Secret**，应改为 Environment 级别、单字段 Secret：

### Environment 级 Secrets（推荐）

- [ ] 在 `staging` Environment 中逐个配置：`STAGING_PORT`、`IMAGE_REPO`（可选）以及后续业务字段（如 `DB_URL`）。
- [ ] 在 `production` Environment 中逐个配置：`PROD_PORT`、`IMAGE_REPO`（可选）以及后续业务字段（如 `DB_URL`）。
- [ ] 每个 Secret 仅对应一个字段，禁止把多行 `.env` 内容塞到一个 Secret。

建议字段至少包括：

#### staging

```env
STAGING_PORT=8080
# 如果未来有应用变量，继续追加
# APP_ENV=staging
# DB_URL=...
```

#### production

```env
PROD_PORT=80
# 如果未来有应用变量，继续追加
# APP_ENV=production
# DB_URL=...
```

> `IMAGE_TAG` 建议继续由 workflow 在运行时注入（如 `${{ github.sha }}`），`IMAGE_REPO` 可固定在 workflow 或作为单字段 Secret 管理。

## 3. 服务器基础依赖（两台都要）

### 3.1 账号与权限

- [ ] 禁止 root 直登，创建最小权限运维账号（如 `deployer`）。
- [ ] 该账号可执行 Docker（加入 `docker` 组）。

### 3.2 必备软件

- [ ] Docker Engine（建议 24+）。
- [ ] Docker Compose Plugin（`docker compose` 命令可用）。
- [ ] Git（Runner 拉取仓库时需要）。

### 3.3 网络与端口

- [ ] staging 开放对外访问端口（默认 `8080`，可按需调整）。
- [ ] production 开放 `80/443`（当前模板只用到 `80`）。
- [ ] 仅开放必要端口，不在部署脚本里做防火墙变更。

## 4. 部署执行方式（关键项）

当前 workflow:

- `staging-deploy.yml` 使用 `runs-on: ubuntu-latest`
- `production-deploy.yml` 使用 `runs-on: ubuntu-latest`

这意味着部署不会在你的服务器执行。要落到服务器，推荐：

- [ ] staging 服务器安装并注册 GitHub self-hosted runner（如 label: `self-hosted,staging`）。
- [ ] production 服务器安装并注册 GitHub self-hosted runner（如 label: `self-hosted,production`）。
- [ ] 让 staging workflow 的 deploy job 在 staging runner 执行。
- [ ] 让 production workflow 的 deploy job 在 production runner 执行（并保留 environment approval）。

> 你要求“禁止修改 production workflow”，因此本次仅给出配置清单，不改 production workflow 文件。

## 5. GHCR 权限与镜像策略

- [ ] 仓库 Actions 具备 `packages: write`（当前 workflow 已声明）。
- [ ] 仓库对 GHCR 包具有读取权限（部署节点可拉取镜像）。
- [ ] 镜像保留策略：至少保留最近 N 个 tag（满足 rollback）。

## 6. 回滚能力检查

当前回滚依赖 `.deploy-state/<env>/previous_tag`：

- [ ] 确认 Runner 工作目录可持久化 `.deploy-state`（否则无法回滚到上一版本）。
- [ ] 约定回滚操作入口：`deploy/rollback.sh <env> <env_file> <compose_file>`。
- [ ] 将“回滚到上一 tag”的操作写入运维手册并演练。

## 7. 你现在还缺什么（按优先级）

1. **部署执行位置**：确认并落地 self-hosted runner（最关键）。
2. **production 审批人**：在 GitHub Environment 中配置 Required reviewers。
3. **两套 ENV Secrets**：补齐并校验变量完整性。
4. **服务器 Docker/Compose 基线**：安装、权限、端口检查。
5. **回滚演练**：至少做一次 staging 回滚演练，确认 previous tag 可用。

## 8. 最小上线前核对命令（在服务器执行）

```bash
docker --version
docker compose version
id
getent group docker
```

如果 Runner 已在服务器上，可额外检查：

```bash
./run.sh --version || true
```

---

如果你愿意，我下一步可以给你一份“**只改 staging workflow，不动 production workflow**”的最小改造方案（含 runner label、部署目录与持久化 `.deploy-state` 的建议）。
