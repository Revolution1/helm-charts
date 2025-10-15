# 仓库设置指南

本指南说明如何设置用于托管 Helm charts 的 GitHub Pages (gh-pages) 分支并配置分支保护。

## 前置要求

- 具有管理员权限的 GitHub 仓库
- 本地安装 Git
- 了解 GitHub Pages 和分支保护的基础知识

## 创建 gh-pages 分支

`gh-pages` 分支用于 GitHub Pages 托管 Helm chart 仓库索引和打包的 charts。chart-releaser GitHub Action 会自动将 charts 发布到此分支。

### 方法 1: 使用设置脚本（最简单）

提供了一个便捷脚本来自动创建分支:

```bash
# 运行设置脚本
.github/scripts/setup-gh-pages.sh
```

该脚本将:
- 创建一个空的孤儿 gh-pages 分支
- 添加初始 README.md
- 将分支推送到 GitHub
- 让您返回到原始分支

### 方法 2: 使用 Git 命令（手动）

创建一个空的孤儿分支用于 gh-pages:

```bash
# 进入本地仓库目录
cd helm-charts

# 创建一个空的孤儿分支
git checkout --orphan gh-pages

# 从工作树中删除所有文件
git rm -rf .

# 创建初始提交并添加 README
cat > README.md << 'EOF'
# Helm Charts 仓库

此分支包含已发布的 Helm charts 和仓库索引。

当更改合并到主分支时，Charts 会通过 GitHub Actions 自动发布到此处。

## 使用方法

添加此 Helm 仓库:

```bash
helm repo add revolution1 https://revolution1.github.io/helm-charts
helm repo update
```

查看可用的 charts:

```bash
helm search repo revolution1
```

## 自动发布

此分支由 chart-releaser GitHub Action 自动更新。请勿手动提交到此分支。
EOF

# 添加并提交 README
git add README.md
git commit -m "Initialize gh-pages branch"

# 推送分支到 GitHub
git push origin gh-pages

# 切换回主分支
git checkout main
```

### 方法 3: 使用 GitHub Web 界面

1. 在 GitHub 上访问您的仓库
2. 点击分支下拉菜单（默认显示 "main"）
3. 在文本框中输入 `gh-pages`
4. 点击 "Create branch: gh-pages from 'main'"
5. 然后使用 Git 命令执行以下清理步骤

通过 Web 界面创建后，清理分支:

```bash
git fetch origin
git checkout gh-pages
git rm -rf .
git commit -m "Clean gh-pages branch"
git push origin gh-pages
git checkout main
```

## 配置 GitHub Pages

创建 gh-pages 分支后:

1. 在 GitHub 上进入仓库的 **Settings（设置）**
2. 在左侧边栏导航到 **Pages**
3. 在 **Source（源）** 下选择:
   - Branch: `gh-pages`
   - Folder: `/ (root)`
4. 点击 **Save（保存）**
5. GitHub Pages 将发布到: `https://<用户名>.github.io/<仓库名>`

等待几分钟进行初始部署。您会看到一条显示站点 URL 的成功消息。

## 保护 gh-pages 分支

为防止意外修改并确保只有 GitHub Actions 可以更新分支:

### 基础保护

1. 进入仓库 **Settings（设置）** > **Branches（分支）**
2. 点击 **Add branch protection rule（添加分支保护规则）**
3. 输入 `gh-pages` 作为分支名称模式
4. 启用以下设置:
   - ✅ **Require a pull request before merging（合并前需要拉取请求）**
     - 取消选中 "Require approvals"（因为这是自动化的）
   - ✅ **Require status checks to pass before merging（合并前需要通过状态检查）**
   - ✅ **Require branches to be up to date before merging（合并前需要分支保持最新）**
   - ✅ **Do not allow bypassing the above settings（不允许绕过上述设置）**
   - ✅ **Restrict who can push to matching branches（限制谁可以推送到匹配的分支）**
     - 仅允许 GitHub Actions 或特定用户/团队
5. 点击 **Create（创建）** 或 **Save changes（保存更改）**

### 高级保护（推荐）

为了增强安全性:

1. 在同一分支保护规则中，还要启用:
   - ✅ **Require linear history（需要线性历史）** - 防止合并提交
   - ✅ **Include administrators（包括管理员）** - 对管理员也应用规则
   - ✅ **Allow force pushes（允许强制推送）** - 仅针对特定参与者
     - 为 `github-actions[bot]` 添加例外
   - ✅ **Allow deletions（允许删除）** - 禁用以防止分支删除

2. 考虑使用 **Rulesets（规则集）**（GitHub 新功能）:
   - 进入 **Settings（设置）** > **Rules（规则）** > **Rulesets（规则集）**
   - 创建一个针对 `gh-pages` 分支的新规则集
   - 配置强制状态: **Active（活动）**
   - 添加规则:
     - 限制创建
     - 限制更新（仅允许 GitHub Actions）
     - 限制删除
     - 阻止强制推送（为 Actions 添加例外）

### 允许 GitHub Actions 推送

确保您的 GitHub Actions 工作流有权限推送到 gh-pages:

在您的 `.github/workflows/release.yaml` 中，作业应该有:

```yaml
permissions:
  contents: write  # 推送到 gh-pages 所需
```

这已经在现有的发布工作流中配置好了。

## 验证设置

### 检查 GitHub Pages 状态

1. 进入 **Settings（设置）** > **Pages**
2. 验证站点已发布
3. 访问您的 Helm 仓库 URL: `https://revolution1.github.io/helm-charts`

### 测试 Helm 仓库

```bash
# 添加 Helm 仓库
helm repo add revolution1 https://revolution1.github.io/helm-charts

# 更新仓库
helm repo update

# 搜索 charts
helm search repo revolution1

# 查看仓库索引
curl https://revolution1.github.io/helm-charts/index.yaml
```

## 工作流集成

chart-releaser action (`.github/workflows/release.yaml`) 会自动:

1. 检测更改的 charts
2. 打包新的 chart 版本
3. 创建 GitHub releases
4. 使用以下内容更新 gh-pages 分支:
   - 打包的 chart 文件 (`.tgz`)
   - 更新的 `index.yaml` 文件
5. GitHub Pages 提供这些文件

## 故障排除

### GitHub Pages 未发布

- 在 **Settings（设置）** > **Pages** 中检查错误消息
- 验证 gh-pages 分支存在且有内容
- 确保 GitHub Pages 源设置正确
- 推送后等待 1-2 分钟进行部署

### Charts 未显示

- 在 **Actions** 标签中检查发布工作流运行
- 验证 `Chart.yaml` 中的 chart 版本已更新
- 检查 gh-pages 分支中是否存在 `index.yaml`
- 查看工作流日志中的错误

### 权限错误

- 验证 `GITHUB_TOKEN` 具有 `contents: write` 权限
- 检查分支保护规则不会阻止 GitHub Actions
- 确保在仓库设置中允许 Actions

## 维护

### 清理旧版本

gh-pages 分支会随时间累积 chart 版本。要清理:

```bash
git checkout gh-pages
# 删除旧的 chart 版本（保留最近的版本）
# 相应地更新 index.yaml
git add .
git commit -m "Clean up old chart versions"
git push origin gh-pages
git checkout main
```

注意: 清理时要小心，因为用户可能仍在引用旧版本。

## 参考资料

- [Helm Chart Releaser Action](https://github.com/helm/chart-releaser-action)
- [GitHub Pages 文档](https://docs.github.com/zh/pages)
- [分支保护规则](https://docs.github.com/zh/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches)
- [Helm 仓库文档](https://helm.sh/zh/docs/topics/chart_repository/)

## 安全注意事项

- 切勿将敏感数据提交到 gh-pages
- 使用分支保护防止未经授权的更改
- 定期审查 GitHub Actions 工作流权限
- 监控仓库访问日志
- 考虑使用部署环境以获得额外控制
