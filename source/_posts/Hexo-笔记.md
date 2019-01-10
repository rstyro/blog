---
title: Hexo 笔记
date: 2019-01-10 14:37:42
tags: hexo
---

## 一、前置条件
#### 1、安装Git
#### 2、安装Node.js

## 二、安装Hexo
```
# 安装 hexo
npm install -g hexo


# 查看是否安装成功，查看版本号
hexo -v

# 初始化Hexo，在当前目录下，创建一个文件夹为blog 的博客
hexo init blog

#生成静态文件
hexo generate


# 启动,默认访问：http://localhost:4000/
hexo s

# 清除缓存，和已生成的静态文件
hexo clean


```

## 三、修改主题
```
# 可以在https://hexo.io/themes/可以查看你喜欢的主题,然后 clone 到themes文件夹下即可
git clone https://github.com/theme-next/hexo-theme-next themes/next
```

## 四、配置
#### 一、基本配置
```
编辑文件路径站点根目录/_config.yml

“title”：博客的名称。
“subtitle”：根据主题的不同，有的会显示有的不会显示。
“description”：主要用于SEO，告诉搜索引擎一个关于站点的简单描述，通常建议在其中包含网站的关键词。
“author”：作者名称，用于主题显示文章的作者。
“language”：语言会对应的解析正在应用的主题中的languages文件夹下的不同语言文件。所以这里的名称要和languages文件夹下的语言文件名称一致。
“timezone”：Asia/Shanghai //可不填写。
```

#### 二、主题配置
修改主题配置文件，在菜单项添加以下内容
```
menu:
  首页: / || home
  关于: /about/ || user
  标签: /tags/ || tags
  分类: /categories/ || th
  存档: /archives/ || archive
  #schedule: /schedule/ || calendar
  #sitemap: /sitemap.xml || sitemap
  #commonweal: /404/ || heartbeat

# Enable/Disable menu icons / item badges.
menu_settings:
  icons: false	#是否显示Icon
  badges: false
```
##### 新建页面
```
hexo new page tags
hexo new page about
hexo new page categories
```
##### 设置头像
```
# Sidebar Avatar
avatar:
  # in theme directory(source/images): /images/avatar.gif
  # in site  directory(source/uploads): /uploads/avatar.gif
  # You can also use other linking images.
  url: #你的头像地址
  # If true, the avatar would be dispalyed in circle.
  rounded: false
  # The value of opacity should be choose from 0 to 1 to set the opacity of the avatar.
  opacity: 1
  # If true, the avatar would be rotated with the cursor.
  rotated: false
```
##### 设置顶部加载
在`\themes\next\layout\_custom head.swig`文件中添加如下代码，
```
<script src="//cdn.bootcss.com/pace/1.0.2/pace.min.js"></script>
<link href="//cdn.bootcss.com/pace/1.0.2/themes/pink/pace-theme-flash.css" rel="stylesheet">
<style>
  .pace .pace-progress {
	  background: #1E92FB; /*进度条颜色*/
	  height: 3px;
  }
  .pace .pace-progress-inner {
	   box-shadow: 0 0 10px #1E92FB, 0 0 5px     #1E92FB; /*阴影颜色*/
  }
  .pace .pace-activity {
	  border-top-color: #1E92FB;    /*上边框颜色*/
	  border-left-color: #1E92FB;    /*左边框颜色*/
  }
</style>
```
#### 三、部署到GitHub
```
# 安装git 部署插件
npm install hexo-deployer-git --save
```
修改 配置文件 `_config.yml` 在`deploy` 选项,修改如下
```
# Deployment
## Docs: https://hexo.io/docs/deployment.html
deploy:
  type: git
  repo: https://github.com/rstyro/blog.git	# 你的github 仓库地址
  branch: master
```