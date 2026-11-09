---
title: VLN 入门 —— R2R 任务与评测指标
date: 2026-11-09 10:00:00
categories:
  - VLN
tags:
  - VLN
  - R2R
  - 视觉语言导航
description: 以 R2R 为例，梳理视觉语言导航的任务设定与常用评测指标。
---

> 这是一篇 VLN 入门笔记，内容会持续补充。

## 任务设定

视觉语言导航（Vision-and-Language Navigation，VLN）要求智能体在未见过的三维环境中，根据自然语言指令从起点移动到目标位置。

R2R（Room-to-Room）是目前最常用的基准之一：

- 环境基于 Matterport3D 的室内场景
- 动作空间是预定义的导航图节点
- 每条指令对应一条参考路径

## 常用指标

- **NE（Navigation Error）**：终点与目标点的平均距离，越低越好
- **SR（Success Rate）**：终点落在成功阈值内的比例
- **OSR（Oracle Success Rate）**：路径曾经过目标附近的比例
- **SPL（Success weighted by Path Length）**：在成功率基础上惩罚绕路

$$
\mathrm{SPL} = \frac{1}{N}\sum_{i=1}^{N} S_i \cdot \frac{\ell_i}{\max(p_i, \ell_i)}
$$

其中 $S_i$ 表示第 $i$ 条轨迹是否成功，$\ell_i$ 是最短路径长度，$p_i$ 是智能体实际走过的路径长度。

## 经典基线

早期的 seq2seq 模型把全景视觉特征和指令编码后，逐步预测下一个动作；后续工作引入了跨模态注意力、图结构建模和预训练。

对刚入门来说，一条比较稳的路线是：

1. 先复现 R2R 上的 seq2seq baseline
2. 再加入视觉-语言对齐模块
3. 最后尝试预训练与数据增强
