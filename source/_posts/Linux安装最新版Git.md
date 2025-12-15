---
title: Linux安装最新版Git
date: 2019-05-05 11:42:47
updated: 2025-12-15 11:42:47
tags:
---

## 引言

- Git 作为当今最流行的分布式版本控制系统，是开发者和系统管理员必备的工具。虽然大多数 Linux 发行版的官方仓库都提供了 Git，但版本往往滞后于官方发布。本文将详细介绍在 Linux 系统中安装 Git 的多种方法，包括快速安装、获取最新版本以及版本管理技巧。

## 一、包管理安装Git
在linux中，安装Git 一般一条命令即可，如下：

- **Debian/Ubuntu 及其衍生系统**

```bash

apt-get install git

# 或者先更新
apt update; apt install git
```


- **Fedora/RHEL/CentOS**

```bash
# Fedora 22+ / RHEL 8+
sudo dnf install git

# CentOS 7 / RHEL 7
sudo yum install git
```

- **Gentoo 系列**
```bash
emerge --ask --verbose dev-vcs/git
```

+ **Arch Linux 及衍生版**
```bash
pacman -S git
```

- **openSUSE 系列**
```bash
zypper install git
```

- **Mageia 系列**
```bash
urpmi git
```

- **Nix/NixOS 系列**
```bash
nix-env -i git
```

- **FreeBSD 系列**
```bash
pkg install git
```

- **Solaris 9/10/11  (OpenCSW) 系列**
```bash
pkgutil -i git
```



- 上面都是基于包管理进行安装的

**优点：**

- 安装简单快捷
- 自动处理依赖关系
- 可通过系统更新统一升级

**缺点：**

- 版本通常较旧
- 可能缺少最新功能

> 有时安装的版本比较旧。不是我们想要的






## 二、最新版安装

- 在Github,[https://github.com/git/git/tags](https://github.com/git/git/tags) 下载最新版本。
- 在2025-12-15，最新版本为：`v2.52.0`

![git0](git0.png)


- 执行命令如下：

```bash
# 访问 GitHub 发布页查看最新版本，得到下载链接。下载v2.52.0版本
wget https://github.com/git/git/archive/refs/tags/v2.52.0.tar.gz

# 安装依赖
yum -y install curl-devel expat-devel gettext-devel openssl-devel zlib-devel gcc perl-ExtUtils-MakeMaker

# 解压
tar -zxvf v2.52.0.tar.gz

# 进入解压目录 
cd git-2.52.0/

# 编译
make prefix=/usr/local/git all

# 安装Git在/usr/local/git路径
make prefix=/usr/local/git install
```



![](git-download.png)



+ 配置环境变量

```bash
# 编辑环境配置文件/etc/profile,末尾 export PATH=/usr/local/git/bin:$PATH
# 然后执行： source /etc/profile 使其立马生效，一行命令如下：

echo 'export PATH=/usr/local/git/bin:$PATH' >> /etc/profile && source /etc/profile
```



![](git-success.png)

> git version 查看安装的git版本




- 如上图，如果成功显示 `git version 2.52.0`，恭喜你，已经用上了顶尖开发者同款的最新版Git！
- `测试一下`：简单clone 了一下我的rstyro仓库成功。
- 定期更新Git可以确保您获得最新的功能改进和安全补丁，提升开发效率和代码安全性。



**互动话题**：

> 你平时用什么方法安装/管理Git？在版本更新上踩过什么坑？欢迎在评论区分享你的经验！





*如果觉得这篇教程对你有帮助，别忘了“**点赞**”和“**在看**”！*
*关注我，一个专注分享开发实战干货的号主，让你在技术路上少走弯路。*

