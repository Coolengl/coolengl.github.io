---
title: 测试：分类模型评估指标
date: 2026-11-08 09:00:00
categories:
  - 机器学习
tags:
  - 机器学习
  - 评估指标
  - 分类
description: 梳理准确率、精确率、召回率、F1 与 AUC 的适用场景。
---

> 这是一篇用于测试机器学习分类与排版的示例文章。

分类任务不能只看准确率，尤其在类别不平衡时。

## 混淆矩阵

二分类的混淆矩阵包含四个量：

- TP：预测为正，实际为正
- FP：预测为正，实际为负
- TN：预测为负，实际为负
- FN：预测为负，实际为正

## 常用指标

$$
\mathrm{Precision} = \frac{TP}{TP+FP}, \qquad
\mathrm{Recall} = \frac{TP}{TP+FN}
$$

$$
F_1 = 2 \cdot \frac{\mathrm{Precision}\cdot\mathrm{Recall}}{\mathrm{Precision}+\mathrm{Recall}}
$$

- **Accuracy**：类别均衡时直观，但容易被多数类掩盖
- **Precision**：更关注「预测为正的样本中有多少是真的」
- **Recall**：更关注「真正的正样本被找回了多少」
- **F1**：精确率与召回率的调和平均
- **ROC-AUC**：对排序能力敏感，但在极端不平衡时可能偏乐观
- **PR-AUC**：正样本稀疏时往往更有参考价值

## 使用建议

先明确业务更怕 FP 还是 FN，再选择主指标；同时报告混淆矩阵和至少两个互补指标，避免单指标误导。

```python
from sklearn.metrics import classification_report

print(classification_report(y_true, y_pred, digits=4))
```
