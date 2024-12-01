---
title: Centos7部署K8S
date: 2024-04-26 19:33:32
updated: 2024-04-26 19:33:32
tags: [k8s,Kubernetes]
categories: 网络运维
---

### 一、Kubernetes概述
- Kubernetes 是一个可移植、可扩展的开源平台，用于管理容器化的工作负载和服务，可促进声明式配置和自动化。 Kubernetes 拥有一个庞大且快速增长的生态，其服务、支持和工具的使用范围相当广泛。
- Kubernetes 这个名字源于希腊语，意为“舵手”或“飞行员”。K8s 这个缩写是因为 K 和 s 之间有 8 个字符的关系。 Google 在 2014 年开源了 Kubernetes 项目。 Kubernetes 建立在 Google 大规模运行生产工作负载十几年经验的基础上， 结合了社区中最优秀的想法和实践。

<!--more-->

#### 1、为什么需要K8S,它能做什么
-  Kubernetes 为你提供了一个可弹性运行分布式系统的框架。 Kubernetes 会满足你的扩展要求、故障转移你的应用、提供部署模式等。
-  **服务发现和负载均衡**
Kubernetes 可以使用 DNS 名称或自己的 IP 地址来暴露容器。 如果进入容器的流量很大， Kubernetes 可以负载均衡并分配网络流量，从而使部署稳定。
-  **存储编排**
Kubernetes 允许你自动挂载你选择的存储系统，例如本地存储、公共云提供商等。
-  **自动部署和回滚**
你可以使用 Kubernetes 描述已部署容器的所需状态， 它可以以受控的速率将实际状态更改为期望状态。 例如，你可以自动化 Kubernetes 来为你的部署创建新容器， 删除现有容器并将它们的所有资源用于新容器。
-  **自动完成装箱计算**
你为 Kubernetes 提供许多节点组成的集群，在这个集群上运行容器化的任务。 你告诉 Kubernetes 每个容器需要多少 CPU 和内存 (RAM)。 Kubernetes 可以将这些容器按实际情况调度到你的节点上，以最佳方式利用你的资源。
-  **自我修复**
Kubernetes 将重新启动失败的容器、替换容器、杀死不响应用户定义的运行状况检查的容器， 并且在准备好服务之前不将其通告给客户端。
-  **密钥与配置管理**
Kubernetes 允许你存储和管理敏感信息，例如密码、OAuth 令牌和 SSH 密钥。 你可以在不重建容器镜像的情况下部署和更新密钥和应用程序配置，也无需在堆栈配置中暴露密钥。
-  **批处理执行** 除了服务外，Kubernetes 还可以管理你的批处理和 CI（持续集成）工作负载，如有需要，可以替换失败的容器。
-  **水平扩缩** 使用简单的命令、用户界面或根据 CPU 使用率自动对你的应用进行扩缩。
- **IPv4/IPv6 双栈**  为 Pod（容器组）和 Service（服务）分配 IPv4 和 IPv6 地址。
-  **为可扩展性设计** 在不改变上游源代码的情况下为你的 Kubernetes 集群添加功能



### 二、安装K8S


#### 1、预置条件
- 需要关闭防火墙，关闭swap分区，时间同步等
- 下面的步骤，所有主机都需要执行

**主机环境：**
```bash
# 都是centos7.9，虚拟机环境，最小化安装
192.168.80.128 master
192.168.80.131 node1 
192.168.80.132 node2 

```

##### Centos7.9升级内核
- 网上搭建资料全是升级内核的
- 我尝试了下，使用Centos7.9的默认内核：`3.10.0-1160.71.1.el7.x86_64`集群搭建成功
- 测试安装nginx,任意节点正常访问，没有部署比较复杂的应用，不确定是否出现不稳定的情况
- **可以不装**，但是需要的时候，得知道怎么升级

```bash
#查看现在的内核版本
[root@master ~]#uname -a
Linux worker01 3.10.0-1160.el7.x86_64 #1 SMP Mon Oct 19 16:18:59 UTC 2020 x86_64 x86_64 x86_64 GNU/Linux

# 查看 yum 中可升级的内核版本
# 如果list中有需要的版本可以直接执行 update 升级，多数是没有的，所以要按以下步骤操作
yum list kernel --showduplicates


# 导入ELRepo软件仓库的公共秘钥
rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org

# Centos7系统安装ELRepo
yum install -y https://www.elrepo.org/elrepo-release-7.el7.elrepo.noarch.rpm
# Centos8系统安装ELRepo
yum install -y https://www.elrepo.org/elrepo-release-8.el8.elrepo.noarch.rpm

# 查看ELRepo提供的内核版本
yum --disablerepo="*" --enablerepo="elrepo-kernel" list available


#kernel-lt：表示longterm，即长期支持的内核
#kernel-ml：表示mainline，即当前主线的内核
#安装主线内核（32位安装kernek-ml）
yum --enablerepo=elrepo-kernel install -y kernel-ml.x86_64

# grub2-mkconfig: 这是一个GRUB2的工具，用于根据系统的当前状态动态生成GRUB配置文件。
# 它会检查系统上的内核版本、安装的引导菜单项以及其他配置细节，然后基于这些信息创建或更新GRUB配置。
# 当你运行这个命令时，它会自动检测系统上的变化（比如内核更新），并根据这些变化重新生成GRUB的配置文件
# 确保启动菜单保持最新，且包含所有有效的启动选项。这对于系统升级、内核更换或者修复GRUB配置问题非常有用。
grub2-mkconfig -o /boot/grub2/grub.cfg

# 查看启动内核的菜单项有哪些
[root@node2 ~]#  sudo awk -F\' '$1=="menuentry " {print i++ " : " $2}' /etc/grub2.cfg
0 : CentOS Linux (6.8.7-1.el7.elrepo.x86_64) 7 (Core)
1 : CentOS Linux (3.10.0-1160.71.1.el7.x86_64) 7 (Core)
2 : CentOS Linux (0-rescue-f788a8d1727f47ddaf6a16214215d088) 7 (Core)
[root@node2 ~]# 


# 备份启动内核版本
cp /etc/default/grub /etc/default/grub-bak

# 设置默认内核版本
grub2-set-default 0 

# 查看默认内核
grubby --default-kernel

#重新创建内核配置
grub2-mkconfig -o /boot/grub2/grub.cfg

#更新软件包并重启系统
yum makecache

# 重启
reboot

#验证内核
[root@master ~]# uname -a
Linux master 6.8.7-1.el7.elrepo.x86_64 #1 SMP PREEMPT_DYNAMIC Wed Apr 17 15:04:09 EDT 2024 x86_64 x86_64 x86_64 GNU/Linux

```


##### 设置hostname
- 不设置也问题不大,但是hosts文件要设置

```bash

# 在需要创建master节点的主机执行,例如我这里:192.168.80.128上执行
hostname master

# 节点 192.168.80.131上执行
hostname node1

# 192.168.80.132上执行
hostname node2

# 然后重新连接hostname就变过来了
```


##### 1、安装NTP时间同步
- 配置NTP时间同步服务 

```bash
#!/bin/bash

#安装ntp软件包。
yum -y install ntp

#设置ntp服务开机自启。
systemctl enable ntpd

#启动ntp服务。
systemctl start ntpd

#从公共ntp服务器同步一次时间。
ntpdate -u cn.pool.ntp.org

#将系统时间同步到硬件时钟。
hwclock --systohc

#设置系统时区为上海。
timedatectl set-timezone Asia/Shanghai
```

##### 2、安装cri-dockerd
- `CRI` 是 Kubernetes 项目引入的一个标准化接口，旨在解耦Kubernetes与底层容器运行时的直接依赖。它定义了一套API，使得Kubernetes可以与任何符合CRI规范的容器运行时进行通信，而不需要知道具体运行时的实现细节。这意味着Kubernetes可以支持多种容器运行时，如Docker、containerd、CRI-O等，增强了平台的灵活性和可移植性。
- 在 Kubernetes v1.24 版本之前，Docker 是默认的容器运行时。由于Docker并未直接实现CRI接口，Kubernetes引入了一个叫作Dockershim的组件作为适配层，它的作用是将Kubernetes的CRI调用转换为Docker API调用。简单来说，Dockershim起到了桥梁的作用，使得Kubernetes能够通过CRI接口与Docker容器引擎进行通信。
- 随着Kubernetes的发展，为了进一步减少依赖并优化架构，从Kubernetes 1.20版本开始，官方宣布计划废弃Dockershim，并鼓励使用直接支持CRI接口的容器运行时。
- 从Kubernetes 1.24 +版本开始，Dockershim 已从 Kubernetes 项目中移除，改为默认使用Containerd
- **cri-dockerd** 是一种替代方案，它直接实现了CRI接口，允许Kubernetes直接与Docker交互，而无需依赖Dockershim，是随着Dockershim废弃计划出现的解决方案之一，旨在提供更直接、更高效且未来更可持续的Docker集成方式。
- cri-dockerd的Github地址：https://github.com/Mirantis/cri-dockerd
- 最新发布的版本：https://github.com/Mirantis/cri-dockerd/releases


```bash
#!/bin/bash

# 下载centos7的rpm包
wget https://github.com/Mirantis/cri-dockerd/releases/download/v0.3.13/cri-dockerd-0.3.13-3.el7.x86_64.rpm
# 安装
rpm -ivh cri-dockerd-0.3.13-3.el7.x86_64.rpm


# 修改配置cri-docker的启动配置文件：/usr/lib/systemd/system/cri-docker.service

# vim到/usr/lib/systemd/system/cri-docker.service里
# 找到大概第10行修改ExecStart=/usr/bin/cri-dockerd --network-plugin=cni --pod-infra-container-image=registry.aliyuncs.com/google_containers/pause:3.7

# 这段配置是修改 cri-docker 系统服务的启动参数,主要作用是:
# 设置 Kubernetes 使用的容器网络插件为 CNI (Container Network Interface)
# 通过 --network-plugin=cni 参数指定网络插件类型为 CNI。这是 Kubernetes 默认的网络模型,
# 需要安装额外的 CNI 插件比如 Calico、Flannel 等来提供 Pod 网络。
# 设置 pause 镜像
# 通过 --pod-infra-container-image 指定 pause 镜像,这个镜像用来提供 Pod 内部共享的网络和文件空间。
# 默认是 k8s.gcr.io/pause,这里修改为了国内阿里云的镜像,加速获取镜像。
# 修改 cri-docker 服务的启动参数
# Kubernetes 通过 docker CRI (Container Runtime Interface) 来管理容器,cri-docker 这个系统服务就是 docker 的 CRI 实现。
# 通过修改服务启动参数,可以自定义 Kubernetes 使用 docker 时的网络和镜像配置。
# 总结一下,这组配置主要是设置了 CNI 网络插件类型和自定义了 pause 镜像,方便后续 Kubernetes 集群使用。

# 直接一行命令替换
sudo sed -i 's#ExecStart=.*#ExecStart=/usr/bin/cri-dockerd --network-plugin=cni --pod-infra-container-image=registry.aliyuncs.com/google_containers/pause:3.7#' /usr/lib/systemd/system/cri-docker.service



# 重载系统守护进程→设置cri-dockerd自启动→启动cri-dockerd
systemctl daemon-reload
systemctl enable cri-docker.socket cri-docker --now
```

#####  3、环境配置

```bash
#!/bin/bash


# 配置hosts文件
cat >> /etc/hosts << EOF
192.168.80.128    master
192.168.80.131    node1
192.168.80.132    node2
EOF



# 将 SELinux 设置为 permissive 模式（相当于将其禁用）
# 为什么要关闭，因为容器访问主机文件系统时必需禁用，不然会访问不到
sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config


# 关闭防火墙，设置开机不启动
systemctl stop firewalld
systemctl disable firewalld


# 关闭swap分区
sudo swapoff -a

# 永久禁用swap,删除或注释掉/etc/fstab里的swap设备的挂载命令，以/dev/mapper/centos-swap开头的那一行
# /^\/dev\/mapper\/centos-swap/：这是一个地址表达式，匹配所有以 /dev/mapper/centos-swap 开头的行
# s/^/#/：这是一个替换命令，s 是替换命令的简写，^ 表示行的开始，/#/ 是要插入的注释符号
sudo sed -i '/^\/dev\/mapper\/centos-swap/s/^/#/' /etc/fstab

```


##### 4、配制iptables规则
- 清理iptables规则
- **iptables -F：**清除iptables的filter表的所有规则链中的规则。
- **iptables -X：**删除iptables的filter表中所有非默认的空链。
- **iptables -F -t nat：**清除iptables的nat表的所有规则链中的规则。
- **iptables -X -t nat：**删除iptables的nat表中所有非默认的空链。
- **iptables -P FORWARD ACCEPT：**设置iptables filter表的FORWARD链的默认策略为ACCEPT，允许数据包转发。这对于Kubernetes集群中的Pod间通信是必要的。

```bash
# 清理iptables规则
iptables -F && iptables -X && iptables -F -t nat && iptables -X -t nat && iptables -P FORWARD ACCEPT

#设置系统参数,告诉内核的网桥模块在处理IPv4和IPv6数据包时调用iptables的规则。
# 这是因为在Kubernetes中，Pod间的通信依赖于iptables规则进行网络策略实施和数据包转发，
# 这两行设置确保了在使用如Flannel、Calico等网络插件时，网络策略能够正确应用。
cat <<EOF >  /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF


# 重新加载所有sysctl配置文件
sysctl --system
```


#####  5、安装docker
- 使用docker作为k8s的CRI接口的容器运行时，所以需要安装docker

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

# 使用官方源地址（比较慢） 可以使用国内的阿里镜像
sudo yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo

# 安装26.1.0版本的docker
yum install docker-ce-26.1.0 docker-ce-cli-26.1.0 containerd.io docker-buildx-plugin docker-compose-plugin

# 开启自启动
systemctl enable docker


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

# 查看版本
docker version

# 查看docker 的信息
docker info
```


#### 2、开始安装

##### 1、安装k8s组件
- kubeadm、kubelet 和 kubectl 是 Kubernetes 集群管理中的三个核心组件
- **kubeadm** 是 Kubernetes 社区提供的一种简化集群部署和管理的工具。
- **kubelet** 是运行在每一个 Kubernetes 节点上的代理进程，它是节点与集群控制平面之间的桥梁。
  - kubelet 的主要职责包括：
  - **Pod 管理：**根据 API server 的指令，创建、修改和监控节点上的容器（Pods），确保它们按照预期状态运行。
  - **健康检查：**定期检查容器状态并向 API server 报告，支持节点级和 Pod 级别的健康检查。
  - **资源管理：**管理节点资源，如 CPU、内存和存储，确保 Pod 的资源请求和限制得到满足。
  - **日志和监控：**收集容器日志，提供给集群的监控系统
- **kubectl** 是 Kubernetes 的命令行工具，用于与 Kubernetes 集群进行交互。它提供了强大的命令集，使得用户能够从本地机器上执行各种集群操作





```bash
# 配置yum为阿里镜像仓库
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF


#查看kubeadm有什么版本，-V自然排序r是倒序 head -n 10只显示10条
yum list --showduplicates kubeadm | sort -Vr | head -n 10


#不指定版本默认为最新版本,目前安装k8s 1.28.2
sudo yum install -y kubelet-1.28.2 kubeadm-1.28.2 kubectl-1.28.2 --disableexcludes=kubernetes

#设置kubelet自启动
systemctl enable  kubelet  --now

```

##### 2、初始化K8S集群
- 只需要在master节点初始化即可

```
# 初始化k8s集群
#在master节点执行初始化（node节点不用执行）
#apiserver-advertise-address  指定apiserver的IP，即master节点的IP
#image-repository  设置镜像仓库为国内镜像仓库
#kubernetes-version  设置k8s的版本，跟kubeadm版本一致
#service-cidr  这是设置node节点的网络的，暂时这样设置
#pod-network-cidr  这是设置node节点的网络的，暂时这样设置
#cri-socket  设置cri使用cri-dockerd

kubeadm init \
--apiserver-advertise-address=192.168.80.128 \
--image-repository registry.cn-hangzhou.aliyuncs.com/google_containers \
--kubernetes-version v1.28.2 \
--service-cidr=10.96.0.0/12 \
--pod-network-cidr=10.244.0.0/16 \
--cri-socket unix:///var/run/cri-dockerd.sock \
--ignore-preflight-errors=all

# 可以查看kubelet日志
journalctl -xefu kubelet  
```

- 等待初始化成功，如果不出问题，出现成功：`Your Kubernetes control-plane has initialized successfully!`
- 我的返回如下：

```bash
[kubelet-finalize] Updating "/etc/kubernetes/kubelet.conf" to point to a rotatable kubelet client certificate and key
[addons] Applied essential addon: CoreDNS
[addons] Applied essential addon: kube-proxy

Your Kubernetes control-plane has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

Alternatively, if you are the root user, you can run:

  export KUBECONFIG=/etc/kubernetes/admin.conf

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join 192.168.80.128:6443 --token ugbeb5.673rb9ivznpzi2oh \
        --discovery-token-ca-cert-hash sha256:7a68c380e113ca2b1d589bb31bc3e6a21bb5e28373d79bf7083bf4c3f8446639 
```

![](init.png)


- 返回的信息中，让我们配置环境变量，然后还要配置k8s集群的pod网络
- 然后先执行如下命令，配置环境变量

```bash
# 在master节点执行，配置环境变量
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
export KUBECONFIG=/etc/kubernetes/admin.conf


# 在node节点执行，配置环境变量
echo "export KUBECONFIG=/etc/kubernetes/kubelet.conf" >> /etc/profile
source /etc/profile
```

##### 3、安装网络插件
- 目前比较常用的是flannel和calico，
- flannel的功能比较简单，不具备复杂网络的配置能力，不支持网络策略；
- calico是比较出色的网络管理插件，单具备复杂网络配置能力的同时，
- 往往意味着本身的配置比较复杂，所以相对而言，比较小而简单的集群使用flannel，
- 考虑到日后扩容，未来网络可能需要加入更多设备，配置更多策略，则使用calico更好。
- 官网地址：https://docs.tigera.io/calico/latest/getting-started/kubernetes/self-managed-onprem/onpremises


**calico**

```
# 下载calico.yaml
wget https://raw.githubusercontent.com/projectcalico/calico/v3.27.3/manifests/calico.yaml --no-check-certificate

#查看calico用到的镜像
grep image: calico.yaml


# 默认的calico.yaml清单文件无需手动配置Pod子网范围（如果需要，可通过CALICO_IPV4POOL_CIDR指定），默认使用
# kube-controller-manager的"–cluster-cidr"启动项的值，即kubeadm init时指定的"–pod-network-cidr"或清单文件中使用"podSubnet"的值。

vim calico.yaml
...
# 我下载的V3.27.3这里是被注释上的，打开即可
- name: CALICO_IPV4POOL_CIDR
  value: "10.244.0.0/16"   #更改为初始化pod的地址范围
...


#安装calico.yaml
kubectl apply -f calico.yaml

#如果是重装calico，需要先清除旧的配置
rm -rf /etc/cni/net.d/
rm -rf /var/lib/calico
```

**flannel**
- 如果不想装calico就安装flannel
- Github地址：https://github.com/flannel-io/flannel#deploying-flannel-manually

```bash
# 下载flannel
wget https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
#更改network地址，是初始化时的pod地址范围，默认就是：10.244.0.0/16
 vim kube-flannel.yml
 ...
 net-conf.json: |
    {
      "Network": "10.244.0.0/16",  #更改为初始化pod的地址范围
      "Backend": {
        "Type": "vxlan"
      }
    }
 ...   
#安装flannel
kubectl apply -f kube-flannel.yml
```



##### 4、node节点加入集群
- 网络也配置好之后，node节点执行加入

```bash
查看所有命名空间的pod
[root@mastart k8s]# kubectl get pod -A
NAMESPACE     NAME                                       READY   STATUS     RESTARTS       AGE
kube-system   calico-kube-controllers-787f445f84-sb5rn   0/1     Pending    0              38s
kube-system   calico-node-57q5j                          0/1     Init:0/3   0              38s
kube-system   calico-node-ksspf                          0/1     Init:0/3   0              38s
kube-system   calico-node-rbxhw                          0/1     Init:0/3   0              38s
kube-system   coredns-6554b8b87f-24c2t                   0/1     Pending    0              3h1m
kube-system   coredns-6554b8b87f-fd9df                   0/1     Pending    0              3h1m
kube-system   etcd-mastart                               1/1     Running    0              3h1m
kube-system   kube-apiserver-mastart                     1/1     Running    1 (3h1m ago)   3h1m
kube-system   kube-controller-manager-mastart            1/1     Running    0              3h1m
kube-system   kube-proxy-45ftw                           1/1     Running    0              33m
kube-system   kube-proxy-85w8t                           1/1     Running    0              33m
kube-system   kube-proxy-fn9wz                           1/1     Running    0              3h1m
kube-system   kube-scheduler-mastart                     1/1     Running    0              3h1m


#如果有pod启动失败，可以通过下面的命令查看pod的详细信息
kubectl describe pod coredns-6554b8b87f-24c2t -n kube-system


#在你要加入的node节点上执行，master节点不用执行
# --cri-socket unix:///var/run/cri-dockerd.sock 是一个配置选项，用于指定容器运行时接口 (CRI) 与 Docker 守护程序之间的通信方式。
kubeadm join 192.168.80.128:6443 --token ugbeb5.673rb9ivznpzi2oh \
        --discovery-token-ca-cert-hash sha256:7a68c380e113ca2b1d589bb31bc3e6a21bb5e28373d79bf7083bf4c3f8446639  \
    --cri-socket unix:///var/run/cri-dockerd.sock
 
 #如果上面的令牌忘记了，或者新的node节点加入，在master上执行下面的命令，生成新的令牌
 # 记得后面要加上 --cri-socket unix:///var/run/cri-dockerd.sock 容器运行时
 kubeadm token create --print-join-command
```

![](pod.png)

![](nodes.png)




##### 5、验证集群的可用性

```bash
#检查节点
#status为ready就表示集群可以正常运行了
[root@node1 k8s]# kubectl get nodes
NAME      STATUS   ROLES           AGE     VERSION
mastart   Ready    control-plane   3h41m   v1.28.2
node1     Ready    <none>          74m     v1.28.2
node2     Ready    <none>          74m     v1.28.2

# 查看集群健康情况
[root@mastart k8s]# kubectl get cs
Warning: v1 ComponentStatus is deprecated in v1.19+
NAME                 STATUS    MESSAGE   ERROR
etcd-0               Healthy   ok        
scheduler            Healthy   ok        
controller-manager   Healthy   ok        
```


**其他命令：**
- 移除节点

```bash
# 在要移除的节点上，禁用调度以阻止新的Pod在这个节点上运行
kubectl cordon $NODENAME

# 逐渐驱逐节点上的Pod,驱逐过程会尽量将Pod转移到其他节点上，并确保服务不中断。
# 使用--ignore-daemonsets参数是因为daemonset类型的Pods通常不应该被驱逐，它们通常提供集群级别的服务
kubectl drain $NODENAME --ignore-daemonsets --delete-emptydir-data

# 从集群中移除节点
kubectl delete node $NODENAME

# 如果你想彻底清除节点上的所有Kubernetes组件，可以手动删除相关的文件和目录，例如：
rm -rf /etc/cni/net.d
rm -rf /var/lib/kubelet/*
```



#### 3、测试部署
- 测试部署Nginx
- 在k8s-master机器上执行

```bash
# 创建一次deployment部署
[root@mastart k8s]# kubectl create deployment nginx --image=nginx
deployment.apps/nginx created
# Deployment nginx Service 暴露80端口
[root@mastart k8s]# kubectl expose deployment nginx --port=80 --type=NodePort
service/nginx exposed
# 查看Nginx的pod和service信息
[root@mastart k8s]# kubectl get pod,svc -owide
NAME                         READY   STATUS    RESTARTS   AGE   IP             NODE
pod/nginx-7854ff8877-f7st9   1/1     Running   0          11m   10.244.104.1   node2

NAME                 TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE 
service/kubernetes   ClusterIP   10.96.0.1       <none>        443/TCP        3h59m 
service/nginx        NodePort    10.105.79.246   <none>        80:31129/TCP   11m
[root@mastart k8s]# 
[root@mastart k8s]# 
```

- 访问Nginx地址： http://任意节点的ip:图中Nginx的对外映射端口，http://192.168.80.132:31129/

