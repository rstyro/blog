---
title: K8s存储实战：从Local-Path到NFS动态存储，一篇搞定
tags: [k8s,Kubernetes]
categories: 网络运维
date: 2026-07-04 17:50:44
updated: 2026-07-04 17:50:44
---



在 Kubernetes 集群中，持久化存储是绕不开的刚需。无论是数据库的高可用，还是 AI 模型文件的共享，都离不开一个可靠的 StorageClass（存储类）。

今天这篇文章，我们将**从零开始**，先搭建轻量级的本地存储 `local-path-provisioner`，再搭建企业级共享存储 NFS，并最终在 K8s 中实现**动态存储卷分配**（PVC 自动创建 PV）。读完这篇，你就能根据业务需求灵活选择存储方案了。




好的，我在原文最前面补充了 **local-path-provisioner** 的安装使用，并在其后增加了与 NFS 的横向对比，帮你更清晰地理解两者的适用场景。以下是完整的微信公众号文章内容，你可以直接复制排版发布。



## 一、安装本地动态存储

如果你只是想快速测试，或者对读写性能要求极高且数据不需要跨节点共享，`local-path-provisioner` 是最佳选择。它由 Rancher 开源，利用节点本地的磁盘空间为 Pod 动态分配存储。



### 1.一键部署
```bash
# 安装 local-path-provisioner
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.30/deploy/local-path-storage.yaml

# 修改配置把镜像名称 rancher/local-path-provisioner:v0.0.30 改为 docker.io/rancher/local-path-provisioner:v0.0.30

# 将 local-path 设为默认 StorageClass
# 这样后续创建 PVC 时不指定 `storageClassName` 也会自动使用它
kubectl patch storageclass local-path -p '{"metadata":{"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'




# 清理相关
# 删除所有已有的 PV 和 PVC
kubectl delete pv --all 2>/dev/null || true
kubectl delete pvc --all --all-namespaces 2>/dev/null || true

# 删除旧的 local-path StorageClass
kubectl delete sc local-path --ignore-not-found=true

# 删除旧的 local-path-provisioner（Deployment + Namespace）
kubectl delete deployment local-path-provisioner -n local-path-storage --ignore-not-found=true
kubectl delete ns local-path-storage --ignore-not-found=true

```



### 2. 验证与使用
```bash
# 查看存储类
kubectl get sc

# 创建一个测试 PVC
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-local-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
EOF

# 查看状态，很快会 Bound
kubectl get pvc test-local-pvc
```

**总结**：local-path 部署极简，性能接近裸盘，但**无法跨节点读写（仅 ReadWriteOnce）**，且 Pod 漂移后数据可能丢失（除非配合节点亲和性）。这就引出了我们下面要讲的 NFS。





## 二、方案对比：Local-Path vs NFS

在选择存储方案前，我们先看一张核心对比图：

| 对比维度 | **local-path-provisioner** | **NFS (网络文件系统)** |
| :--- | :--- | :--- |
| **存储位置** | 节点本地磁盘（SSD/HDD） | 独立的远程 NFS 服务器 |
| **读写性能** | ⭐⭐⭐⭐⭐ **极高**（无网络开销） | ⭐⭐⭐ 中等（受限于网络带宽和延迟） |
| **访问模式** | 仅支持 `ReadWriteOnce`（单节点） | 支持 `ReadWriteMany`（多节点同时读写） |
| **数据持久性** | 节点故障则数据丢失（除非节点恢复） | 集中存储，节点故障不影响数据安全 |
| **适用场景** | 高性能数据库、缓存、临时计算任务 | 共享配置文件、AI 模型仓库、日志收集、跨 Pod 共享文件 |
| **维护成本** | 极低（无需额外服务器） | 需要独立维护 NFS 服务器及磁盘阵列 |

**一句话结论**： 
**追求极致性能且不需要共享**，选 `local-path`；**需要多 Pod 共享数据或做持久化模型存储**，选 `NFS`。

下面，我们就来详细搭建这套企业级 NFS 动态存储方案。



## 三、NFS 服务端安装与配置

- 我们假设你有一台节点作为 NFS 服务端（IP 示例：`192.168.32.131`）。



### 1.安装NFS



#### Ubuntu安装

```bash
sudo apt update
# 服务端需要全套，客户端只装 nfs-common
# 1. NFS 服务端（主节点）安装命令
sudo apt install -y nfs-kernel-server nfs-common rpcbind

# 2. NFS 客户端（从节点）只需要装这个
sudo apt install -y nfs-common rpcbind
```



#### Centos

```bash
# 在每个机器。
yum install -y nfs-utils
```



### 2.服务端-创建共享目录 /nfs/data

```bash
sudo mkdir -p /data/nfs-share

# 如果有权限问题-放开权限避免读写报错
# sudo chmod 777 /data/nfs-share

# 覆盖-写入共享配置 /etc/exports
# 配置 exports 文件（定义共享规则）
echo "/data/nfs-share *(insecure,rw,sync,no_root_squash)" | sudo tee /etc/exports

# *： 允许所有客户端 IP 连接
# insecure： 允许客户端使用大于 1024 的随机端口（容器 / 虚拟机必加）
# rw： 读写权限
# sync： 同步写入，数据落盘更安全
# no_root_squash： 客户端 root 用户不压缩成 nobody，拥有完整权限



# 开机自启并立刻启动 rpcbind
sudo systemctl enable --now rpcbind
# 开机自启并立刻启动 nfs 服务
sudo systemctl enable --now nfs-server


# 重载 exports 共享配置
# -r 重载，-a 全部，-v 打印详情
sudo exportfs -arv


# 防火墙放行（如开启了 UFW）
sudo ufw allow nfs
sudo ufw allow rpcbind
sudo ufw reload
```



### 3.NFS 从节点

```bash
# 先查看服务端共享（替换你的 NFS 服务端 IP 192.168.32.131）
showmount -e 192.168.32.131
# 正常输出：/data/nfs-share *


# 创建本地挂载目录
sudo mkdir -p /data/nfs-share

# 执行挂载
sudo mount -t nfs 192.168.32.131:/data/nfs-share /data/nfs-share


# 测试读写，写入测试文件
sudo echo "hello nfs server" > /data/nfs-share/test.txt
# 回到服务端 /nfs/data 下能看到 test.txt 即成功



# 开机自动永久挂载
sudo nano /etc/fstab

# 添加一行
# _netdev：代表网络文件系统，系统等网卡就绪后再挂载，防止开机报错
192.168.32.131:/data/nfs-share  /data/nfs-share  nfs defaults,_netdev 0 0




# 使上面写入生效
sudo mount -a
```



### 4. 常用运维命令（备忘）
```bash
# 重启服务
sudo systemctl restart nfs-server rpcbind
# 强制卸载（卡住时用）
sudo umount -lf /data/nfs-share
```


## 四、Kubernetes中的 NFS 动态存储卷

手动创建 PV 太原始了，我们使用官方推荐的 **nfs-subdir-external-provisioner** 控制器。它就像一个小管家，只要监听到 PVC 请求，就会自动在 NFS 共享目录下创建子目录并绑定 PV。

### 1. 通过 Helm 安装 Provisioner
```bash
# helm 安装nfs-subdir-external-provisioner

# 删除原有仓库（如有）
helm repo remove nfs-subdir-external-provisioner
# 使用国内镜像代理仓库
helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/
helm repo update

# 验证拉取
helm search repo nfs-subdir-external-provisioner
```

### 2. 准备核心配置文件 values.yaml
把默认配置导出并修改关键参数：
```bash
helm show values nfs-subdir-external-provisioner/nfs-subdir-external-provisioner > nfs-values.yaml
```

nfs-values.yaml默认字段的解释：

```yaml
# 副本数量，建议保持为 1
replicaCount: 1
# 部署策略，Recreate 表示在更新时先销毁旧 Pod 再创建新 Pod
strategyType: Recreate

image:
  # 镜像仓库地址
  repository: registry.k8s.io/sig-storage/nfs-subdir-external-provisioner
  # 镜像标签版本
  tag: v4.0.2
  # 镜像拉取策略
  pullPolicy: IfNotPresent
# 拉取私有镜像时使用的 Secret 列表
imagePullSecrets: []

nfs:
  # 【重要】NFS 服务器的 IP 地址或域名，必须填写
  server: 
  # 【重要】NFS 服务器上导出的共享目录路径
  path: /nfs-storage
  # NFS 挂载时的额外选项（例如：nolock,tcp,noresvport）
  mountOptions:
  # 主 NFS 卷的名称
  volumeName: nfs-subdir-external-provisioner-root
  # 主 NFS 卷的回收策略（Retain 表示删除 PVC 时保留底层数据）
  reclaimPolicy: Retain

# 用于自动创建 StorageClass 的配置:
storageClass:
  # 是否自动创建 StorageClass
  create: true

  # 设置 provisioner 的名称。如果未设置，将自动生成一个名称。
  # provisionerName:

  # 是否将此 StorageClass 设置为集群的默认 StorageClass
  # 如果 storageClass.create 为 false，则忽略此设置
  defaultClass: false

  # 设置 StorageClass 的名称（后续创建 PVC 时会用到这个名字）
  # 如果 storageClass.create 为 false，则忽略此设置
  name: nfs-client

  # 允许动态扩展卷的大小（需要底层存储支持）
  allowVolumeExpansion: true

  # 回收废弃卷时使用的策略（Delete 表示删除 PVC 时同时删除 NFS 上的数据）
  reclaimPolicy: Delete

  # 当设置为 true 时，在删除 PVC 时，provisioner 不会直接删除数据，而是将目录重命名归档（防止误删）
  archiveOnDelete: true

  # 如果配置了此参数且值为 'delete'，则直接删除目录；如果值为 'retain'，则保留目录。
  # 此配置会覆盖 archiveOnDelete 的设置。
  # 如果未设置值，则忽略。
  onDelete:

  # 指定一个模板，通过 PVC 的元数据（如 labels、annotations、name 或 namespace）来生成目录路径。
  # 例如：`${namespace}-${pvc.name}`。如果未设置值，则忽略。
  pathPattern:

  # 设置访问模式 - ReadWriteOnce(单节点读写), ReadOnlyMany(多节点只读) 或 ReadWriteMany(多节点读写)
  accessModes: ReadWriteOnce

  # 设置卷绑定模式 - Immediate(立即绑定) 或 WaitForFirstConsumer(等待第一个 Pod 调度时再绑定)
  volumeBindingMode: Immediate

  # StorageClass 的注解 (annotations)
  annotations: {}

leaderElection:
  # 当设置为 false 时，将禁用 Leader 选举（多副本时用于防止脑裂，单副本时通常保持开启）
  enabled: true

## RBAC 支持相关配置:
rbac:
  # 指定是否创建 RBAC 资源（Role, RoleBinding 等）
  create: true

# 如果为 true，则创建并使用 Pod Security Policy (PSP) 资源
# 注意：K8s 1.25+ 已废弃 PSP，新版集群通常不需要开启
podSecurityPolicy:
  enabled: false

# Deployment 中 Pod 的注解 (annotations)
podAnnotations: {}

## 设置 Pod 的优先级类名称
# priorityClassName: ""

# Pod 级别的安全上下文配置
podSecurityContext: {}

# 容器级别的安全上下文配置
securityContext: {}

serviceAccount:
  # 指定是否创建 ServiceAccount
  create: true

  # 添加到 ServiceAccount 的注解
  annotations: {}

  # 要使用的 ServiceAccount 的名称。
  # 如果未设置且 create 为 true，则使用 fullname 模板自动生成一个名称
  name:

# 资源限制与请求配置（建议在生产环境中开启以防 OOM）
resources: {}
  # limits:
  #  cpu: 100m
  #  memory: 128Mi
  # requests:
  #  cpu: 100m
  #  memory: 128Mi

# 节点选择器，用于将 Pod 调度到特定标签的节点上
nodeSelector: {}

# 容忍度配置，允许 Pod 调度到带有特定污点 (Taint) 的节点上
tolerations: []

# 亲和性配置（节点亲和性或 Pod 亲和性）
affinity: {}

# 为创建的所有资源添加额外的标签 (labels)
labels: {}

# Pod 中断预算 (PDB) 配置
podDisruptionBudget:
  enabled: false
  maxUnavailable: 1
```



最终我的修改 `nfs-values.yaml`，如下（其他保持默认即可）：

```yaml
# nfs-values.yaml

# 副本数量，建议保持为 1
replicaCount: 1
# 部署策略，Recreate 表示在更新时先销毁旧 Pod 再创建新 Pod
strategyType: Recreate

# 镜像配置 (如果国内拉取困难，可替换为代理镜像)
image:
  # repository: registry.k8s.io/sig-storage/nfs-subdir-external-provisioner
  # 使用华为云的镜像
  repository: swr.cn-north-4.myhuaweicloud.com/ddn-k8s/registry.k8s.io/sig-storage/nfs-subdir-external-provisioner
  tag: v4.0.2
  
nfs:
  # 替换为你的 NFS 服务器 IP
  server: 192.168.32.131
  # 替换为你的 NFS 共享路径
  path: /data/nfs-share 
  mountOptions:
    - nolock,tcp,noresvport

# 配置 StorageClass
storageClass:
  create: true
  # 是否将其设置为集群的默认 StorageClass
  defaultClass: true 
  # StorageClass 的名称，后续创建 PVC 时会用到
  name: nfs-client 
  # 回收策略：Delete (删除PVC时删除数据) 或 Retain (保留数据)
  reclaimPolicy: Delete 
  # 当设置为 true 时，在删除 PVC 时，provisioner 不会直接删除数据，而是将目录重命名归档（防止误删）
  archiveOnDelete: true
  # 允许动态扩展卷的大小（需要底层存储支持）
  allowVolumeExpansion: true
  # 设置卷绑定模式 - Immediate(立即绑定) 或 WaitForFirstConsumer(等待第一个 Pod 调度时再绑定)
  volumeBindingMode: Immediate
  # 设置访问模式 - ReadWriteOnce(单节点读写), ReadOnlyMany(多节点只读) 或 ReadWriteMany(多节点读写)
  accessModes: ReadWriteOnce
  
# 资源限制
resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 512Mi

```

> **注意**：`archiveOnDelete: true` 非常实用！删除 PVC 时不会直接删数据，而是把目录重命名归档，给运维留一条后路。

### 3. 部署到集群
```bash
# 安装
helm install nfs-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
  -f nfs-values.yaml \
  -n nfs-system \
  --create-namespace
  
  
# 修改nfs-values.yaml 后可以执行升级  
helm upgrade nfs-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
  -f nfs-values.yaml \
  -n nfs-system  
  
# 卸载
helm uninstall nfs-provisioner -n nfs-system
```

查看 Pod 是否正常运行：
```bash
kubectl get pods -n nfs-system
```

### 4. 验证动态存储是否生效
创建一个测试 PVC：
```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-pvc
spec:
  storageClassName: nfs-client   # 与上面的name一致
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
EOF
```

查看状态和自动生成的 PV：
```bash
kubectl get pvc test-pvc
kubectl get pv
```
此时去 NFS 服务端的 `/data/nfs-share` 下查看，你会发现多了一个类似 `default-test-pvc-pvc-xxxx` 的子目录——**大功告成**！



![](test.png)



## 五、结语与最佳实践建议

- **存储选型**：在 K8s 中，`local-path` 和 NFS 并不是二选一，而是**共存互补**的关系。你可以将 NFS 作为默认存储，专门给无状态应用和共享存储用；将 `local-path` 留给需要高速读写的数据库（如 etcd、Prometheus）。

- **性能调优**：如果 NFS 传输大文件（比如 AI 模型），可以在 `mountOptions` 里加上 `rsize=1048576,wsize=1048576` 提高吞吐量。

- **生产安全**：务必把 `/etc/exports` 中的 `*` 换成具体的 CIDR（如 `192.168.32.0/24`），并考虑 NFS 结合 Kerberos 加密或内网隔离。

- **故障排查三板斧**：

  - 节点上执行 `showmount -e <server_ip>` 看网络通不通。

  - K8s 中 PVC Pending 时，看 `kubectl describe pvc` 事件，并检查 `nfs-provisioner` Pod 日志。



现在，你已经具备了在 K8s 中搭建完整存储体系的能力。下一期我们将基于这套 NFS 存储，实战部署 **Harbor 私有镜像仓库** 和 **KServe AI 模型推理平台**，敬请期待！

---

如果觉得本文对你有帮助，欢迎 **点赞、在看、转发** 支持一下！有任何配置疑问，欢迎在评论区留言交流~

