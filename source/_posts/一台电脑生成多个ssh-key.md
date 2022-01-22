---
title: 一台电脑生成多个ssh-key
date: 2020-09-09 18:58:25
updated: 2020-09-09 18:58:25
tags: [SSH, Linux]
categories: 网络运维
---
### 前言
SSH Key 是一种方法来确定受信任的计算机，从而实现免密码登录。
### 一、生成ssh-key
#### 1、首先需要检查你电脑是否已经有 SSH key
```
# 进入ssh-key 目录
cd ~/.ssh

# 查看是否生成了ssh-key
ls
```

#### 2、创建一个ssh-key
```shell
/*
-t 指定密钥类型，默认是 rsa ，可以省略。
-C 设置注释文字，比如邮箱。
-f 指定密钥文件存储文件名。当需要生成多个的时候就需要这个参数了
回车之后会让你输入密码，这个密码是你push时候输入的密码，不是账号密码。
如果你不想输入就直接回车，即可
*/
ssh-keygen -t rsa -C "your_email@example.com"
```

#### 3、把ssh-key 添加到Github
- 上面命令不报错，在`~/.ssh` 下应该有`id_rsa`、`id_rsa.pub` 两个文件.
- 把`id_rsa.pub`的内容添加到Github的用户-> `settings` -> `SSH and GPG keys`-> `New SSH key` 

#### 4、验证
```
# 验证是否成功
ssh -T git@github.com
```
![](ssh-test-success.png)

### 二、同一台电脑生成多个ssh-key
一般人都有个公司`git`、`github`、`gitee`之类的，搞多个ssh-key是很有必要的。
#### 1、生成新的ssh-key
```
# new_id_rsa 就是你要新生成ssh-key的名字
ssh-keygen -t rsa -C "your_email@example.com" -f ~/.ssh/new_id_rsa
```

#### 2、添加新生成的ssh-key
默认ssh只会读取 `id_rsa`，所以为了让ssh识别新的ssh-key，需要将其添加到ssh-agent
```
# 添加新的key
ssh-add.exe ~/.ssh/new_id_rsa
```

**如果出现`Could not open a connection to your authentication agent.` 可执行**
```
# 需要ssh-agent启动bash，或者说把bash挂到ssh-agent下面
ssh-agent.exe bash

# 再次添加，即可
ssh-add.exe ~/.ssh/new_id_rsa
```

![](ssh-add.png)

当然不需要的时候 你也可以使用
```
# 删除所有管理的密钥
ssh-add -D 

# 删除指定的
ssh-add -d 

# 查看现在增加进去的指纹信息
ssh-add -l 

# 查看现在增加进去的私钥
ssh-add -L 

```
#### 3、配置config文件
```
# 查看是否存在config文件
ls -l  ~/.ssh

# 如果没有存在则创建
touch config
```
如果已经存在则编辑如下：
```
Host github
HostName github.com
User  rstyro
IdentityFile ~/.ssh/id_rsa_github

Host company
HostName 172.16.1.205
User  companyName
IdentityFile ~/.ssh/id_rsa_company
```
名词解释
```
Host			是自己定义的名字
HostName		就是远程git地址了
User			登录用户
IdentityFile	就是私钥路径名称
```

**当使用的时候要注意一点**
如果你host 和hostName 不一样的话，**你clone 的时候要使用的是你上面config文件配置的host而不是hostName.**如下图：
![](host-clone.png)

#### 4、验证
```
ssh -T git@github.com
```