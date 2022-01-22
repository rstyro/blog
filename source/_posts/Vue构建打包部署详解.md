---
title: Vue构建打包部署详解
date: 2019-04-24 18:24:42
updated: 2019-04-24 18:24:42
tags: [Vue]
categories: 前端
---
### 准备工作：
+ 电脑要安装`node.js`及`npm`  
+ 安装淘宝镜像，听说用淘宝镜像安装速度会快过一点  
`npm install cnpm -g --registry=https://registry.npm.taobao.org`
+ 全局安装vue-cli  
`npm install --global vue-cli`
+ 查看vue是否安装成功，注意参数是大V  
`vue -V`

### 构建项目
![](create.png)

构建命令：`vue init webpack 项目名`  
+ Project name  输入项目名称  
+ Project description 输入项目描述  
+ Author 作者   
+ Vue build 打包方式，回车就好了?    
+ Install vue-router?  选择  Y 使用 vue-router，输入 N 不使用?    
+ Use ESLint to lint your code? 代码规范，避免不必要的麻烦推荐 N  
+ Setup unit tests with Karma + Mocha  单元测试  
+ Setup e2e tests with Nightwatch? E2E测试  

### 安装依赖
+ 构建项目成功之后，进入刚才创建的项目目录  
+ 安装依赖命令: `cnpm install` 或者 `npm install`	

### 运行项目
+ 运行命令:`npm run dev`  
+ 然后访问：http://localhost:8080​，出现如下图片说明成功  

![](view.png)

### 打包部署
![](build.png)
+ 打包命令:`npm run build`  
+ 成功之后会在项目路径生成名为`dist`的文件夹
+ 把`dist` 复制到nginx 的html目录下，启动nginx即可
> 可能出现的问题就是你访问的时候会出现一个空白的页面，那是因为样式没有找到报404
解决方案：
+ 修改项目路径下的`conf/index.js` 文件  
+ 修改`module.exports={dev:{},build:{}}` 中的 `build` 把 `assetsPublicPath` 属性从'/' 改为 './'然后重新打包即可  
+ 注意上面的步骤，是修改`build`中的`assetsPublicPath`，不是`dev`中的，别改错了地方

#### 自此你已踏入vue的大门，开启Vue的探索之旅。
