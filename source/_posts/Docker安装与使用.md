---
title: Docker安装与使用
date: 2018-01-11 01:14:08
updated: 2024-04-26 19:14:08
tags: [Docker]
categories: 网络运维
---

## 一、Docker概述
- Docker 是一个开源的应用容器引擎，基于 Go 语言 并遵从 Apache2.0 协议开源。
- Docker 可以让开发者打包他们的应用以及依赖包到一个轻量级、可移植的容器中，然后发布到任何流行的 Linux 机器上，也可以实现虚拟化。
- 容器是完全使用沙箱机制，相互之间不会有任何接口（类似 iPhone 的 app）,更重要的是容器性能开销极低。
- Docker 从 17.03 版本之后分为 CE（Community Edition: 社区版） 和 EE（Enterprise Edition: 企业版），我们用社区版就可以了。
- 基于Linux内核的Cgroup，Namespace，以及AUFS等技术，对进程进行封装隔离，属于操作系统层面的虚拟化技术，由于隔离的进程独立于宿主和其它的隔离的进程，因此也称其为容器。
- 最初实现是基于LXC，从0.7以后开始去除LXC，转而使用自行开发的Libcontainer，从1.1开始，则进一步演进为使用runC和Containerd。
- Docker在容器的基础上，进行了进一步的封装，从文件系统、网络互联到进程隔离等等，极大的简化了容器的创建和维护，使得Docker技术比虚拟机技术更为轻便、快捷。

#### 1、Docker的应用场景
- Web 应用的自动化打包和发布。
- 自动化测试和持续集成、发布。
- 在服务型环境中部署和调整数据库或其他的后台应用。
- 从头编译或者扩展现有的 OpenShift 或 Cloud Foundry 平台来搭建自己的 PaaS 环境。

#### 2、核心概念
- **Client：**Client 就是Docker的客户端
- **Image：**image（镜像）：是一个极度精简版的Linux程序运行环境，比如vi这种基本的工具都没有，它是需要定制化Build的一个“安装包” 。 Dockerfile 用来创建一个自定义的image,包含用户指定的软件依赖等，使用build命令进行创建。
- **Container：**Container （容器）：是Image 的实例，共享系统内核
- **Daemon：**Daemon（守护进程）：是创建和运行Container的Linux守护进程，可以理解为Docker Container的Container
- **Registry：**Registry/Hub（镜像仓库）：你可以在Docker Hub上轻松下载大量已经容器化好的应用镜像，即拉即用，有些是Docker官方维护的，有些是开发者自发上传分享的。


## 二、Docker的安装
- 官方文档：https://docs.docker.com/engine/install/centos/#package-install-and-upgrade

#### 1、配置环境
- 卸载旧版本
- 安装yum-utils，yum-utils: 是一个软件包的集合名称，它包含了一系列有用的YUM工具，如yum-config-manager（用于管理YUM源）、yum-deprecated、yum-groups-manager（管理软件组）、yum-versionlock（锁定软件包版本）等
- 设置docker仓库

```bash
# 删除旧版本
sudo yum remove docker \
                  docker-client \
                  docker-client-latest \
                  docker-common \
                  docker-latest \
                  docker-latest-logrotate \
                  docker-logrotate \
                  docker-engine
                  
                  
#yum-utils 提供了 yum-config-manager ，并且 device mapper 存储驱动程序需要 device-mapper-persistent-data 和 lvm2
sudo yum install -y yum-utils

# 使用官方源地址（比较慢） 可以使用国内的源，如下：阿里云和清华大学
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

# 阿里云
$ sudo yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
# 清华大学源
$ sudo yum-config-manager --add-repo https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/centos/docker-ce.repo


```


#### 2、安装docker依赖
- 安装最新版本的 Docker Engine-Community 和 containerd

```bash

# 安装最新版本的 Docker Engine-Community 和 containerd
$ sudo yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

```

**安装指定版本的docker**

- 使用`yum list docker-ce --showduplicates | sort -r`命令
- 列出并排序您存储库中可用的版本


```bash
[root@localhost ~]# yum list docker-ce --showduplicates | sort -r
已加载插件：fastestmirror
已安装的软件包
可安装的软件包
 * updates: mirrors.jlu.edu.cn
Loading mirror speeds from cached hostfile
 * extras: mirrors.aliyun.com
docker-ce.x86_64            3:26.1.0-1.el7                     docker-ce-stable 
docker-ce.x86_64            3:26.1.0-1.el7                     @docker-ce-stable
docker-ce.x86_64            3:26.0.2-1.el7                     docker-ce-stable 
docker-ce.x86_64            3:26.0.1-1.el7                     docker-ce-stable 
docker-ce.x86_64            3:26.0.0-1.el7                     docker-ce-stable 
docker-ce.x86_64            3:25.0.5-1.el7                     docker-ce-stable 
docker-ce.x86_64            3:25.0.4-1.el7                     docker-ce-stable 
docker-ce.x86_64            3:25.0.3-1.el7                     docker-ce-stable 

# 通过其完整的软件包名称安装特定版本，
# 该软件包名称是软件包名称（docker-ce）加上版本字符串（第二列），从第一个冒号（:）一直到第一个连字符，并用连字符（-）分隔,
# 例如：docker-ce-26.1.0
[root@localhost ~]# yum install docker-ce-<VERSION_STRING> docker-ce-cli-<VERSION_STRING> containerd.io docker-buildx-plugin docker-compose-plugin
```

- 例如：`docker-ce-26.1.0`
- 命令格式：`yum install docker-ce-26.1.0 docker-ce-cli-26.1.0 containerd.io docker-buildx-plugin docker-compose-plugin`
- 其中：**docker-ce**、**docker-ce-cli**、和**containerd.io**是Docker的核心组件，
- 分别代表Docker Community Edition、Docker命令行工具和底层容器运行时。
- 而**docker-buildx-plugin**和**docker-compose-plugin**则是两个附加的插件
- **docker-buildx-plugin (BuildKit):** Docker Buildx 是一个构建工具，它扩展了Docker的构建功能，允许你跨多架构构建容器镜像，比如同时为amd64、arm64等多种CPU架构生成镜像。
- **docker-compose-plugin:** Docker Compose 是一个用于定义和运行多容器Docker应用的工具。通过一个YAML文件，你可以定义一组相关联的服务及其网络、卷等配置，然后使用一个命令来启动、停止或重建所有的服务。


#### 3、启动docker

```bash
# 启动docker
sudo systemctl start docker

# 开启自启动
systemctl enable docker

# 查看版本
docker version

# 查看docker 的信息
docker info

```

#### 4、配置镜像加速
- 国内从 DockerHub 拉取镜像有时会遇到困难，此时可以配置镜像加速器。

```bash
# 配置docker镜像加速,清华大学镜像加速
cat <<EOF | sudo tee /etc/docker/daemon.json
{
    "registry-mirrors": ["https://docker.mirrors.ustc.edu.cn"]
}
EOF


# 刷新配置 
systemctl daemon-reload

# 重启docker
systemctl restart docker
```

## 三、Docker的使用

#### 1、常用命令
- docker的一些常用命令


| 命令          | 详解                          |
| ------------- | ----------------------------- |
| docker search | 搜索镜像                      |
| docker pull   | 获取镜像                      |
| docker images | 列出镜像                      |
| docker run    | 运行镜像                      |
| docker ps     | 查看后台运行的容器            |
| docker rm     | 删除容器                      |
| docker rmi    | 删除镜像                      |
| docker cp     | 在host和container之间拷贝文件 |
| docker commit | 保存改动为新的镜像            |
| docker build  | 构建镜像                      |


- 使用示例：

```bash
# 从 Docker Hub 查找所有镜像名包含 openjdk，并且收藏数大于 1 的镜像
# -f <过滤条件>:列出收藏数不小于指定值的镜像。
# --no-trunc :显示完整的镜像描述；
# --automated :只列出 automated build类型的镜像；
docker search -f stars=1 openjdk


# 从Docker Hub下载REPOSITORY为openjdk的镜像,版本为11。
# -a :拉取所有 tagged 镜像
# --disable-content-trust :忽略镜像的校验,默认开启
docker pull openjdk:11


# 查看本地镜像列表
# -a :列出本地所有的镜像（含中间映像层，默认情况下，过滤掉中间映像层）；
# --digests :显示镜像的摘要信息；
# -f :显示满足条件的镜像；
# --no-trunc :显示完整的镜像信息；
docker images


# 使用nginx镜像,以后台模式启动一个容器,将容器的80端口映射到主机80端口,主机的目录/var/html 映射到容器的/usr/share/nginx/html/。
# -d: 后台运行容器，并返回容器ID
# -P: 随机端口映射，容器内部端口随机映射到主机的端口
# -p: 指定端口映射，格式为：主机(宿主)端口:容器端口
# --name="nginx-lb": 为容器指定一个名称；
# -e,--env   username="ritchie": 设置环境变量；
# --memory,-m :设置容器使用内存最大值；
# --cpuset="0-2" or --cpuset="0,1,2": 绑定容器到指定CPU运行；
# --net="bridge": 指定容器的网络连接类型，支持 bridge/host/none/container: 四种类型；
# --link=[]: 添加链接到另一个容器；
# -v, --volume : 绑定一个卷，格式：-v 主机地址:容器地址
# --expose=[]: 开放一个端口或一组端口；
# --restart 设置容器退出后的重启策略，如 no, on-failure, always, unless-stopped
# 默认=no,容器不会在退出后自动重启。
# on-failure=当容器因非0退出状态码退出时，Docker守护进程将尝试重启容器。
# always=不论容器的退出状态码如何，只要容器停止，Docker守护进程就会自动重启容器。
# unless-stopped=只要Docker守护进程运行，容器就会在每次停止后自动重启，除非容器被显式停止（比如通过docker stop命令）。
# --rm  当容器退出后自动删除容器。这对于创建临时容器非常有用。
# --network  指定容器加入的网络，如 bridge, host, none, 或自定义网络名
docker run -p 80:80 -v /var/html:/usr/share/nginx/html/ -d --name=mynginx nginx


# 列出容器
# -a :显示所有的容器，包括未运行的。
# -l :显示最近创建的容器。
# -n :列出最近创建的n个容器。
docker ps


#强制删除容器 db01、db02
# -f :通过 SIGKILL 信号强制删除一个运行中的容器。
docker rm -f db01 db02

# 强制删除本地镜像nginx
docker rmi -f nginx

# 将主机/www/html 目录拷贝到容器96f7f14e99ab的/www目录下。
docker cp /www/html 96f7f14e99ab:/www/

# 将容器a404c6c174a2 保存为新的镜像,并添加提交人信息和说明信息。
# -a :提交的镜像作者；
# -c :使用Dockerfile指令来创建镜像；
# -m :提交时的说明文字；
# -p :在commit时，将容器暂停。
docker commit -a "rstyro" -m "测试提交" a404c6c174a2  naginx:v2


#  通过 /path/to/a/Dockerfile 创建镜像
# -f :指定要使用的Dockerfile路径；
# --network: 默认 default。在构建期间设置RUN指令的网络模式， 等等参数
docker build -f /path/to/a/Dockerfile .


# 获取容器/镜像的元数据,语法：docker inspect [OPTIONS] NAME|ID [NAME|ID...]
# -f :指定返回值的模板文件。
# --type :为指定类型返回JSON。
docker inspect nginx


# 进入容器ID=a404c6c174a2的终端
docker exec -it  a404c6c174a2 /bin/bash
```


#### 2、Dockerfile
- Dockerfile 是一个用来构建镜像的文本文件，文本内容包含了一条条构建镜像所需的指令和说明。
- **1、FROM**  指定了基础镜像
- **2、MAINTAINER**  描述这个镜像的作者，以及联系方式(可选)
- **3、LABEL**  镜像的标签信息 (可选)
- **4、ENV**  环境变量配置
- **5、RUN**  在构建镜像时，需要执行的 shel1 命令
- **6、ADD**  将主机中的指定文件复制到容器的目标位置，可以简单理解为 cp 命令
- **7、WORKDIR**  设置容器中的工作目录，如果该目录不存在，那么会自己创建
- **8、VOLUME**  镜像数据卷绑定，将主机中的指定目录挂载到容器中
- **9、EXPOSE**  设置容器启动后要暴露的端口
- **10、CMD**  作用是描述镜像构建完成后，启动容器时默认执行的脚本
- **11、ENTRYPOINT**  和CMD的指令作用一样，不同点：ENTRYPOINT不会被运行容器时指定的命令所覆盖，而CMD 会被覆盖



- 指令示例如下：


```bash
# 1、先指定当前镜像的基础镜像是什么
FROM openjdk:11

# 2、描述这个镜像的作者，以及联系方式(可选)
MAINTAINER rstyro

# 3、镜像的标签信息 (可选)
LABEL version="1.0"
LABEL description="这是我的第一个 Dockerfile"

# 4、环境变量配置
ENV JAVA ENV dev
ENV APP NAME test-dockerfile

# ENV JAVA ENV=dev APP NAME=test-dockerfile

#5、在构建镜像时，需要执行的 shel1 命令
RUN s -al
RUN mkdir /www/dockerfile/test

# 6、将主机中的指定文件复制到容器的目标位置，可以简单理解为 cp 命令
#ADD /wwwindex.html /www/server
ADD ["/www/index.html"，"/www/server"]


#7、设置容器中的工作目录，如果该目录不存在，那么会自己创建
WORKDIR /app
#在设置完工作目录后，执行 pwd 命令，打印的目录就是 /app
RUN pwd

# 8、镜像数据卷绑定，将主机中的指定目录挂载到容器中
VOLUME ["/www/html"] 


# 9、设置容器启动后要暴露的端口
EXPOSE 8080/tcp

# 10、CMD 和 ENTRYPOINT 选择其一即可，作用是描述镜像构建完成后，启动容器时默认执行的脚本
# CMD ping 127.0.0.1
CMD ["sh","-c" "ping 127.0.0.1"]

# 11、作用是描述镜像构建完成后，启动容器时默认执行，和CMD的区别是 ENTRYPOINT的命令执行不会被覆盖
ENTRYPONINT ping 127.0.0.1
ENTRYPONINT ["sh","-c" "ping 127.0.0.1"]


```

**简单的springboot使用Dockerfile示例：**

```bash
# 使用java环境
FROM openjdk:8   
MAINTAINER rstyro
WORKDIR /home/java
ADD target/hello-docker-SNAPSHOT.jar /home/java/app.jar
EXPOSE 8080
ENTRYPOINT ["java","-jar","/home/java/app.jar"]
```
