# AGENTS.md

# 项目目标

本仓库是一个 AI-first 的 DevOps 基础设施模板。

目标是建立一套：

* 可复现
* 可回滚
* 可自动化
* 可审计
* 适合 AI Agent 协作

的软件部署流程。

本仓库当前不关注业务功能开发，而是优先完成：

* GitHub Actions CI/CD
* Docker Compose 部署
* GitHub Container Registry（GHCR）
* staging / production 双环境
* 自动部署
* 人工审批
* rollback 回滚能力
* AI 辅助运维

未来本仓库会作为其他 AI 项目的基础模板。

---

# 当前架构

## 环境划分

### staging

测试环境：

* 用于 AI 自动部署
* 用于功能验证
* 允许频繁更新
* 允许 AI 自动操作

### production

正式环境：

* 用于正式用户访问
* 所有 deploy 必须人工审批
* 必须保证可回滚
* 变更应尽量最小化

---

# 分支规则

## develop

对应 staging 环境：

* push 后自动部署 staging
* 用于 AI 开发与测试

## main

对应 production 环境：

* deploy 前必须人工 approve
* 仅允许稳定代码进入

---

# 部署流程

标准流程：

feature branch
→ Pull Request
→ GitHub Actions build
→ push image 到 GHCR
→ 自动 deploy staging
→ 人工验证
→ merge main
→ production approval
→ deploy production

---

# 核心原则

## 所有配置必须 Git 化

以下内容必须存放于仓库：

* docker-compose
* nginx 配置
* deploy 脚本
* workflow
* env template
* monitoring 配置

禁止只在服务器手动修改。

---

# 安全规则

## 禁止行为

禁止：

* 直接 SSH production
* 使用 root 登录
* 删除 docker volume
* 执行危险清理命令
* 修改防火墙
* 修改 DNS
* 删除数据库
* 执行 rm -rf 类危险命令
* 未确认情况下执行 destructive operation

---

# Deploy 规则

## 所有 deploy 必须通过 GitHub Actions

禁止：

* 本地手动 deploy
* 本地 build 后 scp 上传
* 服务器手工部署

推荐流程：

GitHub Actions
→ build image
→ push GHCR
→ server pull image
→ docker compose up -d

---

# Docker 规则

## 使用 Docker Compose

当前阶段：

* 不使用 Kubernetes
* 不引入复杂编排系统
* 优先保持简单稳定

## 镜像规则

所有 image：

* 必须 push 到 GHCR
* 必须使用 tag
* 必须支持 rollback

服务器只负责：

* docker compose pull
* docker compose up -d

---

# Workflow 规则

## workflow 必须保持简单

禁止：

* 复杂 inline shell
* 超长 yaml
* 不可维护逻辑

要求：

* deploy 逻辑统一放在 deploy/*.sh
* workflow 只负责 orchestration

---

# Shell Script 规则

deploy/*.sh 必须：

* 可重复执行（idempotent）
* 尽量无副作用
* 输出清晰日志
* 支持失败退出
* 支持 rollback

---

# 环境变量规则

## Secrets 管理

敏感信息必须来自：

* GitHub Secrets
* Environment Secrets

环境变量配置要求：

* 禁止在 workflow 或 deploy 过程中直接使用整份 `.env` 文件注入。
* 后续统一使用 GitHub Environment 级别 Secrets 进行配置（如 staging / production 分环境管理）。
* 每个 Secret 只允许承载一个字段（one secret per key），禁止将多个配置项拼接到同一个 Secret。
* 应用读取环境变量时按字段逐一注入，确保最小权限与可审计性。

禁止：

* 明文密码进入仓库
* workflow 写死 token
* commit 私钥

---

# Production 规则

production deploy：

* 必须人工 approve
* 必须保留 rollback 能力
* 必须优先稳定性

禁止 AI：

* 自动 deploy production
* 自动修改 production 配置
* 自动执行高风险操作

---

# 回滚规则

系统必须支持：

* 回滚到上一 image tag
* 快速恢复服务
* 保留历史镜像

deploy 不允许破坏 rollback 能力。

---

# 推荐目录结构

.github/workflows/
deploy/
docker/
docker-compose.staging.yml
docker-compose.prod.yml
env/
nginx/
AGENTS.md
README.md

---

# AI Agent 工作规则

AI Agent 在执行任务时：

* 优先保持系统稳定
* 优先保持可回滚
* 优先保持结构清晰
* 优先最小化修改
* 所有 AI 生成内容默认使用中文输出，除非明确要求英文或技术字段必须英文

修改前应：

* 理解当前结构
* 避免大规模重构
* 避免无必要新增依赖

---

# 提交规范

commit message 应清晰描述：

* 修改内容
* 修改目的
* deploy 影响

示例：

fix: 修复 staging deploy workflow
feat: 增加 production rollback script
chore: 调整 docker compose 结构

---

# 当前阶段目标

当前优先级：

1. 完成 GitHub Actions CI/CD
2. 完成 staging 自动部署
3. 完成 production 审批部署
4. 完成 rollback
5. 完成 monitoring
6. 完成 AI-assisted workflow

暂不考虑：

* Kubernetes
* 微服务
* Terraform
* 高复杂度云原生架构

---

# 长期目标

未来目标：

建立一套适用于 AI Agent 协作的软件工程基础设施。

最终实现：

* AI 开发
* AI deploy
* AI rollback
* AI issue fixing
* AI observability
* Human approval
* GitOps workflow

形成完整 AI DevOps 闭环。


---

# 基础设施极简模型

- 仅允许 `SERVERS` + `ROOT_SSH_KEY`
- `SERVERS` 仅用于 bootstrap 阶段
- `ROOT_SSH_KEY` 仅用于 bootstrap 阶段
- deploy 阶段禁止使用 root key
- environment 必须严格隔离
- bootstrap 必须 workflow_dispatch 手动触发

---

# AI DevOps 安全规则（新增）

## Bootstrap

- 属于高权限操作。
- 必须人工触发（`workflow_dispatch`）。
- 禁止自动执行 bootstrap。

## Deploy

- 仅允许 `deploy` 用户执行。
- 允许自动化 CI/CD。
- 禁止 root 参与日常 deploy。

## Environment

- `staging` / `production` 必须强隔离。
- 禁止跨环境 deploy 与跨环境读取 secrets。

## Secrets 极简规则

仅允许以下字段作为环境级核心密钥：

- `SERVERS`
- `ROOT_SSH_KEY`
- `DEPLOY_SSH_KEY`

## Language

以下默认使用中文：

- PR 描述
- README 文档
- 注释
- workflow 说明
