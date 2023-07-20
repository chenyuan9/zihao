---
title: "论文复现：soft-DTW：a Differentiable Loss Function for Time-Series"
author: "magisk"
date: "2023-07-20"
output: md_document
---

[soft-DTW：a Differentiable Loss Function for Time-Series](https://arxiv.org/pdf/1703.01541v2.pdf)原文下载

## 翻译

### 摘要：

我们在本文提出一种基于著名的动态时间规整(DTW)差异的可微学习损失函数，用于比较时间序列数据之间的差异。与欧氏距离不同，DTW可以比较具有不同长度的时间序列，并且对于时间维度上的平移或拉伸具有鲁棒性。为了计算DTW,一种常规方法是使用动态规划解决两个时间序列之间的最小成本校准。我们的工作利用了DTW的一种平滑形式，称为soft-DTW，它计算所有校准成本的soft最小值。我们在这篇论文中展示了soft-DTW是一个可微的损失函数，而且它的值和梯度都可以以二次时间/空间复杂度计算（而DTW具有二次时间复杂度但线性空间复杂度）。我们展示了这种正则化特别适用于在DTW几何空间下对时间序列进行平均化和聚类的任务，在这个任务中，我们的方法明显优于现有的基准方法。接下来，我们建议通过以soft-DTW的方式最小化输出时间序列机器与地面真实标签之间的拟合来调整其参数。

### 1.介绍
