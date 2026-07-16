---
title: 一台电脑生成多个ssh-key
date: 2020-09-09 18:58:25
updated: 2020-09-09 18:58:25
tags: [SSH, Linux]
categories: 网络运维
---
### 前言
SSH Key 是一种用于身份验证的加密密钥对，能够实现免密码登录远程服务器或代码托管平台（如 GitHub、GitLab 等）。如何在一台电脑上生成并管理多个 SSH Key，以满足不同服务（公司 Git、GitHub、Gitee 等）的使用需求，并涵盖 SSH 免密登录的配置方法。



### 一、生成第一个 SSH Key

#### 1、检查是否已有 SSH Key

打开终端，进入 SSH 配置目录并查看已有密钥文件

```bash
# 进入ssh-key 目录
cd ~/.ssh

# 查看是否生成了ssh-key
ls
```


如果存在 `id_rsa` 和 `id_rsa.pub` 文件，则表示已生成过密钥对。若无需保留，可先备份或删除后再重新生成。

<!--more-->



#### 2、创建 SSH Key

使用 `ssh-keygen` 命令生成新密钥对：

```bash
ssh-keygen -t rsa -C "your_email@example.com"
```

**参数说明**：

- `-t`：指定密钥类型，默认 RSA，可省略。
- `-C`：注释文字，通常填写邮箱，便于识别。
- `-f`：指定密钥文件名（如需生成多个密钥，此参数必用）。

执行后系统会提示输入密码（passphrase），该密码用于保护私钥，每次使用需输入；若不想设置，直接按回车跳过。

默认生成的文件为 `~/.ssh/id_rsa`（私钥）和 `~/.ssh/id_rsa.pub`（公钥）



#### 3、将公钥添加到 GitHub

- 复制公钥内容：`cat ~/.ssh/id_rsa.pub`，复制输出的全部文本。
- 登录 GitHub，进入 **Settings** → **SSH and GPG keys** → **New SSH key**，粘贴公钥并保存。



#### 4、验证连接
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

此时会生成 `~/.ssh/new_id_rsa`（私钥）和 `~/.ssh/new_id_rsa.pub`（公钥）。

#### 2、添加新生成的ssh-key

默认ssh只会读取 `id_rsa`，所以为了让ssh识别新的ssh-key，需要将其添加到 SSH Agent
```bash
# 启动 ssh-agent 并添加密钥
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/new_id_rsa
```

**如果出现`Could not open a connection to your authentication agent.` 可执行**
```bash
# 需要ssh-agent启动bash，或者说把bash挂到ssh-agent下面
ssh-agent.exe bash

# 再次添加，即可
ssh-add.exe ~/.ssh/new_id_rsa
```

![](ssh-add.png)

当然不需要的时候 你也可以使用
```bash
# 删除所有管理的密钥
ssh-add -D 

# 删除指定的
ssh-add -d  ~/.ssh/new_id_rsa

# 查看现在增加进去的指纹信息
ssh-add -l 

# 查看现在增加进去的私钥
ssh-add -L 

```
#### 3、配置config文件
```bash
# 查看是否存在config文件
ls -l  ~/.ssh

# 如果没有存在则创建
touch config
```
如果已经存在则编辑如下：
```tex
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



### 三、SSH 免密登录远程服务器

除了代码托管平台，SSH Key 也常用于 Linux 服务器的免密登录。以下以 `192.168.1.50`（源终端）向目标服务器 `192.168.1.54`、`192.168.1.55` 配置免密登录为例。

```bash
# 1.原终端生成密钥对
ssh-keygen -t ed25519 -C "key-for-L20"
# 一路按回车键即可

# 2.将原终端的公钥复制到 目标服务器
ssh-copy-id root@192.168.1.54
ssh-copy-id root@192.168.1.55

# 测试
ssh root@192.168.1.55
```



#### 简化后续连接命令

为避免每次输入完整 IP 和用户名，可在源终端（`192.168.1.50`）的 `~/.ssh/config` 文件中配置 SSH 客户端,编辑 `~/.ssh/config` 文件：

```bash
Host server54
    HostName 192.168.1.54
    User root
    IdentityFile ~/.ssh/id_ed25519
Host server55
    HostName 192.168.1.55
    User root
    IdentityFile ~/.ssh/id_ed25519
```



保存后，今后只需在 `192.168.1.50` 上执行：

```bash
ssh server54

ssh server54
```

即可快速连接，体验免密便捷登录。
