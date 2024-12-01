---
title: Vue使用Vue-cli工具
date: 2019-04-26 17:12:28
updated: 2019-04-26 17:12:28
tags: [Vue]
categories: 前端
---

# 使用Vue-cli 开发
下面是官方的Tip
> 关于旧版本
> 
> Vue CLI 的包名称由 vue-cli 改成了 @vue/cli。 如果你已经全局安装了旧版本的 vue-cli (1.x 或 2.x)，你需要先通过 npm uninstall vue-cli -g 或 yarn global remove vue-cli 卸载它。

如果你已经安装了新版本就忽略它。  

<!--more-->

## 创建项目
+ 命令：`vue create demo(你的项目名)`
+ 项目配置
   如果直接回车就是选择默认的配置，但是我们可以看看手动配置











#### 可能出现的问题
> 如果出现类似下面的信息，说明你得更换版本
> vue create is a Vue CLI 3 only command and you are using Vue CLI 2.9.6.
> You may want to run the following to upgrade to Vue CLI 3:
> 
> npm uninstall -g vue-cli
> npm install -g @vue/cli

#### 卸载旧版 vue-li,重新安装  
```
# 卸载以前装的vue-cli
npm uninstall -g vue-cli

# 安装vue/cli
npm install -g @vue/cli
# OR
yarn global add @vue/cli
```
