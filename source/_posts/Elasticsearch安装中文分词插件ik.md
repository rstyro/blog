---
title: Elasticsearch安装中文分词插件ik
date: 2017-12-11 17:13:52
tags: [ElasticSearch]
categories: 搜索引擎
---
# Elasticsearch安装中文分词插件ik
### 为了做搜索弄了一个星期，还是没有搜索到自己想要的内容。虽说各种查询都懂一点，但是就是查不到自己想要的。
### 那是以为我用的是默认的标准分词器。对中文来说不是很好，它把中文拆成一个一个的。
### 然后我就各种论坛，各种博客，各种学习网站。然后发现有这么一个ik中文分词的东西。
### 然后我就试着使用了一下，发现确实一些基本的查询都搞定了。一个星期的问题，其实装个插件就搞定了。有点小郁闷。
## 一、Windows 安装ik插件
#### 1、下载地址：[https://github.com/medcl/elasticsearch-analysis-ik](https://github.com/medcl/elasticsearch-analysis-ik)
下载你对应的版本
![](89174.png)

![](94607.png)
#### 2、解压
把下载的文件，解压
#### 3、在elasticsearch 的plugins 目录下，新建一个名为：ik 的文件夹，把上面解压的东西放到ik文件内
![](10743.png)
#### 4、重启elasticsearch

## 二、Linux 安装ik插件
操作和windows 的操作一样。。。。。。
