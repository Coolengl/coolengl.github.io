---
title: 测试：大模型 LoRA 微调笔记
date: 2026-11-09 09:30:00
categories:
  - 大模型
tags:
  - 大模型
  - LoRA
  - 微调
description: 整理 LoRA 的低秩适配思路、关键参数与简单示例。
---

> 这是一篇用于测试大模型分类与排版的示例文章。

LoRA（Low-Rank Adaptation）冻结原始权重，只训练一对低秩矩阵，从而大幅降低微调成本。

## 核心思想

对于原始权重 $W \in \mathbb{R}^{d \times k}$，LoRA 将更新量分解为两个小矩阵的乘积：

$$
W' = W + \frac{\alpha}{r} B A
$$

其中 $A \in \mathbb{R}^{r \times k}$、$B \in \mathbb{R}^{d \times r}$，秩 $r \ll \min(d,k)$。

## 关键参数

- **rank（r）**：秩越大，表达能力越强，显存和参数量也越大
- **alpha**：缩放系数，通常与 rank 联动设置
- **target_modules**：选择对哪些线性层做适配，常见是 `q_proj`、`v_proj`

## 一个最小示例

```python
from peft import LoraConfig, get_peft_model

config = LoraConfig(
    r=8,
    lora_alpha=16,
    target_modules=["q_proj", "v_proj"],
    lora_dropout=0.05,
)
model = get_peft_model(model, config)
model.print_trainable_parameters()
```

## 注意事项

训练完成后可以把 LoRA 权重合并回基座模型，便于部署；也可以保留适配器，按任务动态加载。
