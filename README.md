# 我的博客

基于 **Hexo 7 + Butterfly 主题** 的静态博客，通过 **GitHub Actions** 自动部署到 **GitHub Pages**。

## 本地常用命令

```bash
npm install          # 安装依赖（已配置 npmmirror 镜像）
npx hexo server      # 本地预览，打开 http://localhost:4000
npx hexo new "标题"   # 新建文章，文件在 source/_posts/
npx hexo generate    # 手动生成静态站点到 public/
```

## 首次上线清单（重要）

### 1. 改成你自己的信息

编辑 `_config.yml`：

```yaml
title: 我的博客                       # 站点标题
author: 博主                         # 你的名字
url: https://YOUR_USERNAME.github.io # 改成你的 GitHub 用户名
```

可选：`_config.butterfly.yml` 里修改头像（`avatar.img`）、社交链接（`social`）、公告等。
把头像图片放到 `source/img/avatar.jpg`，再设 `avatar.img: /img/avatar.jpg`。

### 2. 在 GitHub 创建仓库

推荐仓库名：**`<你的用户名>.github.io`**（例如用户名为 `abc`，仓库名就是 `abc.github.io`）。
这样博客地址就是 `https://abc.github.io`，不用处理子路径。

> 如果你想用普通仓库名（比如 `blog`），需要把 `_config.yml` 的 `url` 改成
> `https://<用户名>.github.io/blog`，否则样式和链接会 404。

### 3. 推送代码

在 GitHub 新建**空仓库**（不要勾选 README），然后在本目录执行：

```bash
git remote add origin https://github.com/<用户名>/<仓库名>.git
git branch -M main
git push -u origin main
```

> 本机 git 已配置 github.com 走代理 `127.0.0.1:7890`（对应你的系统代理）。
> 如果以后代理端口变了，更新：
> `git config --global http.https://github.com.proxy http://127.0.0.1:<新端口>`

### 4. 打开 GitHub Pages

仓库页面 → **Settings** → **Pages** → **Build and deployment**：

- **Source** 选择 **GitHub Actions**（不要选 Deploy from a branch）

然后到 **Actions** 标签页，最新的 `Deploy Hexo to GitHub Pages` 运行完成后，
访问 `https://<用户名>.github.io` 即可。

### 5. 以后发布文章

```bash
npx hexo new "文章标题"
# 编辑 source/_posts/文章标题.md
git add .
git commit -m "新文章：文章标题"
git push
```

推送后 GitHub Actions 会自动构建并发布，无需本地 generate。

## 目录结构

```
.
├── _config.yml              # Hexo 站点配置（标题、url、作者等）
├── _config.butterfly.yml    # Butterfly 主题配置（菜单、头像、公告等）
├── source/
│   ├── _posts/              # 文章（Markdown）
│   ├── about/               # 关于页
│   ├── tags/                # 标签页
│   ├── categories/          # 分类页
│   └── img/                 # 图片资源
├── themes/                  # 本地主题（本项目主题由 npm 安装）
├── .github/workflows/pages.yml  # 自动部署工作流
└── package.json
```

## 说明

- 依赖从 `registry.npmmirror.com` 安装（`.npmrc` 已配置）；GitHub Actions 中自动切换为官方源。
- 文内图片可放在 `source/img/`，Markdown 中用 `/img/xxx.png` 引用。
- 主题文档：<https://butterfly.js.org/>
