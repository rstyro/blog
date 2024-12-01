---
title: Docker（一）、Docker是什么
date: 2018-01-11 01:11:48
updated: 2018-01-11 01:11:48
tags: [Docker]
categories: 网络运维
---
#### [Docker](https://baike.baidu.com/item/Docker/13344470?fr=aladdin) 是一个开源的应用容器引擎，让开发者可以打包他们的应用以及依赖包到一个可移植的容器中，然后发布到任何流行的 Linux 机器上，也可以实现虚拟化。容器是完全使用沙箱机制，相互之间不会有任何接口。Docker 也被称为第三代PasS平台

## 一、Docker 的起源
### 1、Docker 的创始人 ———— Solomon Hykes
### 2、历史发展
+ ##### 2010年，几个年轻人在旧金山成立了一家做PaaS平台的公司，起名为 dotCloud,dotCloud 主要是基于PaaS平台为开发者或开发商提供技术服务。
+ ##### docker 于2013年3月27 正式作为public项目发布
+ ##### dotCloud 公司2013.10改名为Docker Inc,转型专注于Docker引擎和Docker生态系统。
+ ##### 2014.2月被[Black duck](https://baike.baidu.com/item/blackduck%E8%BD%AF%E4%BB%B6/13466605) 评选为2013年10大开源新项目
+ ##### 2014.9月获取4000万美元融资
+ ##### 2015.4月获取9500万美元融资
+ ##### 2015.6月DockerCon 2015 大会上，Linux基金会与行业巨头联手打造开放容器技术项目Open Container Project
+ ##### 2016.1月Docker凭借着Docker Datacenter与Docker Cloud的发布而迎来爆炸式增长
+ ##### 2017.4月Docker 公司将 Docker 项目改名为 Moby Project，Docker 这个名称保留用作其产品名（纳尼，docker 变成了 moby,那么可爱的鲸鱼图标，变成丑得一比的moby）
+ #### [Github地址](https://github.com/moby/moby)

<!--more-->

## 二、Docker 的技术原理介绍
** Docker 就是虚拟化的一种轻量级替代技术，Docker的容器技术不依赖任何语言、框架或系统。可以将app变成一种标准化的，可移植的、自管理的组件，并脱离服务器硬件在任何主流系统中开发、调试和运行 **
** 简单的说就是在Linux系统上迅速创建一个容器（类型虚拟机）并在容器上部署和运行应用程序，并通过配置文件可以轻松实现应用程序的自动化安装、部署和升级，非常方便，因为使用容器，可以方便的把生产环境和开发环境分开，互不影响，这是docker最普遍的一个玩法。**

### 1、核心技术之cgroups
** Linux 系统中经常有个需求就是希望能限制某个或者某些进程的分配资源，于是就出现了cgroups的概念。**

** cgroup 就是Controller Group,就这个group 中，有分配好的特定比例的cpu时间、IO时间、可用内存大小等系统资源。**

** cgroups 是将任意进程进行分组化管理的Linux内核功能，最初由Google的工程师提出，后来整合进Linux内核中。**

** cgroups中的重要概念是子系统，也就是资源控制器，每种子系统就是一个资源分配器，比如cpu子系统是控制cpu时间分配的，首先挂在子系统，然后才有control group的。比如先挂载memory子系统，然后在其子系统中创建一个cgroup节点，在这个节点中，将需要控制的进程id写入，并且将控制的属性写入，这就完成了内存的资源限制**

### 2、核心技术之LXC 
** LXC是Linux Containers 的简称，是一种基于容器额操作系统层级的虚拟技术，借助于namespace的隔离机制和cgroup限额功能，LXC提供了一套统一的API和和工具来建立和管理container.LXC跟其他操作系统层次的虚拟机相比，最大的优势在于LXC被中和进内核，不用单独为内核打补丁。**

** LXC旨在提供一个共享的Kernel(内核)的OS级虚拟化方法，在执行时不用重复加载Kernel,且container的Kernel与主机共享，因此可以大大加快container的启动过程，并显著减少内存消耗，容器在提供隔离的同时，还通过共享这些资源节省开销，这意味着容器比真正的虚拟化开销要小得多，在实际测试中，基于LXC的虚拟化方法的IO和CPU性能几乎接近baremetal（裸机）的性能。**

#### 从 0.9 版本开始使用 libcontainer 替代 lxc)
#### Docker 1.11后	改用runC和containerd
可参考：
[LXC](https://linuxcontainers.org/lxc/introduction/)
[libcontainer](https://github.com/docker/libcontainer)
[runC](https://github.com/opencontainers/runc)
[containerd](https://github.com/containerd/containerd)


### 3、核心技术之AUFS
 **什么时AUFS?AUFS是一个能透明覆盖一个或多个现有文件系统的层状文件系统，支持将不同目录挂载到同一个虚拟文件系统下，可以把不同的目录联合在一起，组成一个单一的目录，这种是一种虚拟的文件系统，文件系统不用格式化就可以直接挂载。**
 
** Docker一直在用AUFS作为容器的文件系统，当一个进程需要修改一个文件时，AUFS创建该文件的一个副本。AUFS可以把多层合并成文件系统的单层表示，这个过程称为写入复制（copy on write）。**

** AUFS允许Docker把某些镜像作为容器的基础，例如，你可能有一个可以作为很多不同容器的基础的Centos系统镜像，只要一个ContOS 镜像的副本就可以了，这样既节省了存储和内存，也保证更快速的容器部署。**

** 使用AUPS的另一个好处是Docker的版本容器镜像能力，每个新版本都是一个与之前版本的简单差异改动，有效地保持镜像文件最小化，但，这也意味着你总是要有一个记录该容器从一个版本到另一个版本改动的审计跟踪。**


## 三、Docker 的基本概念
### 1、Client 
##### Client 就是Docker的客户端

### 2、Image
##### image（镜像）：是一个极度精简版的Linux程序运行环境，比如vi这种基本的工具都没有，它是需要定制化Build的一个“安装包” 。 Dockerfile 用来创建一个自定义的image,包含用户指定的软件依赖等，使用build命令进行创建。

### 3、Container
##### Container （容器）：是Image 的实例，共享系统内核

### 4、Daemon
##### Daemon（守护进程）：是创建和运行Container的Linux守护进程，可以理解为Docker Container的Container

### 5、Registry
##### Registry/Hub（镜像仓库）：你可以在Docker Hub上轻松下载大量已经容器化好的应用镜像，即拉即用，有些是Docker官方维护的，有些是开发者自发上传分享的。

![](76049.png)

> 若有不对的地方，欢迎指正















