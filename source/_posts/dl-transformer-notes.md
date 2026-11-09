---
title: Transformer 架构速览
date: 2026-11-09 08:30:00
categories:
  - 深度学习
tags:
  - 深度学习
  - Transformer
  - 注意力机制
description: 快速回顾 Transformer 的自注意力、多头机制与整体结构。
---

> 这是一篇用于测试深度学习分类与排版的示例文章。

Transformer 用注意力机制替代循环结构，成为目前大多数大模型的基础架构。

## 自注意力

给定查询 $Q$、键 $K$、值 $V$，缩放点积注意力为：

$$
\mathrm{Attention}(Q,K,V)
= \mathrm{softmax}\left(\frac{QK^\top}{\sqrt{d_k}}\right)V
$$

除以 $\sqrt{d_k}$ 是为了避免点积过大导致 softmax 饱和。

## 多头注意力

把注意力拆成多个头并行计算，让模型在不同子空间关注不同关系，再拼接后做线性变换。

## 整体结构

一个 Transformer block 通常包含：

- 多头自注意力
- 残差连接与 LayerNorm
- 前馈网络（FFN）
- 再次残差连接与 LayerNorm

## 位置信息

自注意力本身不感知顺序，因此需要位置编码。常见方案包括正弦位置编码、可学习位置嵌入，以及后来的 RoPE 等相对位置方法。

## 小结

Transformer 的关键不只是「注意力」，而是注意力、残差、归一化和并行训练共同带来的可扩展性。
