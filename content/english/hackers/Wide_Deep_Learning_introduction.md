---
title: "抖音推荐算法之Wide & Deep Learning"
output: html_document
date: "2025-04-28"
tags:
  - 深度学习
  - 推荐算法
  - 抖音
---

近期，抖音在北京举行的“安全与信任中心开放日”上公开了抖音APP的算法推荐机制及原理，并将其大致内容摘取出来放在了抖音自建的安全与信任中心的“信息公开”部分:[抖音推荐算法公开链接](https://95152.douyin.com/article/15358)。
众所周知，数学模型一贯是抽象、难以被理解的，而实际应用到抖音上时却又如此强大，因此依据抖音的公开信息、恰又赶上我刚离职得空，于是我便想写一篇博客介绍一下抖音公布算法之一的“Wide & Deep Learning”。

<!--more-->

<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/katex@0.16.8/dist/katex.min.css">
<script defer src="https://cdn.jsdelivr.net/npm/katex@0.16.8/dist/katex.min.js"></script>
<script defer src="https://cdn.jsdelivr.net/npm/katex@0.16.8/dist/contrib/auto-render.min.js"></script>
<script>
  document.addEventListener("DOMContentLoaded", function() {
    renderMathInElement(document.body, {
      delimiters: [
        {left: "$$", right: "$$", display: true},
        {left: "$",  right: "$",  display: false},
        {left: "\\(", right: "\\)", display: false},
        {left: "\\[", right: "\\]", display: true}
      ]
    });
  });
</script>

## <center>算法介绍</center>

推荐算法需要使用数学模型去理解用户行为，首要具备的就是“记忆性”（Memorization）。例如，当用户点赞了一段“Faker 的塞拉斯开团高光”视频，模型会牢记这是一个LOL的内容，基于这种记忆性，平台下一次就会继续推送LOL的视频。但这种记忆性仅针对明确的历史记录，而无法自动推断，因此下一个视频不会有任何逻辑去推送男团抛媚眼或者爆笑综艺之类的切片。然而，若仅依赖记忆性，就会导致用户点赞了帅哥美女之后，平台会单一推送更多帅哥美女的视频，那么当用户大脑分泌的多巴胺达到阈值时，算法工程师们想要将用户不断留在app内的野心也就难以实现了。此时就需要引入另一个模型特性——“泛化性”（Generalization）。我曾经在夜晚练跑时最常见到那类拉着一大货车果蔬的司机，夏天是西瓜、秋天是桔子和玉米，司机老板坐在一旁却不招徕，只是一味不知疲倦的刷着手机，从极大的外放声音可以听到，老板上一段刷着美帝野心，下一段便是美女辣舞，往后是美食切片、大国崛起、激情短剧、育儿心得、养生纲要云云，不知不觉过了很久，仿佛手中便拥有全世界。而这，便是所谓“泛化性”的效果体现。

Wide & Deep Learning模型是由谷歌的Heng-Tze Cheng等作者于2016年提出的推荐系统经典框架，记述在论文[『Wide & Deep Learning for Recommender Systems』](https://arxiv.org/abs/1606.07792v1)中，现作为抖音等头部平台的推荐算法核心架构，其核心创新在于通过双通道结构（Wide部分与Deep部分联合训练）实现“记忆性”与“泛化性”的协同互补。

## <center>Wide部分--Logistic模型</center>

Wide & Deep Learning模型中的wide部分可以将视频的总体反馈简化为一个二分类问题“正反馈”和“负反馈”，当一个用户对于美女视频给出了正反馈，那么模型内部的标签记为$P（美女=1）$；如果该用户对于短剧给出了正反馈，那么模型内部的标签记为$P（短剧=1）$。可以构造逻辑回归模型如下：

$$
y = \mathbf{w}^T \times x + b 
$$

其中，$x=[美女,短剧]$表示输入向量；$\mathbf{w}=[\mathbf{w_{美女}},\mathbf{w_{短剧}}]$表示输入向量$x$的权重；$b$表示偏差。

当用户同时对美女视频和短剧均有正反馈时，该特征取1，否则取0，记为交叉特征：

$$
{\phi_{美女\times短剧}}(x) = x_{美女}\times x_{短剧}
$$

此时的$P({美女}\times{短剧}=1)$，同时输入向量$x$也就更正为$x=[美女,短剧,美女\times 短剧]$。由此，Wide 部分借助这些交叉特征，增强了广义线性模型的非线性记忆能力，对用户行为记录中频繁出现的特征组合进行精确记忆。

## <center>Deep部分--DNN模型</center>

Wide & Deep Learning模型中的deep部分主要解决的是推荐算法中的泛化性，作者Heng-Tze Cheng使用DNN模型进行处理。由于作者在[原论文](https://arxiv.org/abs/1606.07792v1)中并没有说明为何选用DNN模型，而非CNN或者RNN，本文将三类模型的特点进行简单比较如下，从表1中可以看出，面对实时推荐这种大规模在线服务场景，DNN模型具有延迟低、硬件加速支持好等优势：

<center>表1</center>

| 模型 | 网络结构 | 计算依赖 | 实现复杂度 |
| ---- | ------- | --------| ---------- |
| **DNN**  | 多层全连接层 | 矩阵乘加激活函数 | 结构简单，实现和优化较为直接 |
| **CNN**  | 卷积层、池化层和全连接层 | 卷积、池化、矩阵乘加激活函数 | 卷积核设计与优化、边界处理、实现细节复杂 |
| **RNN** | 递归展开的时序单元 | 序列展开、状态维护、矩阵乘加激活函数 | 时序展开与状态传递、梯度传播复杂 |

DNN模型的具体结构主要分为三个层级：输入层、隐藏层和输出层。

**输入层（Input Layer）**

输入层负责接收原始数据特征，输入的原始数据形式如下：

$$
\mathbf{a} = [a_1,a_2,...,a_d]^T
$$

其中，$d$为特征维度，$\mathbf{a}\in\mathbb{R}^d$。在这个层级中，将所有类型的数据转化为数值型或者one-hot编码输入。

**隐藏层（Hidden Layers）**

隐藏层通过激活函数引入非线性能力，允许网络学习复杂的模式。其中，激活函数(ReLU)为：

$$
a^{L}=max(0,\mathbf{w}^{L} a^{(L-1)} + b^{L})
$$
ReLU激活函数的的主要特点是在输入大于零时输出输入值，否则输出零。这种非线性映射的方式可以通过增加稀疏性，减少神经元之间的耦合，增强模型的鲁棒性，从而提升整体模型的泛化能力。

**输出层（Output Layer）**

输出层主要负责输出模型的结果，每个类别分别对应一个输出神经元。

使用Sigmoid函数：

$$
\sigma(z)=\frac{1}{1+e^{-z}}
$$

可以发现，Sigmoid函数的核心作用在于将每层的线性变换结果$z$映射为非线性输出，激活函数将任意实数压缩到$(0,1)$区间，既可以使$z\gg0$时输出趋近$1$、当$z\ll0$时输出趋近$0$，又保证全域可导，便于梯度下降求解参数。

使用上述Sigmoid函数分类：

$$
a^L = \sigma\bigl(\mathbf{w}^T a^{(L-1)} + b)
$$
此种分类可以达到泛化效果，比如用户A在观看美女视频做出正反馈之后，对二次元及短剧类视频做出了正反馈，模型就会学习到美女视频与二次元及短剧类视频存在潜在关联。那么当用户B对“美女视频”产生正反馈时，模型基于相同的特征关联，就会泛化的推送二次元相关内容。

## <center> 模型组装--Wide&Deep模型</center>

在分别了解了wide和deep两部分之后，就可以将上述内容整合组装起来，构建一个完整的Wide&Deep模型(这里的组装也可以理解为Wide&Deep的联合训练)。将样本同时输入Wide部分和Deep部分，分别进行特征处理，两部分的输出通过加权求和得到最终的预测值$\hat{y}$，加权方式如下：


$$
\hat{y} = \sigma(\mathbf{w}^T_{wide}[\mathbf{x},\phi(\mathbf{x})]+ \mathbf{w}^T_{deep}{a^{l_f}} +b)
$$

在得到预测值$\hat{y}$后，依据损失函数计算梯度，将梯度同时反向传播至Wide和Deep部分，更新各自的模型参数以达到更好的推荐效果。基于该模型的训练，抖音便能不断为用户提供“嗑瓜子”式费一点力就享受一下的内容，从而打造一个沉浸式的平台体验。

## <center>写在最后</center>

Wide & Deep Learning模型结合了记忆与泛化的优点，既能精准捕捉用户记录上频繁出现的兴趣特征，也能挖掘出潜在的新组合，弥补了传统方法单独使用时的不足。它的网络结构非常简单，推理速度快，非常适合大规模、高并发的在线推荐环境。同时，Wide部分保留了直观易懂的特征解释，Deep部分又能通过自动学习减少人工特征设计的负担，整体既灵活又实用。

抖音作为一个商用平台在短视频APP中的使用体验冠绝全球，这与其强大的推荐算法离不开关系，仅在安全与信任中心的“信息公开”部分就披露了多种模型算法的联合使用。由此可以观察到，抖音推荐系统并非依赖单一模型，而是通过多阶段模型协同推送。并且抖音虽说将诸如Wide&Deep Learning之类的推荐算法进行公开示例，但并未说明其具体使用参数、具体推送视频的调用算法流程以及对原有模型做出了何种改进，实际应用中调整模型参数、推荐算法改进程度之类的细节操作也同样是及其重要的一环。因此，本文仅作学习者与爱好者的参考之用。

## <center>参考的文献、博客与视频</center>

[Wide & Deep Learning for Recommender Systems](https://arxiv.org/abs/1606.07792v1)

[深入广泛学习：使用TensorFlow来记忆和归纳](https://www.youtube.com/watch?v=NV1tkZ9Lq48)

[Wide & Deep Learning with TensorFlow - Machine Learning](https://www.youtube.com/watch?v=Xmw9SWJ0L50)

[Wide &amp; Deep Learning: Better Together with TensorFlow](https://research.google/blog/wide-amp-deep-learning-better-together-with-tensorflow/)

[见微知著，你真的搞懂Google的Wide&Deep模型了吗？](https://cloud.tencent.com/developer/article/1636190)

[谷歌推出 Wide Deep Learning，开源 TensorFlow API](https://cloud.tencent.com/developer/article/1070675)

[ReLU激活函数有什么样的特点和优势](https://www.youtube.com/watch?v=RhOVOgNl6Bw)

[随机梯度下降如何帮助深度学习找到泛化能力强的解](https://cqb.pku.edu.cn/tanglab/info/1005/2246.htm)