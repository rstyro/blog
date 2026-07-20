---
title: KubeEdge的安装与使用
tags: [KubeEdge,k8s]
categories: 网络运维
date: 2026-07-20 18:51:20
---


## 前言

随着物联网、工业互联网、边缘AI技术的快速普及，海量终端设备产生的数据不再适合全部回传云端处理，传统中心化云计算架构面临网络带宽受限、延迟过高、离线不可用、运维成本高等痛点。边缘计算将计算、存储、网络能力下沉到业务就近的边缘节点，可有效解决上述问题。但边缘节点数量庞大、架构分散、设备异构性强，缺乏统一的编排和管理标准。

<!--more-->


Kubernetes 作为云原生编排标准，擅长云端集群资源管理，但原生并不适配边缘弱网络、低资源、离线自治的场景。**KubeEdge** 作为 CNCF 官方孵化的开源云边协同平台，完美将 Kubernetes 容器编排能力延伸至边缘场景，实现云端统一管控、边缘本地自治、终端设备统一接入，是目前工业边缘、物联网边缘、AI 边缘场景的主流开源解决方案。本文将详细介绍 KubeEdge 的核心原理、架构组成、部署安装流程及基础使用方法。



## 一、概述

KubeEdge 是面向云边协同场景的开源边缘计算框架，完全兼容 Kubernetes 原生 API，无需改动原有 K8s 运维习惯，即可实现对海量边缘节点、边缘应用、物联网终端设备的统一管理。平台打通了云端数据中心与边缘节点的通信链路，支持弱网、断网自治、轻量化部署、多协议设备接入，广泛应用于智能制造、智慧园区、车载边缘、安防视频、边缘AI推理等场景。



### 1、为什么需要KubeEdge

传统纯云端 K8s 架构无法适配边缘业务场景，存在诸多短板，而 KubeEdge 针对性解决了边缘计算的核心痛点，具体优势如下：

- **适配弱网与离线自治**：边缘网络普遍存在延迟高、抖动大、断网频繁的问题。KubeEdge 边缘节点具备本地元数据缓存能力，断网后仍可稳定运行业务、维持设备状态，网络恢复后自动同步云端数据，彻底解决断网业务中断问题。
- **极致轻量化，适配低资源边缘设备**：传统 K8s 组件臃肿、资源占用高，无法部署在树莓派、工控机、嵌入式设备等低配置边缘硬件。KubeEdge 边缘核心 EdgeCore 内存占用极低，适配 ARM、x86 多架构，兼容各类异构边缘终端。
- **云边统一管控，运维无差异**：完全兼容 Kubernetes 原生命令、CRD 资源、控制器模型，运维人员可通过云端 kubectl 统一管理成千上万的边缘节点，无需登录边缘设备操作，大幅降低大规模边缘集群运维成本。
- **原生支持物联网设备接入**：内置设备孪生、消息总线、多协议适配器，原生支持 Modbus、OPC UA、MQTT、蓝牙、摄像头等各类终端设备接入，实现“应用编排+设备管理”一体化，区别于单纯的边缘容器方案。
- **安全可靠的云边通信**：基于 WebSocket/QUIC 协议构建加密长连接隧道，支持跨内网、跨防火墙穿透，解决边缘节点内网部署、无公网 IP 的通信难题，同时保障云边数据传输安全。





## 二、核心架构

KubeEdge 采用标准的**云-边-端三层架构**，整体分为云端控制面、边缘计算面、终端设备面，云边分离、协同工作，架构解耦且扩展性极强。核心组件分为云端 CloudCore、边缘端 EdgeCore 两大核心模块，搭配自定义资源与协议适配器，实现完整的云边协同能力。



```
┌─────────────────────────────────────────┐
│              云端（Cloud）                |
│   Kubernetes + CloudCore                │
│   ├─ CloudHub       ← 云边通信网关        │
│   ├─ EdgeController ← 同步 Pod/ConfigMap │
│   └─ DeviceController← 同步设备资源      │
└────────────┬────────────────────────────┘
             │ WebSocket/QUIC 加密隧道
             ▼
┌─────────────────────────────────────────┐
│           边缘节点（Edge）                │
│   EdgeCore                              │
│   ├─ EdgeHub    ← 连接云端               │
│   ├─ Edged      ← 边缘版 kubelet        │
│   ├─ MetaManager← 本地元数据缓存          │
│   ├─ DeviceTwin ← 设备孪生               │
│   ├─ EventBus   ← 本地 MQTT 总线         │
│   └─ EdgeMesh   ← 边缘服务发现与通信       │
└────────────┬────────────────────────────┘
             │ Modbus / OPC UA / MQTT / BLE
             ▼
┌─────────────────────────────────────────┐
│           终端设备（Device）              │
│   摄像头 / 温湿度传感器 / PLC / 扫码器      │
└─────────────────────────────────────────┘
```





### 1、云端组件（CloudCore）

云端组件部署在标准 Kubernetes 集群中，作为整个边缘集群的控制平面，负责资源调度、节点管理、设备管控、消息转发，核心组件如下：

- **CloudHub**：云端核心网关组件，是云边通信的唯一入口，负责与所有边缘节点的 EdgeHub 建立加密长连接，转发云端指令与边缘状态数据，支持 Websocket/QUIC 双协议。
- **EdgeController**：边缘资源控制器，监听 K8s 原生资源（Deployment、ConfigMap、Service 等），将资源变更同步至对应边缘节点，实现云端统一下发应用。
- **DeviceController**：设备管理控制器，监听设备自定义资源（Device、DeviceModel），负责终端设备的注册、状态同步、权限管控，实现云端统一管理物联网设备。



| 组件 | 作用 | 类比 |
| --- | --- | --- |
| **CloudHub** | 云边通信的唯一入口，维护与所有 EdgeHub 的长连接 | 像 VPN 网关 |
| **EdgeController** | 监听 Deployment、ConfigMap、Secret 等资源，同步到边缘 | 像边缘资源的"快递员" |
| **DeviceController** | 监听 Device、DeviceModel 等自定义资源，同步设备状态 | 像设备管家 |



### 2、边缘端组件（EdgeCore）

边缘端以单二进制文件 EdgeCore 为核心，部署在所有边缘节点，无需完整 K8s 集群，轻量化且高可用，内置多个核心子模块：

- **EdgeHub**：边缘通信客户端，主动与云端 CloudCore 建立隧道连接，上报边缘节点状态、设备数据，接收云端调度指令与资源配置。
- **Edged**：轻量化边缘 kubelet，替代原生 kubelet，负责边缘节点 Pod 管理、容器生命周期调度、资源监控，兼容 K8s 原生容器规范。
- **MetaManager**：边缘离线自治核心模块，本地缓存 K8s 元数据、配置文件、设备状态，断网时独立维持业务运行，网络恢复后自动增量同步云端数据。
- **DeviceTwin**：设备孪生模块，缓存终端设备的状态、属性、配置，实现设备状态云端镜像同步，支持云端下发设备控制指令、边缘上报设备异常。
- **EventBus**：边缘本地消息总线，内置轻量 MQTT 服务，负责本地设备数据、业务消息的发布与订阅，支撑边缘本地数据流转。
- **EdgeMesh**：边缘服务网格，实现边缘节点内部、跨边缘节点的服务发现与通信，替代 kube-proxy，降低边缘资源消耗。



| 组件 | 作用 |
| --- | --- |
| **EdgeHub** | 主动连上 CloudHub，上报心跳、接收指令 |
| **Edged** | 边缘版 kubelet，负责拉镜像、起 Pod、管容器生命周期 |
| **MetaManager** | 把 Pod、ConfigMap 等数据存在本地数据库，断网时也能用 |
| **DeviceTwin** | 维护设备状态镜像，云端改配置，边缘自动同步给设备 |
| **EventBus** | 内置 MQTT broker，本地应用和设备之间可 pub/sub 消息 |
| **EdgeMesh** | 边缘服务发现与负载均衡，替代 kube-proxy |



### 3、 终端接入层

KubeEdge 不直接对接五花八门的硬件协议，而是通过 **Mapper** 适配器统一接入：

- Modbus-Mapper：工业 PLC、传感器
- OPC-UA-Mapper：数控机床、智能制造设备
- MQTT-Mapper：物联网传感器
- Bluetooth-Mapper：蓝牙设备
- 摄像头 Mapper：视频流、AI 推理

一个摄像头或温湿度传感器，在 KubeEdge 里会被映射成 `Device` 和 `DeviceModel` 两种 CRD 资源，你可以用 `kubectl get device` 查看它。



## 三、安装

可采用 KubeEdge 官方推荐的 **keadm 工具** 快速部署，部署分为环境准备、云端部署、边缘节点接入三步，适配主流 Linux 系统，部署简单、稳定性高。



### 1、环境前置要求

#### 我的测试环境

- 资源有限，就弄了2个服务器



| 角色     | IP            | 说明                            |
| -------- | ------------- | ------------------------------- |
| 云端节点 | `10.12.5.160` | 已安装 K8s 集群，运行 CloudCore |
| 边缘节点 | `10.12.5.161` | 运行 EdgeCore，加入云端集群     |

> 你可以把 IP 替换成自己的实际地址。



![](edge-version.png)




#### 云端节点（控制面）

- 操作系统：Ubuntu 20.04+/CentOS 7+
- 已部署正常运行的 Kubernetes 1.20+ 集群
- 已安装 `kubectl`，`~/.kube/config` 可用
- 防火墙放行：
  - `10000/tcp`：CloudHub 端口，边缘节点接入用
  - `10002/tcp`：证书端口，边缘节点首次注册用
  - `10003/tcp`（可选）：EdgeMesh 使用
  - `10004/tcp`（可选）：Tunnel 端口



检查集群状态：

```bash
kubectl get nodes
kubectl get pods -n kube-system
```



#### 边缘节点（业务面）

- 操作系统：Ubuntu 20.04+/ARM 嵌入式系统
- 已安装 containerd/docker 容器运行时
- 时间与云端同步（建议配置 NTP）
- 能访问云端 `10000` 和 `10002` 端口
- 关闭或配置好防火墙，避免拦截云边通信





### 2、安装keadm工具

KubeEdge 官方提供了一键部署工具 **keadm**，能自动完成：下载组件、生成证书、部署 CloudCore、生成 join token、接入边缘节点。



在**云端节点**和**边缘节点**都要安装 keadm。



```bash
# 安装keadm,可访问https://github.com/kubeedge/kubeedge/releases 下载最新版
wget https://github.com/kubeedge/kubeedge/releases/download/v1.22.1/keadm-v1.22.1-linux-amd64.tar.gz

# 解压并移动到/usr/local/bin 方便使用
tar -zxvf keadm-v1.22.1-linux-amd64.tar.gz
cp keadm-v1.22.1-linux-amd64/keadm/keadm /usr/local/bin/keadm

# 验证安装
keadm version
```



### 3、云端初始化（部署CloudCore）

在 K8s 主控节点执行初始化命令，自动创建 kubeedge 命名空间、部署云端核心组件、生成通信证书。

```bash
# 初始化云端 CloudCore
# --advertise-address 填边缘节点能通的 master 内网 IP：10.12.5.160
# --image-repository 镜像仓库前缀，网络慢时换国内镜像
keadm init \
  --advertise-address=10.12.5.160 \
  --kubeedge-version=v1.22.1 \
  --kube-config=/root/.kube/config \
  --image-repository=docker.m.daocloud.io/kubeedge

```



![](edge-init.png)





执行完成后，记录边缘节点接入 Token，用于后续边缘节点注册：

```bash
# 获取边缘接入token
keadm gettoken
```



等待云端组件全部启动，确认 Pod 运行正常：

```bash
kubectl get pods -n kubeedge
```



### 4、边缘节点接入集群

在所有边缘节点执行接入命令，替换为上方获取的 Token 与云端节点 IP，完成边缘节点注册。

```bash
# 边缘节点接入集群

# 防止下载镜像超时，可以提前下载
crictl pull kubeedge/installation-package:v1.22.1

# 加入云端节点，通过 keadm join -h 查看各个参数
# --cloudcore-ipport 对应cloudcore的10000端口
# -i, --edgenode-name 是自定义加入节点的名称，唯一即可
# --certport 对应cloudcore的10002端口
# --tarballpath 这个是kubeedge压缩包的地址（可提前从github下载包，会自动下载）
# --token 就是从上面 keadm gettoken 获取的
keadm join  --cloudcore-ipport=10.12.5.160:10000 \
-i edge01 \
--certport=10002 \
--kubeedge-version=v1.22.1 \
--tarballpath="/root/k8s/kubeedge/" \
--token="da99622c850b34fc0af1df75fa6e22a10abf4b11720b49b7e6aa6031231119d5.eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3ODQ2MTcxNDh9.eUE_9KF9s9f_i7et-G50QgJvn2UYuo24ttYfE7oV5YY
" 

```



![](edge-join.png)





### 5、CNI网络问题

在 KubeEdge 边缘节点上，CNI（容器网络接口）需要特殊处理，主要有两件事要做：

- **禁止 calico-node 调度到边缘节点**：因为边缘节点资源有限且网络环境不同，通常不在边缘跑 calico。
- **为边缘节点配置独立的桥接网络**：当边缘节点不走 kube-proxy 时，需要一个轻量级的 CNI 插件来给 Pod 分配 IP。



#### ①、禁止 calico-node 调度到边缘节点
云端 K8s 集群通常装了 Calico，它的 `calico-node` DaemonSet 默认会在所有节点上跑。边缘节点不需要 calico-node，而且低配硬件也跑不动。

通过给 calico-node DaemonSet 添加反亲和，让它**跳过带有 `node-role.kubernetes.io/edge` 标签的节点**：

```bash
kubectl patch daemonset calico-node -n kube-system --type='merge' -p '
{
  "spec": {
    "template": {
      "spec": {
        "affinity": {
          "nodeAffinity": {
            "requiredDuringSchedulingIgnoredDuringExecution": {
              "nodeSelectorTerms": [
                {
                  "matchExpressions": [
                    {
                      "key": "node-role.kubernetes.io/edge",
                      "operator": "DoesNotExist"
                    }
                  ]
                }
              ]
            }
          }
        }
      }
    }
  }
}'
```

> 前提：你已经给边缘节点打过 `node-role.kubernetes.io/edge=` 标签。打完标签后 calico-node 的 Pod 就不会再调度到边缘节点了。
> 



#### ②、 为边缘节点配置桥接网络（bridge CNI）

当边缘节点不依赖 kube-proxy 做服务发现时，Pod 之间的网络需要一个 CNI 插件来接管。边缘场景下最常见也最轻量的方案是 **bridge 模式**：在一台宿主机上，把所有 Pod 都挂到一个 Linux 网桥 `cni0` 上，通过 host-local IPAM 给每个 Pod 分配 IP，并用 NAT 让 Pod 访问外部网络。

**Step 1：进入 CNI 配置目录**

```bash
cd /etc/cni/net.d/
```

**Step 2：创建 bridge 配置文件**

新建文件 `10-kubeedge-bridge.conflist`，写入以下内容：

```json
{
  "cniVersion": "1.0.0",
  "name": "kubeedge-bridge",
  "plugins": [
    {
      "type": "bridge",
      "bridge": "cni0",
      "isGateway": true,
      "ipMasq": true,
      "promiscMode": true,
      "ipam": {
        "type": "host-local",
        "ranges": [
          [
            {
              "subnet": "10.88.0.0/16"
            }
          ]
        ],
        "routes": [
          {
            "dst": "0.0.0.0/0"
          }
        ]
      }
    },
    {
      "type": "portmap",
      "capabilities": {
        "portMappings": true
      }
    },
    {
      "type": "firewall"
    },
    {
      "type": "tuning"
    }
  ]
}
```

各字段的含义：

| 字段 | 说明 |
| --- | --- |
| `type: bridge` | 使用 Linux bridge 作为网络后端 |
| `bridge: cni0` | 创建的网桥名称 |
| `isGateway: true` | 把 `cni0` 网桥当作 Pod 的默认网关 |
| `ipMasq: true` | 自动做 SNAT，让 Pod 能访问外网 |
| `promiscMode: true` | 开启混杂模式，确保所有报文都能正常转发 |
| `ipam.type: host-local` | IP 地址管理方式，每台宿主机本地分配 |
| `subnet: 10.88.0.0/16` | Pod 的 CIDR 地址段（按自己网络规划调整） |
| `routes.dst: 0.0.0.0/0` | Pod 默认路由，指向宿主机 |
| `portmap` 插件 | 支持 Pod `hostPort` 端口映射 |
| `firewall` 插件 | 自动添加 iptables 规则，保证网络安全 |
| `tuning` 插件 | 调优内核网络参数（如 `sysctl` 配置） |

**Step 3：重启 containerd 使配置生效**

```bash
systemctl restart containerd
```

> 如果边缘节点之前残留了 calico 的 CNI 配置文件（如 `10-calico.conflist`），记得先把它备份移除（改后缀为 `.bkb` 或不以 `.conflist` 结尾），否则多个配置冲突可能导致 Pod 网络异常。




### 6、安装验证

回到云端 K8s 节点，查看边缘节点状态，状态为 Ready 即部署成功

```bash
kubectl get nodes
```

此时云端可统一管控所有边缘节点，云边通道建立完成，具备应用部署、设备管理、离线自治能力。



![](edge-nodes.png)






## 四、使用

KubeEdge 完全兼容 K8s 原生操作方式，核心使用场景分为边缘应用部署、边缘节点管理、物联网设备管理三大模块。



### 1、边缘应用部署

通过原生 K8s 资源清单，为边缘节点部署业务应用，可通过节点标签调度应用至指定边缘节点。

#### ①、为边缘节点打标签

在 KubeEdge 中，**标签（Label）** 和 **污点（Taint）** 配合使用，可以让云端应用精准调度到边缘节点，同时防止非边缘应用误调度过来。



| 概念 | 作用 | 类比 |
| --- | --- | --- |
| Label | 标记节点的身份和用途，供 `nodeSelector` / `nodeAffinity` 匹配 | 给节点贴"工牌" |
| Taint + Toleration | 拒绝不符合条件的 Pod 调度上来，只有声明了对应 Toleration 的 Pod 才能容忍该节点 | 给节点加"门禁" |

常见的边缘调度策略是：**打一个 Label 让边缘应用找到节点，再打一个 NoSchedule Taint 挡住非边缘应用。**

##### Step 1：打标签

```bash
# 标记为边缘节点（空值即可，后续用于 nodeSelector 匹配）
kubectl label node edge01 node-role.kubernetes.io/edge=

# 查看标签是否生效
kubectl get node edge01 --show-labels
```

这两条打完，`node-role.kubernetes.io/edge` 标签会显示在节点信息中，Deployment 可通过它做调度匹配。

##### Step 2：打污点（可选但推荐）

如果希望**只有显式声明了 Toleration 的 Pod 才能调度到边缘节点**，加上 NoSchedule 污点：

```bash
# 添加污点：effect=NoSchedule 表示不满足条件的 Pod 一律拒绝
kubectl taint node edge01 node-role.kubernetes.io/edge=true:NoSchedule --overwrite
```

> `--overwrite` 是防止节点上已有同名 key 的污点导致命令失败。

这样一来，普通 Deployment 不会误调到边缘节点；而边缘应用只需在 YAML 中加上对应的 Toleration。



##### Step 3：在 Deployment 中配合使用

边缘应用的 Deployment 需要同时声明 `nodeSelector`（选择节点）和 `tolerations`（容忍污点）：

```yaml
spec:
  template:
    spec:
      nodeSelector:
        node-role.kubernetes.io/edge: ""
      tolerations:
        - key: "node-role.kubernetes.io/edge"
          operator: "Equal"
          value: "true"
          effect: "NoSchedule"
      containers:
        - name: my-edge-app
          image: my-edge-app:v1
```

##### 附：如何移除污点

如果后续不再需要污点隔离，用 `-` 后缀移除：

```bash
# 移除指定污点
kubectl taint node edge01 node-role.kubernetes.io/edge:NoSchedule-
```





#### ②、编写边缘yaml：指定节点调度

在调度规则中匹配边缘节点标签，实现应用精准下发至边缘运行。部署方式与原生 K8s 完全一致。

以下是一个完整的边缘 Deployment，保存为 `edge-demo.yaml`：

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-edge
  labels:
    app: nginx-edge
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx-edge
  template:
    metadata:
      labels:
        app: nginx-edge
    spec:
      # 选择边缘节点
      nodeSelector:
        node-role.kubernetes.io/edge: ""
      # 容忍边缘节点污点
      tolerations:
        - key: "node-role.kubernetes.io/edge"
          operator: "Equal"
          value: "true"
          effect: "NoSchedule"
      containers:
        - name: nginx
          image: nginx:alpine
          ports:
            - containerPort: 80
              hostPort: 8080 # 宿主机端口监听
          resources:
            requests:
              cpu: 100m
              memory: 128Mi
            limits:
              cpu: 200m
              memory: 256Mi
```



> **关键点**：`nodeSelector` 让 Pod 调度到边缘节点；`tolerations` 让 Pod 能容忍之前打的 NoSchedule 污点。两者缺一不可。

```bash
# 部署应用
kubectl apply -f edge-demo.yaml
```



![](edge-ip.png)



因为我的edge01的ip是`10.12.5.161`,直接访问：`http://10.12.5.161:8080` 测试



![](edge-nginx.png)




#### ③、查看边缘应用状态

```bash
# 查看 Pod 分布（确认调度到 edge01）
kubectl get pods -o wide

# 查看 Pod 详细信息（事件、状态、分配节点）
kubectl describe pod nginx-edge-xxx

# 查看边缘节点资源与分配的 Pod
kubectl describe node edge01

# 查看节点上的实时资源使用（需安装 metrics-server）
kubectl top node edge01
kubectl top pod -A --field-selector spec.nodeName=edge01
```

部署成功后，你会在 `kubectl get pods -o wide` 的 `NODE` 列看到 `edge01`，说明应用已经精准下发到了边缘节点。





### 2、云边远程运维

依托 KubeEdge 隧道能力，云端可直接远程操作边缘节点 Pod，无需登录边缘设备：

```bash
# 查看日志
kubectl logs nginx-edge-xxx

# 进入容器
kubectl exec -it nginx-edge-xxx -- /bin/sh
```



> 如果提示需要开启 `kubectl logs` 功能，云端需要额外配置 `cloudStream` 和 `tunnel` 相关端口（10003/10004）。



### 3、物联网设备管理

KubeEdge 把设备抽象成两种 CRD：

- **DeviceModel**：设备模型，定义一类设备有哪些属性（Property）
- **Device**：具体设备实例，绑定到某个边缘节点

#### ①、创建设备模型（定义设备属性、协议）

通过 DeviceModel 统一规范同类设备的参数、读写属性、通信协议。

#### ②、创建设备实例（绑定边缘节点）

将物理设备绑定至指定边缘节点，通过对应协议 Mapper 实现设备接入，接入后可在云端查看设备在线状态、实时数据。

#### ③、查看设备状态

```bash
# 查看所有设备模型
kubectl get devicemodels

# 查看所有边缘设备
kubectl get devices
```



### 4、离线自治验证

断开边缘节点网络，边缘节点原有业务 Pod、设备状态不会中断，业务正常运行；恢复网络后，边缘节点自动向云端同步离线期间的所有数据与状态变更，无需人工干预。


**测试方法：**

1. 在 edge01 上部署一个持续运行的业务 Pod。
2. 在云端 `kubectl get pods` 确认运行正常。
3. 断开 edge01 的网络（如拔掉网线、关闭网卡、阻断到云端的连接）。
4. 在边缘节点上执行：

```bash
crictl ps
```

你会发现业务容器**仍然正常运行**。

5. 恢复网络后，边缘节点自动 reconnect 到云端，并同步离线期间的状态变化，无需人工干预。

> 注意：云端新下发的 Pod 在断网期间无法同步到边缘；但**已经在边缘上运行的业务**会保持不变。






### 5、集群卸载与清理



```bash
# 边缘节点卸载
keadm reset edge

# 卸载云端 CloudCore
keadm reset cloud

# 如果 keadm reset 没有清理干净，手动删除残留资源：
kubectl delete deploy cloudcore -n kubeedge
kubectl delete svc cloudcore -n kubeedge
kubectl delete cm cloudcore -n kubeedge
kubectl delete secret cloudcore -n kubeedge

# 删除 kubeedge 命名空间（包含所有相关资源）
kubectl delete ns kubeedge
```



## 五、常见问题与排错



### 1、边缘节点 join 失败

检查以下几点：

- Token 是否复制完整，是否已过期（重新 `keadm gettoken`）
- 边缘节点能否访问云端的 `10000` 和 `10002` 端口
- 云端防火墙是否放行
- 云端 CloudCore Pod 是否 Running

```bash
# 测试连通性
nc -vz 10.12.5.160 10000
nc -vz 10.12.5.160 10002
```

### 2、edgecore 启动失败

查看日志定位原因：

```bash
# 查看edgecore实时日志
journalctl -u edgecore -f

journalctl -u edgecore -n 200 --no-pager

# 重启
systemctl restart edgecore
```

常见问题：

- 容器运行时没装好（containerd/docker）
- cgroup 驱动与 docker/containerd 不一致
- `/etc/kubeedge/config/edgecore.yaml` 配置错误

### 3、kubectl logs/exec 不能用

需要在云端启用 `cloudStream` 和 `tunnel` 端口，并确保边缘能访问云端的 `10003`、`10004` 端口。配置后重启 CloudCore 和 EdgeCore。



## 六、最后




| 要点 | 说明 |
| --- | --- |
| KubeEdge 是什么 | 面向边缘计算的 Kubernetes 扩展，云边协同平台 |
| 核心优势 | 轻量化、离线自治、云边统一管控、物联网设备原生接入 |
| 核心组件 | 云端 CloudCore + 边缘 EdgeCore + Mapper |
| 部署方式 | keadm 一键部署，分云端 init 和边缘 join 两步 |
| 使用方式 | 基本沿用 kubectl，应用部署、设备管理都通过 K8s CRD |
| 适合场景 | 智能制造、智慧园区、车载边缘、安防视频、边缘 AI 推理 |

掌握 KubeEdge 后，你就能用一套云原生技术栈，把 Kubernetes 的管理能力延伸到千千万万的边缘节点和终端设备上。