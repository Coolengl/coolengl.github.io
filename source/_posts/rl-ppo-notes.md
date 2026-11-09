---
title: 测试：PPO 算法核心思路
date: 2026-11-09 09:00:00
categories:
  - 强化学习
tags:
  - 强化学习
  - PPO
  - 策略梯度
description: 用直觉解释 PPO 的裁剪目标、优势估计与训练流程。
---

> 这是一篇用于测试强化学习分类与排版的示例文章。

PPO（Proximal Policy Optimization）是强化学习中最常用的策略梯度算法之一。它的目标是在更新策略时，不要一次走得太远。

## 裁剪目标

PPO 使用重要性采样比率 $r_t(\theta)$，并对其进行裁剪：

$$
L^{\mathrm{CLIP}}(\theta) =
\mathbb{E}_t\left[
\min\left(
r_t(\theta)\hat{A}_t,\
\mathrm{clip}(r_t(\theta), 1-\epsilon, 1+\epsilon)\hat{A}_t
\right)
\right]
$$

其中 $\hat{A}_t$ 是优势函数估计，$\epsilon$ 通常取 0.1 或 0.2。

## 优势估计

实践中常用 GAE（Generalized Advantage Estimation）在偏差与方差之间折中，配合 actor-critic 结构：

- actor 负责策略
- critic 负责价值估计

## 训练流程

1. 用当前策略采样一批轨迹
2. 计算回报与优势
3. 对策略和价值网络做多轮小批量更新
4. 监控 KL 散度，必要时提前停止

## 小结

PPO 的工程性很强：实现简单、样本效率不错、调参空间可控，因此在机器人控制和大模型 RLHF 中都被广泛使用。
