---
title: SVN 代码迁移
date: 2017-08-12 11:30:57
tags: [SVN]
categories: 开发工具
---
# SVN 将服务器上的版本库代码迁移到另一台服务器上
## 我们可能因为服务器到期了，要把代码迁移到新的服务器，废话不多说，流程如下：
#### 1、把服务器的代码 备份。
#### 2、在新的服务器安装svn
#### 3、在新的服务器创建一个仓库
#### 4、把备份文件加载到刚创建的仓库

### 1、备份
```
 # /usr/local/svnRepo 是你的仓库地址
 # blog 是你要备份的项目
 # blog.dump  是要生成的配置文件
  
 svnadmin dump /usr/local/svnRepo/blog/ > /root/blog.dump
```
### 2.在新的服务器安装svn
##### 不会安装看这里：[http://www.lrshuai.top/atc/show/9](http://www.lrshuai.top/atc/show/9)

### 3、创建仓库
##### 在新的服务器 创建新的仓库
```
svnadmin create /usr/local/svnRepo/newblog
```
![](1502076979952076738.png)

### 4、加载备份文件
```
# 从旧服务器复制文件到新的服务器
scp /root/blog.dump  root@192.168.1.1:/root/blog.dump        #192.168.1.1 就是目标主机ip(新服务器的ip)，

#加载备份文件
svnadmin load /usr/local/svnRepo/newblog </root/blog.dump
```
![](1502077491103063187.png)
