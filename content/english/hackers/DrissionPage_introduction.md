---
title: "基于DrissionPage的爬虫方法"
output: html_document
date: "2024-12-23"
output: md_document
tags:
  - python
  - crawler
---

在面对一个需要大批量获取数据的任务时，如获取抖音评论、购物购车平台评分等，这部分数据除了氪金购买外，一般的做法是使用网络爬虫进行获取。但目前这些平台为了防止数据的泄露，近年来也在不断加强网站的反爬机制，因此网络爬虫在实际过程中的运用难度越来越高。

网站爬虫的一般操作是:首先分析出所需数据的xpath或者正则表达来定位数据，再基于Selenium或者BeautifulSoup模拟浏览器运行、PyQuery解析和操作HTML文档，然后获取平台中商品价格、销量、地区、评论等信息，并存储于文档中。另一类则有不同思路，并非使用python模拟人类的浏览器操作，而是使用requests库直接向服务器发送请求数据包，以获取所需要的数据。

由于Selenium库虽然可以操作浏览器、模拟用户行为，但使得浏览器运行效率并不高；而后者使用request请求数据包，就会面对需要登录的网站时，往往还要应付验证码、JS混淆、签名参数等反爬手段，门槛较高。若数据是由JS计算生成的，还须重现计算过程，开发效率不高。

也是上述理由，在我又一次面对网络爬虫任务的时候感到头疼，不过很快随着我的搜索，一个新的爬虫解决方案被我翻了出来------DrissionPage。

那么，DrissionPage是什么呢？

DrissionPag设计初衷，是将request和Selenium两种数据获取的方式合而为一，并能够在不同须要时切换相应模式，提高开发和运行效率。

> 由Claude生成：DrissionPage的核心架构由三个关键组件构成，它们通过精密的协作提供了强大的网页自动化能力。会话管理器作为框架的"大脑"，负责管理所有网络通信状态，包括在Selenium和Requests两种模式间自动同步cookies和session信息，统一管理代理设置和请求头配置，并能有效处理会话超时、重连等异常情况；页面对象模型(POM)则提供了统一的元素定位接口和链式操作支持，通过惰性加载机制提升性能，同时自动进行元素状态检查以确保操作可靠性；混合模式引擎则充当Selenium和Requests之间的智能桥梁，通过维护共享上下文来保持数据同步，并能根据不同操作类型自动选择最优模式，例如在需要JavaScript交互时使用Selenium，而在进行数据抓取时优先使用Requests。这三个组件的协同工作使得开发者能够通过统一的接口实现复杂的自动化任务，同时享受到简化的代码编写体验、更高的程序执行效率、增强的稳定性以及优化的资源占用，特别是在处理需要频繁切换操作模式的场景时，能够显著提升开发效率和程序性能。在内部实现上，它们通过事件驱动和状态同步机制保持紧密联系，任何一个组件的状态变化都会及时通知其他组件进行相应调整，从而确保整个系统的一致性和可靠性，这种设计不仅解决了传统网页自动化工具的局限性，还为复杂的网页交互自动化需求提供了一个优雅而高效的解决方案。

DrissionPage项目地址：<https://github.com/g1879/DrissionPage>

下面使用我自己爬取京东商品评论的例子，介绍一下DrissionPage的基础使用方法，第一步就是安装DrissionPage库到自己的电脑环境中。下载方式很简单，直接在cmd窗口调用pip下载即可：

```         
pip install DrissionPage
```

接下来，DrissionPage给予了使用者两个选择，一是可以使用SessionPage发送和接收数据包（SessionPage基于Python requests库实现，本质是一个增强版的Session对象），二是使用ChromiumPage启动浏览器模仿用户操作（ChromiumPage 基于Chrome DevTools Protocol实现，直接与浏览器内核通信，不依赖Selenium）。我在爬取京东商品评论的过程中使用的 ChromiumPage。

具体的操作如下：

```         
# 导入DrissionPage库中的ChromiumPage包
from DrissionPage import ChromiumPage

# 实例化浏览器对象
driver_car = ChromiumPage()
```

上述步骤之后，就需要一点html的基础知识来帮助你找到数据包的地址。

```         
# 以京东为例，数据包地址：https://api.m.jd.com/

# 监听数据包
driver_JD.listen.start('https://api.m.jd.com/?appid=item-v3&functionId=pc_club_productPageComments')
# 访问网站
driver_JD.get('https://item.jd.com/100051210211.html')
# 等待数据包加载
resp = driver_JD.listen.wait()
# 直接获取数据包返回的响应数据
json_data = resp.response.body
```

**至此，上述代码已经获取了包含商品页面的价格、图片、评论等全部数据的请求体。**

为了更为细致的发掘请求体所包含的数据和本文最需要的商品评论数据,可以将请求体打印出来观察：

```         
print(json_data)
```

接下来只需要将上述主要代码合并进入"创建文档-提取数据-数据写入文档"的常规步骤了。

参考文档：

[推荐一款新的自动化测试框架：DrissionPage！](https://www.cnblogs.com/jinjiangongzuoshi/p/17139003.html)

[DrissionPageを使ってみる](https://note.com/valnd_/n/n9667875f1fc3)

[DrissionPage 1.6.0 Project description](https://pypi.org/project/DrissionPage/1.6.0/)

**特别鸣谢制作DrissionPage库的g1879大佬**（鞠躬鞠躬）

以下附上爬取京东商品评论的全部代码，仅作参考：

```
#### 注意本篇爬取数据没有去除换行符“/n”
from DrissionPage import ChromiumPage
import csv
import time
import random

# 创建文件对象
f = open('data_for_鲜鸡蛋.csv',mode='w',encoding='utf-8-sig',newline='')
# 字典写入方法
csv_writer = csv.DictWriter(f,fieldnames=['昵称','日期','地区','产品名称','评分','评论'])
csv_writer.writeheader()
# 实例化浏览器对象
driver_JD = ChromiumPage()

# 数据包地址：https://api.m.jd.com/
# 监听数据包
driver_JD.listen.start('https://api.m.jd.com/?appid=item-v3&functionId=pc_club_productPageComments')
# 访问网站
driver_JD.get('https://item.jd.com/100051210211.html')
# 点击查看评论数据
driver_JD.ele('css:#detail > div.tab-main.large > ul > li:nth-child(5)').click()
for page in range(1,1000):
    time.sleep(random.uniform(5, 7))  # 随机等待2-5秒
    print(f'正在采集第{page}页的数据内容')
    # #下滑页面到底部
    # driver_JD.scroll.to_bottom()
    # 等待数据包加载
    resp = driver_JD.listen.wait()
    # 获取响应数据
    json_JDdata = resp.response.body
    # 提取评论所在列表
    comments_jd = json_JDdata['comments']

    for index in comments_jd:
        ip_label = index.get('location', None) #ip地址
        # 提取具体评论信息
        dit = {
            '昵称':index['nickname'],
            '日期':index['creationTime'],
            '地区':ip_label,
            '产品名称':index['productColor'],
            '评分': index['score'],
            '评论':index['content'],
        }
        csv_writer.writerow(dit)
        print(dit)
    # 点击下一页按钮
    driver_JD.ele('css:.ui-pager-next',index = 1).click()
```