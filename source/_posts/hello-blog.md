---
title: 你好，世界
date: 2026-11-08 12:00:00
tags:
  - 博客
categories:
  - 随笔
description: 博客的第一篇文章 —— 从这里开始记录。
---

欢迎来到我的博客！这是第一篇文章，用来验证站点、主题和部署都工作正常。

## 怎么发新文章

在博客目录下执行：

```bash
npx hexo new "文章标题"
```

Hexo 会在 `source/_posts/` 下生成一个 Markdown 文件，用任意编辑器写好内容后保存即可。文章头部（front-matter）可以设置标题、日期、标签和分类：

```markdown
---
title: 文章标题
date: 2026-11-08 12:00:00
tags:
  - 标签一
categories:
  - 分类一
---
```

## 本地预览

```bash
npx hexo server
```

然后打开 <http://localhost:4000> 查看效果。

## 发布

把改动推送到 GitHub：

```bash
git add .
git commit -m "新文章：你好，世界"
git push
```

GitHub Actions 会自动构建并发布到 GitHub Pages，几分钟后线上就能看到。

> 写作愉快！✍️
