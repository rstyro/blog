---
title: Containerd安装与运维指南
tags: [Containerd,k8s]
categories: 网络运维
date: 2026-07-15 19:09:59
---





## 一、Containerd 简介

[Containerd](https://containerd.io/) 是一个行业标准的容器运行时，由 CNCF 托管（毕业项目）。它负责管理容器的完整生命周期：镜像拉取/存储、容器的创建/运行/销毁、网络和存储管理等。

- **GitHub**: https://github.com/containerd/containerd
- **官方文档**: https://github.com/containerd/containerd/tree/main/docs

> **提示**: Containerd 自 1.24 版本起成为 Kubernetes 默认的容器运行时（取代 Docker）。


<!--more-->




## 二、环境要求

| 项目 | 要求 |
|------|------|
| 操作系统 | Linux (推荐 Ubuntu 20.04+ / CentOS 7.9+ / Rocky 8+) |
| 内核版本 | >= 4.x（推荐 5.x+） |
| runc | >= 1.1.0 |
| CNI 插件 | 需单独安装 |

### 2.1 前置依赖安装

```bash
# 加载必要内核模块
cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter


# 验证内核模块是否加载成功
lsmod | grep -e overlay -e br_netfilter


# 设置必要的 sysctl 参数
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

sudo sysctl --system



# 验证网络参数是否生效（显示 1 代表成功）
sysctl net.bridge.bridge-nf-call-iptables net.ipv4.ip_forward
```



## 三、安装 Containerd

### 3.1 二进制包安装（通用方式）

**适用场景**: 所有 Linux 发行版，离线安装，需要特定版本。

```bash
# 1. 下载 containerd 二进制包
CONTAINERD_VERSION="2.2.6"
wget https://github.com/containerd/containerd/releases/download/v${CONTAINERD_VERSION}/containerd-${CONTAINERD_VERSION}-linux-amd64.tar.gz

# 2. 解压到 /usr/local
sudo tar Cxzvf /usr/local containerd-${CONTAINERD_VERSION}-linux-amd64.tar.gz

# 3. 下载 runc
RUNC_VERSION="1.3.6"
wget https://github.com/opencontainers/runc/releases/download/v${RUNC_VERSION}/runc.amd64
sudo install -m 755 runc.amd64 /usr/local/sbin/runc

# 4. 下载 CNI 插件
CNI_VERSION="1.6.2"
wget https://github.com/containernetworking/plugins/releases/download/v${CNI_VERSION}/cni-plugins-linux-amd64-v${CNI_VERSION}.tgz
sudo mkdir -p /opt/cni/bin
sudo tar Cxzvf /opt/cni/bin cni-plugins-linux-amd64-v${CNI_VERSION}.tgz

# 5. 创建 systemd 服务文件
sudo mkdir -p /usr/local/lib/systemd/system
sudo tee /usr/local/lib/systemd/system/containerd.service <<'EOF'
[Unit]
Description=containerd container runtime
Documentation=https://containerd.io
After=network.target local-fs.target

[Service]
ExecStartPre=-/sbin/modprobe overlay
ExecStart=/usr/local/bin/containerd

Type=notify
Delegate=yes
KillMode=process
Restart=always
RestartSec=5

LimitNPROC=infinity
LimitCORE=infinity
LimitNOFILE=infinity

TasksMax=infinity
OOMScoreAdjust=-999

[Install]
WantedBy=multi-user.target
EOF

# 6. 启用服务
sudo systemctl daemon-reload
sudo systemctl enable --now containerd
```

### 3.2 使用 apt 安装（Debian/Ubuntu）

```bash
# 1. 安装依赖
sudo apt-get update
sudo apt-get install -y ca-certificates curl

# 2. 添加 Docker 官方 GPG 密钥（containerd 随 docker 源分发）
# sudo install -m 0755 -d /etc/apt/keyrings
# sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
# sudo chmod a+r /etc/apt/keyrings/docker.asc

# 3. 添加 apt 源
# echo \
#   "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
#   $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
#   sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  
# 2. 添加 阿里云Docker GPG 密钥（地址替换为阿里云镜像站）
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# 3. 添加 阿里云Docker APT源（把download.docker.com替换成mirrors.aliyun.com/docker-ce）
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://mirrors.aliyun.com/docker-ce/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
 
  

# 4. 安装 containerd
sudo apt-get update

# 查看可安装的版本
sudo apt list -a containerd.io

# 安装最新版
# sudo apt install -y containerd.io
# 安装与卸载
# sudo apt install -y containerd.io=2.1.5-1~ubuntu.24.04~noble
# 卸载
# apt purge containerd.io=2.1.5-1~ubuntu.24.04~noble -y

# 安装 1.7.27-1 版本
sudo apt install -y containerd.io=1.7.27-1


# 5. 启动并设置开机自启
sudo systemctl enable --now containerd
```

### 3.3 使用 yum/dnf 安装（CentOS/RHEL/Rocky）

```bash
# 1. 安装 yum-utils
sudo yum install -y yum-utils

# 2. 添加 Docker 官方 yum 源
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

# 3. 安装 containerd.io
sudo yum install -y containerd.io

# 或使用 dnf (Fedora / Rocky 8+)
# sudo dnf install -y containerd.io

# 4. 启动并设置开机自启
sudo systemctl enable --now containerd
```



## 四、生成默认配置

Containerd 安装后默认不生成配置文件，需要手动生成：

```bash
# 创建配置目录
sudo mkdir -p /etc/containerd

# 生成默认配置文件
sudo containerd config default | sudo tee /etc/containerd/config.toml

# 查看配置
sudo cat /etc/containerd/config.toml
```



## 五、配置详解

配置文件位置: `/etc/containerd/config.toml`

### 5.1 镜像加速（Registry Mirrors）

> 注册表镜像用于加速从容器镜像仓库拉取镜像的速度。
> 
> **两种配置方式（互斥）**:
> - **方式A（推荐）**: `config.toml` 中设置 `config_path`，然后在 `/etc/containerd/certs.d/` 下通过 `hosts.toml` 配置
> - **方式B**: `config.toml` 中内联 `registry.mirrors` 配置
> 
> **一旦设置了 `config_path`，内联的 `registry.mirrors` 和 `registry.configs` 将被忽略。**

以下采用**方式A（推荐）**，以 Docker Hub 为例，其他仓库同理：

```bash
# 编辑配置文件
sudo vim /etc/containerd/config.toml
```

找到 `[plugins."io.containerd.grpc.v1.cri".registry]` 部分，修改如下：

> 如果是 containerd 2.x 插件路径改为 io.containerd.cri.v1.images

```toml
# containerd 2.x 插件路径改为 io.containerd.cri.v1.images，写法一致
# 1. 修改 config.toml（设置 config_path=/etc/containerd/certs.d）
    [plugins."io.containerd.grpc.v1.cri".registry]
      config_path = "/etc/containerd/certs.d"     
     
```

上面配置了 `/etc/containerd/certs.d` 路径，下面配置镜像加速

```bash
# 2. 创建目录
mkdir -p /etc/containerd/certs.d/docker.io

# 3. 写入 hosts.toml
cat > /etc/containerd/certs.d/docker.io/hosts.toml << 'EOF'
server = "https://registry-1.docker.io"
[host."https://docker.1ms.run"]
  capabilities = ["pull", "resolve"]
  skip_fetch_failure = true
  timeout = "30s"
[host."https://docker.m.daocloud.io"]
  capabilities = ["pull", "resolve"]
  skip_fetch_failure = true
  timeout = "30s"
EOF


# 4. 测试
ctr image pull docker.io/library/nginx:alpine
# 指定 k8s 命名空间
ctr -n k8s.io images list
ctr image pull --hosts-dir=/etc/containerd/certs.d docker.io/library/nginx:alpine



# crictl是安装k8s时才有
crictl pull docker.io/library/nginx:alpine
```



### 5.2 配置代理（HTTP/HTTPS Proxy）

当拉取镜像需要通过代理服务器访问外网时，有以下两种方式配置：

#### 方式一：为 Containerd 配置代理（推荐）

修改 containerd 的 systemd 服务文件，添加环境变量：

```bash
# 1. 创建 containerd 服务的代理配置目录
sudo mkdir -p /etc/systemd/system/containerd.service.d


# 2. 创建代理配置文件
sudo tee /etc/systemd/system/containerd.service.d/http-proxy.conf <<'EOF'
[Service]
# 大写标准环境变量
# 这里的http://127.0.0.1:7890 是我的本地安装clash代理地址
Environment="HTTP_PROXY=http://127.0.0.1:7890"
Environment="HTTPS_PROXY=http://127.0.0.1:7890"
Environment="NO_PROXY=localhost,127.0.0.1,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16,.local,.svc,.cluster.local"

# 兼容小写变量，适配各类OCI/镜像拉取工具
Environment="http_proxy=http://127.0.0.1:7890"
Environment="https_proxy=http://127.0.0.1:7890"
Environment="no_proxy=localhost,127.0.0.1,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16,.local,.svc,.cluster.local"
EOF
```

```bash
# 3. 重新加载并重启
sudo systemctl daemon-reload
sudo systemctl restart containerd

# 4. 验证代理是否生效
sudo systemctl show containerd --property=Environment


# 卸载代理
rm -f /etc/systemd/system/containerd.service.d/http-proxy.conf
systemctl daemon-reload
systemctl restart containerd
```

> **注意**: `NO_PROXY` 中应包含 Kubernetes 集群的 Service CIDR 和 Pod CIDR，以及 `.svc`、`.cluster.local` 等域名，避免集群内部通信经过代理。





#### 方式二：全局环境变量设置

```bash
# 编辑 /etc/environment 或 /etc/profile
sudo tee -a /etc/environment <<EOF
HTTP_PROXY=http://127.0.0.1:7890
HTTPS_PROXY=http://127.0.0.1:7890
NO_PROXY=localhost,127.0.0.1,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16,.local,.svc,.cluster.local
EOF
```

#### 查看当前代理配置

```bash
# 查看 containerd 进程的实际环境变量
sudo cat /proc/$(pidof containerd)/environ | tr '\0' '\n' | grep -i proxy
```



### 5.3 配置私有镜像仓库

> **重要**: 当你在 `config.toml` 中设置了 `config_path = "/etc/containerd/certs.d"` 后，所有 registry 的镜像加速、私有仓库配置都应放在 `/etc/containerd/certs.d/<registry-host>/hosts.toml` 中。**原有的内联 `registry.mirrors` 和 `registry.configs` 会被忽略**。

#### 目录结构总览

```
/etc/containerd/certs.d/
├── docker.io/
│   └── hosts.toml           # Docker Hub 镜像加速
├── harbor.mycorp.com/
│   ├── hosts.toml           # 私有 Harbor 仓库
│   ├── ca.crt               # 自签名 CA 证书
│   ├── client.crt           # 客户端证书（mTLS场景）
│   └── client.key           # 客户端密钥
└── my-registry.local:5000/
    └── hosts.toml           # HTTP 非安全仓库
```

#### 场景1：HTTP 非安全私有仓库

适用于内网 Harbor 或自建 registry 且未配置 HTTPS。

```bash
# 创建目录
sudo mkdir -p /etc/containerd/certs.d/my-registry.local:5000

# 写入 hosts.toml
sudo tee /etc/containerd/certs.d/my-registry.local:5000/hosts.toml <<'EOF'
server = "http://my-registry.local:5000"

[host."http://my-registry.local:5000"]
  capabilities = ["pull", "resolve", "push"]
  skip_verify = true
EOF
```

> **说明**:
> - `server` — 指明上游目标地址（HTTP 协议）
> - `skip_verify = true` — 跳过 TLS 验证（HTTP 仓库必须设为 true）
> - `capabilities` — `pull`（拉取）、`resolve`（解析）、`push`（推送）

#### 场景2：HTTPS 私有仓库（自签名证书）

当私有仓库开启了 HTTPS 但使用自签名证书时：

```bash
# 1. 创建目录并放入 CA 证书
sudo mkdir -p /etc/containerd/certs.d/harbor.mycorp.com

# 2. 将自签名 CA 证书复制进来
sudo cp /path/to/ca.crt /etc/containerd/certs.d/harbor.mycorp.com/ca.crt

# 3. 写入 hosts.toml
sudo tee /etc/containerd/certs.d/harbor.mycorp.com/hosts.toml <<'EOF'
server = "https://harbor.mycorp.com"

[host."https://harbor.mycorp.com"]
  capabilities = ["pull", "resolve", "push"]
  ca = "/etc/containerd/certs.d/harbor.mycorp.com/ca.crt"
EOF
```

也可以直接用 `skip_verify` 跳过证书校验（仅限测试环境）：

```toml
[host."https://harbor.mycorp.com"]
  capabilities = ["pull", "resolve", "push"]
  skip_verify = true
```

#### 场景3：HTTPS 私有仓库 + 认证

需要登录凭据的私有仓库：

```bash
# 1. 创建目录
sudo mkdir -p /etc/containerd/certs.d/harbor.mycorp.com

# 2. 写入带认证的 hosts.toml
sudo tee /etc/containerd/certs.d/harbor.mycorp.com/hosts.toml <<'EOF'
server = "https://harbor.mycorp.com"

[host."https://harbor.mycorp.com"]
  capabilities = ["pull", "resolve", "push"]
  ca = "/etc/containerd/certs.d/harbor.mycorp.com/ca.crt"

  [host."https://harbor.mycorp.com".header]
    authorization = ["Basic YWRtaW46bXlwYXNzd29yZA=="]
EOF
```

> `authorization` 的值为 `Base64(username:password)`，生成方式：
> ```bash
> echo -n "admin:mypassword" | base64
> ```

#### 场景4：mTLS 双向认证

私有仓库要求客户端提供证书时：

```bash
# 1. 放入客户端证书和密钥
sudo cp /path/to/client.crt /etc/containerd/certs.d/harbor.mycorp.com/client.crt
sudo cp /path/to/client.key /etc/containerd/certs.d/harbor.mycorp.com/client.key
sudo cp /path/to/ca.crt       /etc/containerd/certs.d/harbor.mycorp.com/ca.crt

# 2. hosts.toml 中指定客户端证书
sudo tee /etc/containerd/certs.d/harbor.mycorp.com/hosts.toml <<'EOF'
server = "https://harbor.mycorp.com"

[host."https://harbor.mycorp.com"]
  capabilities = ["pull", "resolve", "push"]
  ca = "/etc/containerd/certs.d/harbor.mycorp.com/ca.crt"
  client = [["/etc/containerd/certs.d/harbor.mycorp.com/client.crt", "/etc/containerd/certs.d/harbor.mycorp.com/client.key"]]
EOF
```

#### 配置后验证

```bash
# 重启 containerd 使配置生效
sudo systemctl restart containerd

# 测试拉取私有仓库镜像
sudo ctr image pull harbor.mycorp.com/project/nginx:latest

# 使用 --hosts-dir 指定目录测试
sudo ctr image pull --hosts-dir=/etc/containerd/certs.d harbor.mycorp.com/project/nginx:latest

# 如果安装了 crictl
sudo crictl pull harbor.mycorp.com/project/nginx:latest
```

> **安全提示**: `hosts.toml` 中的密码以 Base64 编码存储（非加密），生产环境建议使用密钥管理服务。

### 5.4 配置 Cgroup 驱动

对于 Kubernetes 集群，**强烈推荐使用 systemd cgroup 驱动**:

```toml
[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
  runtime_type = "io.containerd.runc.v2"

  [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
    SystemdCgroup = true
```

### 5.5 配置 sandbox 镜像（pause 镜像）

```toml
[plugins."io.containerd.grpc.v1.cri"]
  # 默认的 sandbox_image，可按需修改为国内镜像源
  sandbox_image = "registry.cn-hangzhou.aliyuncs.com/google_containers/pause:3.10"
```

### 5.6 修改默认镜像存储位置

Containerd 默认将所有数据（镜像层、容器快照、元数据等）存储在 `/var/lib/containerd`，生产环境中经常需要迁移到大容量磁盘或独立挂载点。

#### 涉及的路径

| 路径 | 默认值 | 用途 |
|------|--------|------|
| `root` | `/var/lib/containerd` | containerd 全局数据根目录（快照、元数据、临时文件） |
| `state` | `/run/containerd` | 运行时临时状态（socket、pid 等，通常无需修改） |

#### 方式一：修改顶层 `root`（一步到位，推荐）

直接修改 `config.toml` 顶层的 `root` 字段，所有数据统一迁移：

```bash
# 1. 停止 containerd
sudo systemctl stop containerd

# 2. 创建新的数据目录
sudo mkdir -p /data/containerd

# 3. 迁移现有数据（如果有）
sudo rsync -avz /var/lib/containerd/ /data/containerd/

# 4. 编辑 config.toml，修改顶层 root 字段
sudo vim /etc/containerd/config.toml
```

```toml
# 原来
root = "/var/lib/containerd"

# 改为
root = "/data/containerd"
```

```bash
# 5. 启动 containerd
sudo systemctl start containerd

# 6. 验证新路径
sudo ls /data/containerd/
sudo ctr image ls
sudo ctr image pull docker.io/library/alpine:latest
```

#### 方式二：仅修改 CRI 插件的镜像存储（细粒度控制）

如果只想改镜像存储位置而保持其他数据不变：

```toml
[plugins."io.containerd.grpc.v1.cri"]
  # CRI 插件镜像存储根目录（containerd 1.x）
  # containerd_image_store_path = "/data/containerd/images"
```

> **注意**: `containerd_image_store_path` 仅 containerd 2.x 支持。1.x 版本通过顶层 `root` 统一控制。

#### 方式三：软链接（无侵入、零停机时间最短）

不想改配置时，直接做软链接映射：

```bash
# 1. 停止 containerd
sudo systemctl stop containerd

# 2. 迁移数据到新位置
sudo mkdir -p /data/containerd
sudo rsync -avz /var/lib/containerd/ /data/containerd/

# 3. 备份原目录并创建软链接
sudo mv /var/lib/containerd /var/lib/containerd.bak
sudo ln -s /data/containerd /var/lib/containerd

# 4. 启动并验证
sudo systemctl start containerd
sudo ctr image ls
```

#### 迁移后验证

```bash
# 确认数据写到了新路径
sudo du -sh /data/containerd/
sudo ls -la /data/containerd/io.containerd.content.v1.content/

# 拉取镜像测试
sudo ctr image pull docker.io/library/redis:alpine

# 确认镜像层存到了新位置
sudo find /data/containerd -name "*.tar" | head
```

#### 清理旧路径

```bash
# 验证无误后，删除旧数据释放空间
sudo rm -rf /var/lib/containerd.bak
```

### 5.7 完整配置示例

以下是一个适用于 Kubernetes 集群的生产级 `config.toml` 模板（在默认配置基础上覆盖关键参数，其余保持默认即可）:

```toml
version = 2

[plugins."io.containerd.grpc.v1.cri"]
  sandbox_image = "registry.cn-hangzhou.aliyuncs.com/google_containers/pause:3.10"

  [plugins."io.containerd.grpc.v1.cri".containerd]

    [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
      runtime_type = "io.containerd.runc.v2"

      [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
        SystemdCgroup = true

  # 关键：指定 hosts.toml 目录，镜像加速和私有仓库配置都在这里完成
  [plugins."io.containerd.grpc.v1.cri".registry]
    config_path = "/etc/containerd/certs.d"
```

配套的 `certs.d` 目录结构（镜像加速 + 私有仓库统一管理）:

```
/etc/containerd/certs.d/
├── docker.io/
│   └── hosts.toml              # Docker Hub 镜像加速
├── registry.k8s.io/
│   └── hosts.toml              # K8s 镜像仓库加速
├── gcr.io/
│   └── hosts.toml              # GCR 镜像加速
├── quay.io/
│   └── hosts.toml              # Quay 镜像加速
└── harbor.mycorp.com/
    ├── hosts.toml              # 私有 Harbor 仓库
    └── ca.crt                  # 自签名证书
```

典型 `docker.io/hosts.toml` 示例:

```toml
server = "https://registry-1.docker.io"

[host."https://docker.m.daocloud.io"]
  capabilities = ["pull", "resolve"]
  skip_fetch_failure = true

[host."https://docker.1ms.run"]
  capabilities = ["pull", "resolve"]
  skip_fetch_failure = true
```

典型 `harbor.mycorp.com/hosts.toml` 示例:

```toml
server = "https://harbor.mycorp.com"

[host."https://harbor.mycorp.com"]
  capabilities = ["pull", "resolve", "push"]
  ca = "/etc/containerd/certs.d/harbor.mycorp.com/ca.crt"

  [host."https://harbor.mycorp.com".header]
    authorization = ["Basic <base64-credentials>"]
```



## 六、启动与管理

```bash
# 启动 containerd
sudo systemctl start containerd

# 停止 containerd
sudo systemctl stop containerd

# 重启 containerd（配置修改后执行）
sudo systemctl restart containerd

# 查看运行状态
sudo systemctl status containerd

# 设置开机自启
sudo systemctl enable containerd

# 取消开机自启
sudo systemctl disable containerd

# 查看日志
sudo journalctl -u containerd -f      # 实时跟踪
sudo journalctl -u containerd -n 100  # 最近 100 行
sudo journalctl -u containerd --since "10 minutes ago"

# 查看 containerd 版本
containerd --version
sudo ctr version
```



## 七、常用运维命令

### 7.1 ctr 命令

`ctr` 是 containerd 自带的 CLI 工具，功能全面但操作较为底层。

```bash
# ------ 镜像操作 ------

# 拉取镜像
sudo ctr image pull docker.io/library/nginx:alpine

# 列出所有镜像
sudo ctr image ls
sudo ctr image ls -q                    # 只显示镜像名

# 导出镜像
sudo ctr image export nginx-alpine.tar docker.io/library/nginx:alpine

# 导入镜像
sudo ctr image import nginx-alpine.tar

# 删除镜像
sudo ctr image rm docker.io/library/nginx:alpine

# 给镜像打标签
sudo ctr image tag docker.io/library/nginx:alpine docker.io/library/nginx:my-tag

# ------ 容器操作 ------

# 创建并运行容器
sudo ctr run -d docker.io/library/nginx:alpine my-nginx

# 列出运行中的容器
sudo ctr container ls

# 列出所有容器（含已停止）
sudo ctr container ls -a

# 查看容器详情
sudo ctr container info my-nginx

# 停止容器
sudo ctr task kill my-nginx

# 删除容器（需先停止）
sudo ctr container rm my-nginx

# ------ 任务操作 ------

# 查看运行中的任务
sudo ctr task ls

# 执行命令（类似 docker exec）
sudo ctr task exec -t --exec-id exec1 my-nginx /bin/sh

# 查看任务详情（CPU、内存等）
sudo ctr task metrics my-nginx

# ------ 命名空间操作 ------

# 查看命名空间列表
sudo ctr namespace ls

# Kubernetes 镜像存储在 k8s.io 命名空间
sudo ctr -n k8s.io image ls
sudo ctr -n k8s.io container ls
```

### 7.2 crictl 命令

`crictl` 是 Kubernetes 社区维护的 CRI 调试工具，使用方式与 docker 命令行非常接近。

```bash
# 安装 crictl
VERSION="v1.32.0"
wget https://github.com/kubernetes-sigs/cri-tools/releases/download/${VERSION}/crictl-${VERSION}-linux-amd64.tar.gz
sudo tar Cxzvf /usr/local/bin crictl-${VERSION}-linux-amd64.tar.gz

# 配置 crictl
sudo tee /etc/crictl.yaml <<EOF
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 10
debug: false
EOF
```

```bash
# ------ 镜像操作 ------
sudo crictl pull nginx:alpine            # 拉取镜像
sudo crictl images                        # 列出镜像
sudo crictl rmi <IMAGE_ID>                # 删除镜像
sudo crictl inspecti <IMAGE_ID>           # 查看镜像详情

# ------ Pod 操作 ------
sudo crictl pods                          # 列出 Pod
sudo crictl pods --all                    # 含已停止的 Pod
sudo crictl inspectp <POD_ID>             # 查看 Pod 详情
sudo crictl runp pod-config.json          # 运行 Pod（通过 PodSandbox 配置）
sudo crictl stopp <POD_ID>                # 停止 Pod
sudo crictl rmp <POD_ID>                  # 删除 Pod

# ------ 容器操作 ------
sudo crictl ps                            # 列出运行中的容器
sudo crictl ps -a                         # 列出所有容器
sudo crictl inspect <CONTAINER_ID>        # 查看容器详情
sudo crictl logs <CONTAINER_ID>           # 查看容器日志
sudo crictl logs -f <CONTAINER_ID>        # 跟踪容器日志
sudo crictl exec -it <CONTAINER_ID> /bin/sh  # 进入容器
sudo crictl stats                         # 查看容器资源使用

# ------ 综合操作 ------
sudo crictl info                          # 查看运行时信息
sudo crictl version                       # 查看版本
```

### 7.3 nerdctl 命令（推荐）

`nerdctl` 是 containerd 的类 Docker CLI 工具，对 Docker 用户非常友好。

> 安装方式见 [第 8 节](#8-安装-nerdctl类-docker-cli)

```bash
# ------ 镜像操作 ------
nerdctl pull nginx:alpine                 # 拉取镜像
nerdctl images                            # 列出镜像
nerdctl rmi nginx:alpine                  # 删除镜像
nerdctl tag nginx:alpine nginx:my-tag     # 打标签

# ------ 容器操作 ------
nerdctl run -d --name web -p 8080:80 nginx:alpine   # 运行容器
nerdctl ps                               # 列出运行中的容器
nerdctl ps -a                            # 列出所有容器
nerdctl stop web                         # 停止容器
nerdctl start web                        # 启动已停止的容器
nerdctl restart web                      # 重启容器
nerdctl rm web                           # 删除容器（需先停止）
nerdctl rm -f web                        # 强制删除容器
nerdctl exec -it web /bin/sh             # 进入容器
nerdctl logs -f web                      # 查看容器日志
nerdctl inspect web                      # 查看容器详情
nerdctl top web                          # 查看容器内进程

# ------ Compose 操作 ------
nerdctl compose up -d                    # 启动 compose 服务
nerdctl compose down                     # 停止 compose 服务
nerdctl compose ps                       # 查看 compose 服务状态
nerdctl compose logs -f                  # 查看 compose 日志

# ------ 网络操作 ------
nerdctl network ls                       # 列出网络
nerdctl network create my-net            # 创建网络
nerdctl network inspect my-net           # 查看网络详情
nerdctl network rm my-net                # 删除网络

# ------ 卷操作 ------
nerdctl volume ls                        # 列出卷
nerdctl volume create my-vol             # 创建卷
nerdctl volume inspect my-vol            # 查看卷详情
nerdctl volume rm my-vol                 # 删除卷

# ------ 系统操作 ------
nerdctl system events                    # 查看事件流
nerdctl system info                      # 查看系统信息
nerdctl system df                        # 查看磁盘使用情况
nerdctl system prune -af                 # 清理无用资源

# ------ 命名空间 ------
nerdctl -n k8s.io ps                     # 查看 k8s 命名空间的容器
nerdctl -n k8s.io images                 # 查看 k8s 命名空间的镜像
```



## 八、安装 nerdctl（类 Docker CLI）

```bash


# 1. 下载 nerdctl
NERDCTL_VERSION="2.0.4"
wget https://github.com/containerd/nerdctl/releases/download/v${NERDCTL_VERSION}/nerdctl-full-${NERDCTL_VERSION}-linux-amd64.tar.gz

# 2. 解压安装（包含 nerdctl + CNI + BuildKit + Rootless 等全套工具）
sudo tar Cxzvvf /usr/local nerdctl-full-${NERDCTL_VERSION}-linux-amd64.tar.gz

# 3. 验证安装
nerdctl version
nerdctl info


# 如果仅下载nerdctl
wget https://github.com/containerd/nerdctl/releases/download/v${NERDCTL_VERSION}/nerdctl-${NERDCTL_VERSION}-linux-amd64.tar.gz

tar -zxvf nerdctl-${NERDCTL_VERSION}-linux-amd64.tar.gz
mv nerdctl /usr/local/bin/

# 验证安装
nerdctl version
nerdctl info
```

> **提示**: `nerdctl-full` 包包含了 BuildKit（用于镜像构建）、CNI 插件等完整组件。如果只需要 CLI 工具，可仅下载 `nerdctl` 单文件。



## 九、卸载 Containerd

### 9.1 停止服务并清理数据

```bash
# 1. 停止 containerd
sudo systemctl stop containerd
sudo systemctl disable containerd

# 2. 停止所有容器
sudo ctr task ls -q | xargs -r sudo ctr task kill
# 或使用 nerdctl
# nerdctl ps -aq | xargs -r nerdctl rm -f

# 3. 删除容器和镜像数据
sudo rm -rf /var/lib/containerd

# 4. 删除配置
sudo rm -rf /etc/containerd
```

### 9.2 按安装方式卸载

**二进制安装**:

```bash
# 删除二进制文件
sudo rm -f /usr/local/bin/containerd
sudo rm -f /usr/local/bin/containerd-shim*
sudo rm -f /usr/local/bin/ctr
sudo rm -f /usr/local/bin/runc
sudo rm -f /usr/local/sbin/runc

# 删除 service 文件
sudo rm -f /usr/local/lib/systemd/system/containerd.service
sudo rm -f /etc/systemd/system/containerd.service.d/http-proxy.conf
sudo systemctl daemon-reload

# 删除 CNI 插件
sudo rm -rf /opt/cni
```

**apt 安装（Debian/Ubuntu）**:

```bash
sudo apt-get purge -y containerd.io
sudo apt-get autoremove -y
```

**yum 安装（CentOS/RHEL）**:

```bash
sudo yum remove -y containerd.io
```

### 9.3 完全清理（可选）

```bash
# 清理残留的运行时目录
sudo rm -rf /run/containerd

# 清理 socket 文件
sudo rm -f /run/containerd/containerd.sock

# 如果安装了 nerdctl
sudo rm -f /usr/local/bin/nerdctl /usr/local/bin/buildkitd /usr/local/bin/buildctl

# 清理用户级 containerd（如使用了 rootless 模式）
rm -rf ~/.local/share/containerd
```



## 十、常见问题与排错

### Q1: 拉取镜像报错 `x509: certificate signed by unknown authority`

```bash
# 原因: 私有镜像仓库证书不受信任
# 解决:
# 1. 在 config.toml 中添加 insecure_skip_verify = true（仅限测试）
# 2. 将 CA 证书安装到系统信任链
sudo cp ca.crt /usr/local/share/ca-certificates/my-ca.crt
sudo update-ca-certificates
```

### Q2: 拉取镜像报错 `dial tcp: lookup xxxx: no such host`

```bash
# 原因: DNS 解析失败
# 检查 DNS 配置
cat /etc/resolv.conf

# 在 config.toml 中确认没有错误的代理或镜像地址
sudo journalctl -u containerd | grep -i "dial"
```

### Q3: `grpc: timed out` 或 `context deadline exceeded`

```bash
# 原因: 网络超时或国内无法直连 gcr.io
# 解决: 配置镜像加速（见 5.1 节）
# 或拉取镜像时增加超时
sudo ctr image pull --timeout 300s docker.io/library/nginx:alpine
```

### Q4: cgroup 相关错误

```bash
# 检查 cgroup 驱动是否一致
# Kubernetes 推荐 systemd，containerd 也需配置 SystemdCgroup = true（见 5.4 节）

# 验证当前 cgroup 驱动
sudo ctr info | grep -i cgroup
```

### Q5: 容器无法访问网络

```bash
# 检查 CNI 插件是否安装
ls /opt/cni/bin/

# 检查 CNI 配置文件
ls /etc/cni/net.d/

# 测试网络转发
sudo sysctl net.ipv4.ip_forward

# 如果为 0，开启转发
sudo sysctl -w net.ipv4.ip_forward=1
```

### Q6: 查看 Containerd 配置是否生效

```bash
# 查看当前 containerd 运行时配置
sudo ctr info

# 重新加载配置后验证
sudo systemctl restart containerd
sudo ctr info | grep -A 20 mirrors
```

### Q7: 磁盘空间不足

```bash
# 查看 containerd 占用空间
sudo du -sh /var/lib/containerd

# 清理未使用的镜像和容器
sudo ctr image prune --all
# 或使用 nerdctl
nerdctl system prune -af
```

### Q8: 配置更新后不生效

```bash
# 确保重启了 containerd
sudo systemctl restart containerd

# 检查配置文件语法（TOML）
# 常见错误: 缺少方括号、缩进不一致
containerd config dump > /tmp/current-config.toml

# 对比默认配置和当前运行配置的差异
diff <(containerd config default) <(containerd config dump)
```



## 十一、快速参考



### 关键文件路径

| 文件/目录 | 用途 |
|-----------|------|
| `/etc/containerd/config.toml` | 主配置文件 |
| `/var/lib/containerd/` | 数据存储目录（镜像、容器层等） |
| `/run/containerd/containerd.sock` | gRPC 监听 socket |
| `/opt/cni/bin/` | CNI 插件目录 |
| `/etc/cni/net.d/` | CNI 网络配置目录 |
| `/etc/crictl.yaml` | crictl 配置文件 |



### 常用操作速查

| 操作 | 命令 |
|------|------|
| 启动服务 | `sudo systemctl start containerd` |
| 重启服务 | `sudo systemctl restart containerd` |
| 查看状态 | `sudo systemctl status containerd` |
| 查看日志 | `sudo journalctl -u containerd -f` |
| 查看版本 | `containerd --version` |
| 生成配置 | `containerd config default` |
| 拉取镜像 | `sudo ctr image pull <image>` |
| 列出镜像 | `sudo ctr image ls` |
| 运行容器 | `sudo ctr run -d <image> <name>` |
| 清理资源 | `sudo ctr image prune --all` |



### 镜像加速地址汇总

| 源仓库 | 镜像加速地址 |
|--------|-------------|
| docker.io | `https://docker.m.daocloud.io` |
| gcr.io | `https://gcr.m.daocloud.io` |
| k8s.gcr.io / registry.k8s.io | `https://k8s.m.daocloud.io` |
| quay.io | `https://quay.m.daocloud.io` |
| ghcr.io | `https://ghcr.m.daocloud.io` |
| docker.io（阿里云） | `https://<your-id>.mirror.aliyuncs.com` |
| docker.io（中科大） | `https://docker.mirrors.ustc.edu.cn` |
| docker.io（南京大学） | `https://docker.nju.edu.cn` |
