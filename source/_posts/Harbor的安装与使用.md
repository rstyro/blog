---
title: Harbor的安装与使用
tags: [k8s,Harbor,Kubernetes]
categories: 网络运维
date: 2026-07-08 20:08:52
updated: 2026-07-09 20:08:52
---


## 一、为什么需要 Harbor

### 1.1 Docker Hub 的痛点

Docker Hub 是公共镜像仓库，企业大规模使用时会遇到以下问题：

- **网络限制**：拉取镜像慢、不稳定，生产环境不可控
- **安全风险**：公共镜像来源不明，可能包含漏洞或恶意代码
- **合规要求**：金融、政务等行业要求镜像必须存储在境内或内部
- **版本管理缺失**：无法按项目、团队、环境进行细粒度权限控制
- **拉取次数限制**：Docker Hub 对匿名和免费账户有拉取配额

<!--more-->

### 1.2 私有镜像仓库的选择

| 方案 | 定位 | 特点 |
| --- | --- | --- |
| Docker Registry | 基础镜像存储 | 官方开源，功能单一，无 UI |
| Harbor | 企业级镜像仓库 | 图形界面、权限管理、漏洞扫描、镜像复制、签名验证 |
| Nexus | 通用制品库 | 支持 Maven、npm、Docker 等多种制品 |
| Quay / ACR / TCR | 商业/云厂商 | 开箱即用，按量付费 |

**选型建议**：

- 团队规模小、只需要存储镜像 → Docker Registry
- 需要权限管理、扫描、审计、多仓库同步 → **Harbor**
- 已经有 Nexus 管理 Java/NPM 制品 → 可直接复用 Nexus 的 Docker 仓库
- 不想自建、预算充足 → 云厂商容器镜像服务

### 1.3 Harbor 能解决什么问题

- **镜像私有化**：将业务镜像统一存储在公司内部
- **权限隔离**：按项目划分命名空间，控制谁可以推送/拉取
- **漏洞扫描**：集成 Trivy，扫描镜像中的 OS/应用漏洞
- **镜像复制**：跨机房、跨云同步镜像，构建多活/灾备
- **签名与可信**：支持 Notation / Cosign 镜像签名，防止镜像被篡改
- **审计与合规**：记录推送、拉取、删除操作日志






## 二、Harbor 是什么

### 2.1 官方定义

Harbor 是一个开源的**云原生制品仓库（Cloud Native Registry）**，用于存储、签名和扫描容器镜像、Helm Chart、OCI Artifact 等云原生制品。

它由 VMware 开源，现为 CNCF 孵化项目，地址：[https://goharbor.io](https://goharbor.io)

### 2.2 支持的制品类型

Harbor 基于 OCI（Open Container Initiative）规范，支持：

- Docker 镜像
- Helm Chart
- OCI Artifact（如 SBOM、签名包）
- CNAB（Cloud Native Application Bundle）

### 2.3 与 Docker Registry 的关系

Harbor 底层基于 Docker Distribution（即 Docker Registry v2）实现镜像的 blob 存储，但在此基础上增加了：

- Web UI（Portal）
- 用户与权限系统
- 数据库元数据管理
- 异步任务调度（Jobservice）
- 漏洞扫描适配器
- 多仓库复制
- 镜像签名验证

可以理解为：**Harbor = Docker Registry + 企业级管理平台**

---

## 三、Harbor 核心架构

### 3.1 数据分层模型

很多坑其实源于没想清楚 Harbor 的**数据分层**。它不是一个单体，而是把"元数据"和"镜像 blob"拆成了两层：

| 层级 | 组件 | 存什么 | 是否状态 | 说明 |
| --- | --- | --- | --- | --- |
| 接入层 | Nginx / Ingress | TLS 终止、路由转发 | 无 | 无状态时可以多副本 |
| 服务层 | Portal / Core / Jobservice | API、UI、异步任务 | **无**（可多副本） | Core 是核心 API 网关 |
| 安全层 | Trivy（Scanner） | 漏洞扫描 | 无 | 扫描结果元数据进 PG |
| 镜像层 | Registry + RegistryCTL | 镜像 blob 实际存储 | **有** | 需要持久化，多副本需共享存储 |
| 元数据层 | PostgreSQL | 项目/用户/镜像索引/审计日志 | **有** | 核心状态库，建议外部高可用 |
| 缓存层 | Redis | 会话、Job 队列、Token | **有** | 建议外部 Redis/Sentinel |

**关键理解**：

- **无状态层**（Portal/Core/Jobservice/Trivy）可以随时水平扩展
- **有状态层**（Registry 存储、PG、Redis）必须保证数据持久化和高可用
- 生产环境尽量使用**外部 PostgreSQL + 外部 Redis + 共享对象存储/SAN**

### 3.2 核心组件职责

| 组件 | 职责 |
| --- | --- |
| **nginx** | 反向代理，统一入口，处理 TLS、静态资源、路由 |
| **portal** | Harbor Web UI，基于 Angular 开发 |
| **core** | 核心业务服务，提供 REST API，处理认证、权限、项目管理、Webhook 等 |
| **jobservice** | 异步任务调度，负责镜像复制、垃圾回收、扫描、保留策略等 |
| **registry** | 基于 Docker Distribution，负责镜像 blob 的推拉 |
| **registryctl** | Registry 的管理面，执行垃圾回收等操作 |
| **trivy-adapter** | 漏洞扫描适配器，调用 Trivy 扫描镜像 |
| **postgresql** | 元数据库，存储用户、项目、仓库、Artifact、审计日志等 |
| **redis** | 缓存会话、任务队列、镜像层缓存索引 |
| **exporter** | Prometheus 指标导出器 |

### 3.3 请求流转示意

```
Docker Client / Browser
         │
         ▼
    Nginx / Ingress  ←── TLS 终止
         │
    ┌────┴────┐
    ▼         ▼
  Portal     Core API
    │         │
    │    ┌────┴────┐
    │    ▼         ▼
    │  Registry   PostgreSQL
    │    │           │
    │    ▼           ▼
    │  镜像 Blob    Redis 缓存
    │
    ▼
  Jobservice ──→ Trivy / 复制目标 / GC
```

---

## 四、安装 Harbor

### 4.1 安装前准备

#### 4.1.1 硬件要求（生产参考）

| 规模 | CPU | 内存 | 存储 | 说明 |
| --- | --- | --- | --- | --- |
| 测试环境 | 2 核 | 4 GB | 50 GB | 单节点即可 |
| 小型生产 | 4 核 | 8 GB | 200 GB+ | 建议外部数据库 |
| 中大型生产 | 8 核+ | 16 GB+ | 1 TB+ | 必须外部 PG/Redis + 对象存储 |

#### 4.1.2 软件依赖

- Docker 20.10+（Docker Compose 方式）
- Docker Compose v2.0+（Docker Compose 方式）
- Kubernetes 1.24+（Helm 方式）
- Helm 3.12+
- 可解析的域名（推荐）
- 有效 TLS 证书（生产环境）

#### 4.1.3 网络规划

- 确定 Harbor 的访问域名，例如 `harbor.example.com`
- 确定暴露方式：Ingress / NodePort / LoadBalancer / ClusterIP
- 确定镜像推拉端口：HTTPS 默认 443，HTTP 默认 80
- 如果走 NodePort，客户端 tag 和 login 时必须带端口

### 4.2 方案一：Docker Compose 安装

适用于单节点测试、小型环境或快速验证。

#### 4.2.1 下载离线安装包

```bash
# 下载离线包（包含所有镜像）
wget https://github.com/goharbor/harbor/releases/download/v2.15.2/harbor-offline-installer-v2.15.2.tgz

# 解压
tar xzf harbor-offline-installer-v2.15.2.tgz && cd harbor
```

#### 4.2.2 配置文件

```bash
# 复制模板
cp harbor.yml.tmpl harbor.yml
```

最小化配置示例：

```yaml
# 访问域名
hostname: harbor.example.com

# HTTP 端口
http:
  port: 80

# HTTPS 端口（生产必须启用）
https:
  port: 443
  certificate: /your/path/harbor.crt
  private_key: /your/path/harbor.key

# 管理员初始密码
harbor_admin_password: Harbor12345

# 数据库密码
database:
  password: root123
  max_idle_conns: 100
  max_open_conns: 900

# 数据持久化目录
data_volume: /data

# 日志配置
log:
  level: info
  local:
    rotate_count: 50
    rotate_size: 200M
    location: /var/log/harbor
```

#### 4.2.3 执行安装

```bash
# 标准安装
./install.sh

# 安装时启用 Trivy 扫描
./install.sh --with-trivy

# 如果后续需要启用其他组件，重新配置后执行
./prepare
```

#### 4.2.4 常用管理命令

```bash
# 停止 Harbor
docker compose -f docker-compose.yml down

# 启动 Harbor
docker compose -f docker-compose.yml up -d

# 查看服务状态
docker compose -f docker-compose.yml ps

# 查看日志
docker compose -f docker-compose.yml logs -f core
```

### 4.3 方案二：Kubernetes Helm 安装

适用于生产环境，便于扩展、升级和高可用。

#### 4.3.1 添加仓库

```bash
helm repo add harbor https://helm.goharbor.io
helm repo update

# 查看可用版本
helm search repo harbor/harbor --versions | head -20
```



![](harbor1.png)



#### 4.3.2 导出默认配置

```bash
helm show values harbor/harbor > harbor-values.yaml
```

harbor-values.yaml内容很多，后面会有篇章讲配置解释，下面是我测试使用的一个配置：



```yaml
# ---------------------- 服务暴露配置 ----------------------
expose:
  # 服务暴露方式：可选 ingress / clusterIP / nodePort / loadBalancer / route
  # 生产环境建议使用 ingress 或 loadBalancer
  type: ingress

  tls:
    # 是否启用 TLS（生产环境必须启用）
    enabled: true
    # TLS 证书来源：auto（自动生成）/ secret（从 Secret 读取）/ none（不使用）
    # 生产环境建议使用 cert-manager 自动签发或手动创建 Secret
    certSource: auto
    auto:
      # 自动生成证书时的通用名称（若 type 不是 ingress，则必须指定）
      commonName: ""  # 通常留空，由 Ingress 规则决定
    secret:
      # 若 certSource 为 secret，指定包含 tls.crt 和 tls.key 的 Secret 名称
      secretName: ""

  ingress:
    hosts:
      # 【需修改】Harbor 核心服务的域名（必须与 externalURL 一致）
      core: harbor.rstyro.com
    # Ingress 控制器类型，默认 default 适用于大多数
    controller: default
    # IngressClass 名称（K8s 1.18+ 支持）
    className: "higress"  # 若使用 nginx-ingress，可指定为：nginx
    annotations:
      # 强制 HTTPS 重定向（根据控制器调整）
      ingress.kubernetes.io/ssl-redirect: "true"
      ingress.kubernetes.io/proxy-body-size: "0"
      nginx.ingress.kubernetes.io/ssl-redirect: "true"
      nginx.ingkubernetes.io/proxy-body-size: "0"
      # 【建议】NFS 场景下可增加超时配置
      nginx.ingress.kubernetes.io/proxy-read-timeout: "600"
      nginx.ingress.kubernetes.io/proxy-send-timeout: "600"
    labels: {}

  # 其他暴露方式（clusterIP/nodePort/loadBalancer/route）均未启用，保持默认

# ---------------------- 外部访问 URL ----------------------
# 【需修改】Harbor 对外访问的完整 URL（必须与 ingress hosts 一致）
externalURL: https://harbor.rstyro.com
# ---------------------- CA 证书 Secret ----------------------
caSecretName: ""  # 若需提供自定义 CA 证书供下载，可指定

# ---------------------- 持久化存储配置 ----------------------
persistence:
  enabled: true
  # 生产环境务必设置为 "keep"，防止误执行 helm uninstall 导致数据丢失
  resourcePolicy: "keep"
  
  persistentVolumeClaim:
    # Registry 镜像存储 (需要多副本共享，必须使用 ReadWriteMany)
    registry:
      existingClaim: ""
      # 指定 NFS 的 StorageClass
      storageClass: "nfs-client"
      subPath: "harbor/registry"
      # NFS 必须使用 RWX 以支持多副本同时读写
      accessMode: ReadWriteMany 
      size: 50Gi
    jobservice:
      jobLog:
        storageClass: "nfs-client"
        subPath: "harbor/jobservice"
        accessMode: ReadWriteMany
        size: 5Gi
    trivy:
      # Trivy 漏洞库缓存，多副本必须共享
      storageClass: "nfs-client"
      subPath: "harbor/trivy"
      accessMode: ReadWriteMany
      size: 5Gi

# ---------------------- 管理员密码 ----------------------
# 【需修改】初始管理员密码（部署后请立即修改）
harborAdminPassword: "Rstyro168"


# ---------------------- 日志级别 ----------------------
logLevel: info  # 生产环境可设为 warn 或 error 减少日志量



# ---------------------- 加密密钥 ----------------------
# 16 字符字符串，用于加密敏感数据。生产环境务必修改！
secretKey: "a1b2c3d4e5f6g7h8"  # 【需修改】


# ---------------------- 代理设置（如需） ----------------------
proxy:
  httpProxy:
  httpsProxy:
  noProxy: 127.0.0.1,localhost,.local,.internal
  components: []  # 留空表示所有组件都不使用代理

# ---------------------- Metrics 监控 ----------------------
metrics:
  enabled: false
  core:
    path: /metrics
    port: 8001
  registry:
    path: /metrics
    port: 8001
  jobservice:
    path: /metrics
    port: 8001
  exporter:
    path: /metrics
    port: 8001

# 自动创建 Prometheus ServiceMonitor (需集群已安装 Prometheus Operator)
serviceMonitor:
  enabled: false
  additionalLabels: {}
  interval: "30s"


# =============================================================================
# 各组件独立配置
# =============================================================================


# ---------------------- Portal（Web UI） ----------------------
portal:
  image:
    repository: docker.io/goharbor/harbor-portal
    tag: v2.15.1
  replicas: 1
  resources:
    requests:
      memory: 256Mi
      cpu: 100m
    limits:
      memory: 512Mi
      cpu: 200m
  # 探针保持默认

# ---------------------- Core（核心服务） ----------------------
core:
  image:
    repository: docker.io/goharbor/harbor-core
    tag: v2.15.1
  replicas: 1  # 生产建议多副本
  resources:
    requests:
      memory: 512Mi
      cpu: 200m
    limits:
      memory: 1Gi
      cpu: 500m

# ---------------------- Jobservice（任务调度） ----------------------
jobservice:
  image:
    repository: docker.io/goharbor/harbor-jobservice
    tag: v2.15.1
  replicas: 1
  resources:
    requests:
      memory: 512Mi
      cpu: 200m
    limits:
      memory: 1Gi
      cpu: 500m


# ---------------------- Registry（镜像存储） ----------------------
registry:
  registry:
    image:
      repository: docker.io/goharbor/registry-photon
      tag: v2.15.1
    resources:
      requests:
        memory: 256Mi
        cpu: 100m
      limits:
        memory: 1Gi
        cpu: 500m
  controller:
    image:
      repository: docker.io/goharbor/harbor-registryctl
      tag: v2.15.1
    resources:
      requests:
        memory: 256Mi
        cpu: 100m
      limits:
        memory: 512Mi
        cpu: 200m
  replicas: 1
  credentials:
    username: "harbor_registry_user"
    password: "harbor_registry_password"  # 【可自己修改】

# ---------------------- Trivy（漏洞扫描） ----------------------
trivy:
  enabled: true
  image:
    repository: docker.io/goharbor/trivy-adapter-photon
    tag: v2.15.1
  replicas: 1
  resources:
    requests:
      memory: 512Mi
      cpu: 200m
    limits:
      memory: 2Gi
      cpu: 1

  skipUpdate: true
  # DB 仓库镜像地址（国内可替换）
  dbRepository:
    - "mirror.gcr.io/aquasec/trivy-db"
    - "ghcr.io/aquasecurity/trivy-db"
  javaDBRepository:
    - "mirror.gcr.io/aquasec/trivy-java-db"
    - "ghcr.io/aquasecurity/trivy-java-db"


# ---------------------- 数据库 ----------------------
# 警告：多副本环境下，内置数据库无法使用 NFS 共享，必须使用外部高可用数据库
database:
  type: internal  # 使用内置 PostgreSQL
  internal:
    image:
      repository: docker.io/goharbor/harbor-db
      tag: v2.15.1
    resources:
      requests:
        memory: 512Mi
        cpu: 200m
      limits:
        memory: 1Gi
        cpu: 500m
    password: "rstyro"  # 【需修改】数据库超级用户密码

# ---------------------- Redis ----------------------
redis:
  type: internal  # 使用内置 Redis
  internal:
    image:
      repository: docker.io/goharbor/redis-photon
      tag: v2.15.1
    resources:
      requests:
        memory: 256Mi
        cpu: 100m
      limits:
        memory: 512Mi
        cpu: 200m

# ---------------------- Exporter（指标导出） ----------------------
exporter:
  image:
    repository: docker.io/goharbor/harbor-exporter
    tag: v2.15.1
  replicas: 1
  resources:
    requests:
      memory: 128Mi
      cpu: 50m
    limits:
      memory: 256Mi
      cpu: 100m
```

- 我这个存储配置使用了NFS动态分配，默认StorageClass为: `nfs-client`  NFS的安装与配置可参考我之前的文章
- 然后ingress 的实现使用的是Higress，也可以使用ingress-nginx只是不维护就想着换一个
- 还有tls这里使用 `auto` 证书有效期一年做测试够用了，后面会有篇章讲 `certSource: secret` 的



#### 4.3.3 创建命名空间并安装

```bash
# 创建命名空间
kubectl create ns harbor

# 安装命令
helm install harbor harbor/harbor -n harbor -f harbor-values.yaml
```

安装成功之后，还要安装ingress的控制器，ingress的控制器有很多，我上面配置使用的是higress,我们查看一下它的网关地址

![](harbor-ingress.png)

可以看到，443映射30145端口，所以我们就可以通过 `域名:30145` 进行访问，higress会通过域名自动进行代理



![](harbor-login.png)



账号密码就是之前配置文件里面harborAdminPassword设置的：`Rstyro168`



![](harbor-view.png)



具体的仓库如何上传镜像和下载镜像看后面的章节



#### 4.3.4 升级与卸载

```bash
# 升级配置
helm upgrade harbor harbor/harbor -n harbor -f harbor-values.yaml

# 卸载（保留 PVC，除非 persistence.resourcePolicy 不是 keep）
helm uninstall harbor -n harbor

# 彻底清理数据（危险操作）
kubectl delete pvc -n harbor --all
kubectl delete namespace harbor
```





### 4.4 两种方案对比

| 维度 | Docker Compose | Helm on Kubernetes |
| --- | --- | --- |
| 适用场景 | 测试、单节点、小团队 | 生产、大规模、高可用 |
| 扩展性 | 垂直扩展为主 | 水平扩展、多副本 |
| 高可用 | 需要手动配置 | 原生支持 |
| 运维复杂度 | 低 | 中 |
| 存储方式 | 本地目录/NFS | PVC / 对象存储 |
| 升级方式 | 重新执行 install.sh | helm upgrade |

**生产强烈推荐 Helm + 外部 PG/Redis + 对象存储/SAN 共享存储。**



## 五、配置解析与生产建议

### 5.1 默认 values 配置总体模板

- 方便查询参考

```yaml
# 对外暴露服务配置
expose:
  # 设置服务暴露方式：可选 ingress / clusterIP / nodePort / loadBalancer / route
  # 选对应类型后填写下方对应模块参数
  type: ingress
  tls:
    # 是否开启TLS加密
    # 若关闭TLS且type为ingress，需删除 ingress.annotations 里的 ssl-redirect 注解
    # 关闭TLS时，推拉镜像命令必须带上端口号
    enabled: true
    # TLS证书来源：auto(自动生成) / secret(读取已有密钥) / none(不配置证书，由Ingress控制器提供默认证书)
    certSource: auto
    auto:
      # 自动生成证书时使用的通用域名，非ingress暴露模式必填
      commonName: ""
    secret:
      # 存放证书的Secret名称，Secret内必须包含两个key：
      # tls.crt：证书文件、tls.key：私钥文件
      secretName: ""
  ingress:
    hosts:
      core: core.harbor.domain # Harbor访问域名
    # Ingress控制器类型，大部分控制器保持default即可
    # gce：GCE ingress控制器 | ncp：NSX-T容器插件 | alb：AWS ALB | f5-bigip：F5负载均衡
    controller: default
    # 覆盖自动创建Ingress时读取的K8s版本号
    kubeVersionOverride: ""
    # 指定IngressClass名称，空则使用集群默认
    className: ""
    annotations:
      # 不同Ingress控制器强制HTTPS跳转注解不同
      # Envoy使用：ingress.kubernetes.io/force-ssl-redirect: "true"，并删除nginx相关两行
      ingress.kubernetes.io/ssl-redirect: "true"
      # 取消请求体大小限制，0代表无上限
      ingress.kubernetes.io/proxy-body-size: "0"
      nginx.ingress.kubernetes.io/ssl-redirect: "true"
      nginx.ingress.kubernetes.io/proxy-body-size: "0"
    # Ingress自定义标签
    labels: {}
  # Gateway API HTTPRoute配置（K8s网关API）
  route:
    labels: {}
    annotations: {}
    # 关联上层Gateway网关资源
    parentRefs: []
      # - name: envoy-internal
      #   namespace: networking
      #   sectionName: https
      #   group: gateway.networking.k8s.io
      #   kind: Gateway
    # 路由绑定域名列表
    hosts: []
      # - "harbor.example.com"
  # ClusterIP 内部服务暴露模式
  clusterIP:
    # ClusterIP服务名称
    name: harbor
    # 固定静态内网IP，留空则自动分配
    staticClusterIP: ""
    ports:
      # HTTP服务端口
      httpPort: 80
      # HTTPS服务端口
      httpsPort: 443
    # Service注解
    annotations: {}
    labels: {}
  # NodePort 节点端口暴露模式
  nodePort:
    name: harbor
    ports:
      http:
        port: 80        # 容器内部服务端口
        nodePort: 30002 # 宿主机对外端口
      https:
        port: 443
        nodePort: 30003
    annotations: {}
    labels: {}
  # LoadBalancer 云厂商负载均衡模式
  loadBalancer:
    name: harbor
    # 固定公网IP（仅支持指定IP的LB）
    IP: ""
    ports:
      httpPort: 80
      httpsPort: 443
    annotations: {}
    labels: {}
    # 允许访问的客户端IP段白名单
    sourceRanges: []

# Harbor对外访问完整地址，用途：
# 1. 页面展示docker/helm推拉命令
# 2. 向docker客户端返回token服务地址
# 格式：协议://域名[:端口]
# 1. ingress模式：域名等于expose.ingress.hosts.core
# 2. clusterIP模式：域名等于expose.clusterIP.name
# 3. nodePort模式：域名填写集群节点IP
# 若前端有代理，填写代理访问地址
externalURL: https://core.harbor.domain

# 持久化存储配置
persistence:
  enabled: true # 开启持久化存储
  # helm delete时PVC保留策略：keep保留，空则自动删除
  # 内部数据库/redis的PVC不受此控制，永远不会自动删除
  resourcePolicy: "keep"
  persistentVolumeClaim:
    # 镜像仓库存储PVC
    registry:
      # 使用已有PVC（需提前手动创建），共享PVC时指定subPath子目录隔离数据
      existingClaim: ""
      # 存储类名称，空使用集群默认SC；填"-"关闭动态存储分配
      storageClass: ""
      subPath: ""
      accessMode: ReadWriteOnce # 读写权限（单节点挂载）
      size: 5Gi # 存储容量
      annotations: {}
    # 任务日志存储PVC
    jobservice:
      jobLog:
        existingClaim: ""
        storageClass: ""
        subPath: ""
        accessMode: ReadWriteOnce
        size: 1Gi
        annotations: {}
    # 数据库PVC（使用外部数据库时该配置失效）
    database:
      existingClaim: ""
      storageClass: ""
      subPath: ""
      accessMode: ReadWriteOnce
      size: 1Gi
      annotations: {}
    # Redis缓存PVC（使用外部Redis时该配置失效）
    redis:
      existingClaim: ""
      storageClass: ""
      subPath: ""
      accessMode: ReadWriteOnce
      size: 1Gi
      annotations: {}
    # 漏洞扫描工具Trivy存储PVC
    trivy:
      existingClaim: ""
      storageClass: ""
      subPath: ""
      accessMode: ReadWriteOnce
      size: 5Gi
      annotations: {}
  # 镜像/Chart底层存储后端配置
  imageChartStorage:
    # 是否关闭存储重定向；MinIO S3存储必须设为true关闭
    disableredirect: false
    # 存储服务自签证书时，指定存放CA根证书的Secret（key为ca.crt）
    # caBundleSecretName:
    # 存储类型：filesystem本地PVC / azure/gcs/s3/swift/oss对象存储
    # 使用PVC持久化必须选 filesystem
    type: filesystem
    filesystem:
      rootdirectory: /storage # 容器内存储根目录
      #maxthreads: 100
    # 阿里云OSS存储配置
    azure:
      accountname: accountname
      accountkey: base64encodedaccountkey
      container: containername
      #realm: core.windows.net
      # 使用已有Secret存储密钥，Secret内key为AZURE_STORAGE_ACCESS_KEY
      existingSecret: ""
    # GCS谷歌云存储
    gcs:
      bucket: bucketname
      # base64编码的密钥JSON文件
      encodedkey: base64-encoded-json-key-file
      #rootdirectory: /gcs/object/name/prefix
      #chunksize: "5242880"
      # 已有Secret存储密钥，key为GCS_KEY_DATA
      existingSecret: ""
      useWorkloadIdentity: false
    # S3兼容对象存储（MinIO、AWS S3）
    s3:
      # 已有Secret存放AK/SK，Secret内key：REGISTRY_STORAGE_S3_ACCESSKEY / REGISTRY_STORAGE_S3_SECRETKEY
      #existingSecret: ""
      region: us-west-1
      bucket: bucketname
      #accesskey: awsaccesskey
      #secretkey: awssecretkey
      #regionendpoint: http://myobjects.local # 私有S3地址
      #encrypt: false
      #keyid: mykeyid
      #secure: true
      #skipverify: false # 跳过证书校验
      #v4auth: true
      #chunksize: "5242880"
      #rootdirectory: /s3/object/name/prefix
      #storageclass: STANDARD
      #multipartcopychunksize: "33554432"
      #multipartcopymaxconcurrency: 100
      #multipartcopythresholdsize: "33554432"
    # OpenStack Swift存储
    swift:
      authurl: https://storage.myprovider.com/v3/auth
      username: username
      password: password
      container: containername
      # 已有Secret密钥key：REGISTRY_STORAGE_SWIFT_PASSWORD / REGISTRY_STORAGE_SWIFT_SECRETKEY / REGISTRY_STORAGE_SWIFT_ACCESSKEY
      existingSecret: ""
      #region: fr
      #tenant: tenantname
      #tenantid: tenantid
      #domain: domainname
      #domainid: domainid
      #trustid: trustid
      #insecureskipverify: false
      #chunksize: 5M
      #prefix:
      #secretkey: secretkey
      #accesskey: accesskey
      #authversion: 3
      #endpointtype: public
      #tempurlcontainerkey: false
      #tempurlmethods:
    # 阿里云OSS存储
    oss:
      accesskeyid: accesskeyid
      accesskeysecret: accesskeysecret
      region: regionname
      bucket: bucketname
      # 已有Secret密钥key：REGISTRY_STORAGE_OSS_ACCESSKEYSECRET
      existingSecret: ""
      #endpoint: endpoint
      #internal: false # 是否使用内网OSS节点
      #encrypt: false
      #secure: true
      #chunksize: 10M
      #rootdirectory: rootdirectory

# Harbor管理员初始密码
# 生产环境建议使用已有Secret存储密码，避免明文
existingSecretAdminPassword: ""
existingSecretAdminPasswordKey: HARBOR_ADMIN_PASSWORD
harborAdminPassword: "Harbor12345"

# Harbor内部组件间通信加密TLS（组件内部HTTPS）
internalTLS:
  enabled: false # 默认关闭
  strong_ssl_ciphers: false # 是否启用高强度加密套件
  # 证书来源：auto自动生成 / manual手动填写证书内容 / secret读取Secret证书
  certSource: "auto"
  # 信任根CA内容，仅certSource=manual时生效
  trustCa: ""
  # core组件证书配置
  core:
    secretName: ""
    crt: ""
    key: ""
  # 任务服务证书
  jobservice:
    secretName: ""
    crt: ""
    key: ""
  # 镜像仓库证书
  registry:
    secretName: ""
    crt: ""
    key: ""
  # 前端页面证书
  portal:
    secretName: ""
    crt: ""
    key: ""
  # 漏洞扫描组件证书
  trivy:
    secretName: ""
    crt: ""
    key: ""

# IP双栈配置
ipFamily:
  ipv6:
    enabled: true # 开启IPv6
  ipv4:
    enabled: true # 开启IPv4
  # Service IP分配策略，用于双栈集群
  policy: ""
  # Service支持的IP协议栈，顺序为ClusterIP分配优先级，可选IPv4/IPv6
  families: []

# 镜像拉取策略
imagePullPolicy: IfNotPresent

# 全局默认镜像拉取私有仓库密钥
imagePullSecrets:
#  - name: docker-registry-secret
#  - name: internal-registry-secret

# 带持久化存储的组件更新策略（jobservice/registry）
# RollingUpdate滚动更新；RWM多节点读写不支持时改为Recreate重建
updateStrategy:
  type: RollingUpdate

# 日志级别：debug / info / warning / error / fatal
logLevel: info

# 存放全局CA根证书的Secret（key=ca.crt），自动证书场景无需配置
caSecretName: ""

# 全局加密密钥，必须16位字符
secretKey: "not-a-secure-key"
# 使用已有Secret存储全局密钥，Secret内key为secretKey
existingSecretSecretKey: ""

# 代理配置：漏洞库更新、跨仓库镜像同步走代理
proxy:
  httpProxy:
  httpsProxy:
  noProxy: 127.0.0.1,localhost,.local,.internal # 不走代理地址
  components: # 使用代理的组件
    - core
    - jobservice
    - trivy

# 通过Helm钩子执行数据库迁移任务
#设为 true 可在 Helm 升级时先启动独立 Job 执行数据库迁移，成功后才会更新 Core 等组件，迁移失败则中止升级，保障生产环境平滑升级。
enableMigrateHelmHook: false

# 自定义全局可信CA证书Secret，所有组件自动信任该CA
# caBundleSecretName: ""

## UAA第三方认证配置（自签证书场景需提供CA）
# uaaSecretName:

# 监控指标配置
metrics:
  enabled: false # 关闭指标采集
  core:
    path: /metrics
    port: 8001
  registry:
    path: /metrics
    port: 8001
  jobservice:
    path: /metrics
    port: 8001
  exporter:
    path: /metrics
    port: 8001
  # 自动创建Prometheus ServiceMonitor（需提前安装Prometheus Operator CRD）
  serviceMonitor:
    enabled: false
    additionalLabels: {}
    interval: "" # 采集间隔，空使用Prometheus全局默认
    metricRelabelings: [] # 指标过滤重命名规则
    relabelings: [] # 标签重写规则

# 链路追踪配置
trace:
  enabled: false # 关闭追踪
  provider: jaeger # 追踪后端：jaeger / otel
  sample_rate: 1 # 采样率1=100%全量采集，0.5=50%
  # namespace: # 区分多套Harbor实例标识
  # attributes: # 自定义追踪标签
  #   application: harbor
  jaeger:
    # 两种模式：collector直连 / agent本地代理
    endpoint: http://hostname:14268/api/traces
    # username:
    # password:
    # agent_host: hostname
    # agent_port: 6831
  otel:
    endpoint: hostname:4318
    url_path: /v1/traces
    compression: false
    insecure: true # 不启用TLS
    timeout: 10 # 超时秒数

# 缓存层配置（高并发拉取镜像加速，缓存项目/仓库/镜像元数据）
cache:
  enabled: false # 默认关闭
  expireHours: 24 # 缓存过期时长24小时

## 容器安全上下文，适配PSP严格安全策略
containerSecurityContext:
  privileged: false # 关闭特权容器
  allowPrivilegeEscalation: false # 禁止权限提升
  seccompProfile:
    type: RuntimeDefault # 使用运行时默认seccomp策略
  runAsNonRoot: true # 非root用户运行
  capabilities:
    drop:
      - ALL # 删除所有Linux内核权限

# 使用Ingress暴露服务时，Nginx组件不会部署
nginx:
  image:
    repository: docker.io/goharbor/nginx-photon
    tag: v2.15.1
  serviceAccountName: "" # 自定义SA账号
  automountServiceAccountToken: false # 不自动挂载SA令牌
  replicas: 1 # 副本数
  podDisruptionBudget:
    enabled: false # 关闭Pod中断预算
    minAvailable: 1
  revisionHistoryLimit: 10 # 保留历史版本数
  # resources: # 资源配额
  #  requests:
  #    memory: 256Mi
  #    cpu: 100m
  extraEnvVars: [] # 额外环境变量
  nodeSelector: {} # 节点选择器
  tolerations: [] # 污点容忍
  affinity: {} # 亲和性调度
  topologySpreadConstraints: [] # 拓扑域打散调度
  podAnnotations: {} # Pod注解
  podLabels: {} # Pod标签
  priorityClassName: # 优先级类
  # 存活探针
  livenessProbe:
    initialDelaySeconds: 300
    periodSeconds: 10
    timeoutSeconds: 1
    failureThreshold: 3
    successThreshold: 1
  # 就绪探针
  readinessProbe:
    initialDelaySeconds: 1
    periodSeconds: 10
    timeoutSeconds: 1
    failureThreshold: 3
    successThreshold: 1

# 前端门户组件
portal:
  image:
    repository: docker.io/goharbor/harbor-portal
    tag: v2.15.1
  serviceAccountName: ""
  automountServiceAccountToken: false
  replicas: 1
  podDisruptionBudget:
    enabled: false
    minAvailable: 1
  revisionHistoryLimit: 10
  # resources:
  #  requests:
  #    memory: 256Mi
  #    cpu: 100m
  extraEnvVars: []
  nodeSelector: {}
  tolerations: []
  affinity: {}
  topologySpreadConstraints: []
  podAnnotations: {}
  podLabels: {}
  serviceAnnotations: {} # Service注解
  priorityClassName:
  livenessProbe:
    initialDelaySeconds: 300
    periodSeconds: 10
    timeoutSeconds: 1
    failureThreshold: 3
    successThreshold: 1
  readinessProbe:
    initialDelaySeconds: 1
    periodSeconds: 10
    timeoutSeconds: 1
    failureThreshold: 3
    successThreshold: 1
  initContainers: [] # 初始化容器

# Harbor核心业务组件
core:
  image:
    repository: docker.io/goharbor/harbor-core
    tag: v2.15.1
  serviceAccountName: ""
  automountServiceAccountToken: false
  replicas: 1
  podDisruptionBudget:
    enabled: false
    minAvailable: 1
  revisionHistoryLimit: 10
  # 启动探针（慢启动服务等待就绪）
  startupProbe:
    enabled: true
    initialDelaySeconds: 10
    periodSeconds: 10
    timeoutSeconds: 1
    failureThreshold: 360
    successThreshold: 1
  livenessProbe:
    initialDelaySeconds: 0
    periodSeconds: 10
    timeoutSeconds: 1
    failureThreshold: 2
    successThreshold: 1
  readinessProbe:
    initialDelaySeconds: 0
    periodSeconds: 10
    timeoutSeconds: 1
    failureThreshold: 2
    successThreshold: 1
  # resources:
  #  requests:
  #    memory: 256Mi
  #    cpu: 100m
  extraEnvVars: []
  nodeSelector: {}
  tolerations: []
  affinity: {}
  topologySpreadConstraints: []
  podAnnotations: {}
  podLabels: {}
  serviceAnnotations: {}
  priorityClassName:
  initContainers: []
  # 自定义用户页面配置JSON
  configureUserSettings:
  # 项目容量统计更新后端：db数据库 / redis缓存（高并发推送场景推荐redis）
  quotaUpdateProvider: db
  # 组件间通信密钥，16位字符，空则helm自动生成
  secret: ""
  # 使用已有Secret存储通信密钥
  existingSecret: ""
  # Token加密自定义证书Secret
  secretName: ""
  # 手动自定义RSA密钥与证书（二选一填写或全部留空自动生成）
  tokenKey: |
  tokenCert: |
  # XSRF跨站请求伪造密钥，必须32位字符，空自动生成
  xsrfKey: ""
  existingXsrfSecret: ""
  existingXsrfSecretKey: CSRF_KEY
  # 镜像拉取计数异步刷新间隔（秒），默认10秒
  artifactPullAsyncFlushDuration:
  gdpr:
    deleteUser: false # 是否开启用户数据彻底删除
    auditLogsCompliant: false # 审计日志合规模式

# 异步任务服务（镜像同步、扫描、垃圾回收）
jobservice:
  image:
    repository: docker.io/goharbor/harbor-jobservice
    tag: v2.15.1
  replicas: 1
  podDisruptionBudget:
    enabled: false
    minAvailable: 1
  revisionHistoryLimit: 10
  serviceAccountName: ""
  automountServiceAccountToken: false
  # resources:
  #   requests:
  #     memory: 256Mi
  #     cpu: 100m
  livenessProbe:
    initialDelaySeconds: 300
    periodSeconds: 10
    timeoutSeconds: 1
    failureThreshold: 3
    successThreshold: 1
  readinessProbe:
    initialDelaySeconds: 20
    periodSeconds: 10
    timeoutSeconds: 1
    failureThreshold: 3
    successThreshold: 1
  extraEnvVars: []
  nodeSelector: {}
  tolerations: []
  affinity: {}
  topologySpreadConstraints:
  podAnnotations: {}
  podLabels: {}
  priorityClassName:
  initContainers: []
  maxJobWorkers: 10 # 最大并发任务工作线程
  # 任务日志输出方式：file文件 / database数据库 / stdout标准输出
  jobLoggers:
    - file
  loggerSweeperDuration: 14 # 日志自动清理周期（天）
  notification:
    webhook_job_max_retry: 3 # Webhook最大重试次数
    webhook_job_http_client_timeout: 3 # Webhook请求超时秒
  reaper:
    max_update_hours: 24 # 任务超过24小时未更新标记失败
    max_dangling_hours: 168 # 闲置任务最大存活时长7天
  # 组件通信密钥
  secret: ""
  existingSecret: ""
  existingSecretKey: JOBSERVICE_SECRET
  registryHttpClientTimeout: 30 # 镜像仓库请求超时（分钟）

# 镜像仓库存储组件
registry:
  registry:
    image:
      repository: docker.io/goharbor/registry-photon
      tag: v2.15.1
    # resources:
    #  requests:
    #    memory: 256Mi
    #    cpu: 100m
    extraEnvVars: []
    livenessProbe:
      initialDelaySeconds: 300
      periodSeconds: 10
      timeoutSeconds: 1
      failureThreshold: 3
      successThreshold: 1
    readinessProbe:
      initialDelaySeconds: 1
      periodSeconds: 10
      timeoutSeconds: 1
      failureThreshold: 3
      successThreshold: 1
  controller:
    image:
      repository: docker.io/goharbor/harbor-registryctl
      tag: v2.15.1
    # resources:
    #  requests:
    #    memory: 256Mi
    #    cpu: 100m
    extraEnvVars: []
    livenessProbe:
      initialDelaySeconds: 300
      periodSeconds: 10
      timeoutSeconds: 1
      failureThreshold: 3
      successThreshold: 1
    readinessProbe:
      initialDelaySeconds: 1
      periodSeconds: 10
      timeoutSeconds: 1
      failureThreshold: 3
      successThreshold: 1
  serviceAccountName: ""
  automountServiceAccountToken: false
  replicas: 1
  podDisruptionBudget:
    enabled: false
    minAvailable: 1
  revisionHistoryLimit: 10
  nodeSelector: {}
  tolerations: []
  affinity: {}
  topologySpreadConstraints: []
  podAnnotations: {}
  podLabels: {}
  priorityClassName:
  initContainers: []
  # 仓库上传状态加密密钥，16位字符
  secret: ""
  existingSecret: ""
  existingSecretKey: REGISTRY_HTTP_SECRET
  relativeurls: false # 是否返回相对路径URL
  # 仓库内部账户认证
  credentials:
    username: "harbor_registry_user"
    password: "harbor_registry_password"
    existingSecret: ""
    # 固定htpasswd加密字符串，避免helm每次渲染生成不同密钥
    htpasswdString: ""
  # 云厂商CDN中间件（CloudFront）
  middleware:
    enabled: false
    type: cloudFront
    cloudFront:
      baseurl: example.cloudfront.net
      keypairid: KEYPAIRID
      duration: 3000s
      ipfilteredby: none
      privateKeySecret: "my-secret"
  # 上传碎片自动清理
  upload_purging:
    enabled: true
    age: 168h # 超过7天的碎片删除
    interval: 24h # 清理执行间隔24小时
    dryrun: false # 是否仅打印日志不实际删除

# Trivy漏洞扫描器
trivy:
  enabled: true # 开启镜像漏洞扫描
  image:
    repository: docker.io/goharbor/trivy-adapter-photon
    tag: v2.15.1
  serviceAccountName: ""
  automountServiceAccountToken: false
  replicas: 1
  podDisruptionBudget:
    enabled: false
    minAvailable: 1
  # 资源配额
  resources:
    requests:
      cpu: 200m
      memory: 512Mi
    limits:
      cpu: 1
      memory: 1Gi
  livenessProbe:
    initialDelaySeconds: 5
    periodSeconds: 10
    timeoutSeconds: 1
    failureThreshold: 10
    successThreshold: 1
  readinessProbe:
    initialDelaySeconds: 5
    periodSeconds: 10
    timeoutSeconds: 1
    failureThreshold: 3
    successThreshold: 1
  extraEnvVars: []
  nodeSelector: {}
  tolerations: []
  affinity: {}
  topologySpreadConstraints: []
  podAnnotations: {}
  podLabels: {}
  priorityClassName:
  initContainers: []
  debugMode: false # 调试日志模式
  vulnType: "os,library" # 扫描漏洞类型：系统包/应用库
  severity: "UNKNOWN,LOW,MEDIUM,HIGH,CRITICAL" # 扫描漏洞等级
  ignoreUnfixed: false # 是否只展示已修复漏洞
  insecure: false # 跳过仓库证书校验
  # GitHub访问令牌，GitHub匿名IP的API请求限60次/小时，使用Token认证后可提至5000次/小时。
  gitHubToken: ""
  skipUpdate: false # 关闭自动下载漏洞库（离线环境开启）
  skipJavaDBUpdate: false # 关闭Java漏洞库自动更新
  # 漏洞库镜像仓库（多镜像降级重试）
  dbRepository:
    - "mirror.gcr.io/aquasec/trivy-db"
    - "ghcr.io/aquasecurity/trivy-db"
  javaDBRepository:
    - "mirror.gcr.io/aquasec/trivy-java-db"
    - "ghcr.io/aquasecurity/trivy-java-db"
  offlineScan: false # 离线扫描模式（不联网解析依赖）
  securityCheck: "vuln" # 安全检测类型
  timeout: 5m0s # 单次扫描超时5分钟

# 数据库配置（内置PostgreSQL/外部数据库）
database:
  type: internal # internal内置库 / external外部独立PG
  internal:
    image:
      repository: docker.io/goharbor/harbor-db
      tag: v2.15.1
    serviceAccountName: ""
    automountServiceAccountToken: false
    # resources:
    #  requests:
    #    memory: 256Mi
    #    cpu: 100m
    livenessProbe:
      initialDelaySeconds: 300
      periodSeconds: 10
      timeoutSeconds: 1
      failureThreshold: 3
      successThreshold: 1
    readinessProbe:
      initialDelaySeconds: 1
      periodSeconds: 10
      timeoutSeconds: 1
      failureThreshold: 3
      successThreshold: 1
    extraEnvVars: []
    nodeSelector: {}
    tolerations: []
    affinity: {}
    priorityClassName:
    extrInitContainers: []
    password: "changeit" # PG超级管理员密码
    shmSizeLimit: 512Mi # PG共享内存大小
    initContainer:
      migrator: {}
      permissions: {}
  # 外部PostgreSQL配置
  external:
    host: "192.168.0.1"
    port: "5432"
    username: "user"
    password: "password"
    coreDatabase: "registry" # Harbor业务库名
    existingSecret: ""
    sslmode: "disable" # SSL连接模式：disable/require/verify-ca/verify-full
  maxIdleConns: 100 # 空闲连接池上限
  maxOpenConns: 900 # 最大并发连接数
  podAnnotations: {}
  podLabels: {}

# Redis缓存配置（内置/外部Redis）
redis:
  type: internal # internal内置 / external外部Redis
  internal:
    image:
      repository: docker.io/goharbor/redis-photon
      tag: v2.15.1
    serviceAccountName: ""
    automountServiceAccountToken: false
    # resources:
    #  requests:
    #    memory: 256Mi
    #    cpu: 100m
    livenessProbe:
      initialDelaySeconds: 300
      periodSeconds: 10
      timeoutSeconds: 1
      failureThreshold: 3
      successThreshold: 1
    readinessProbe:
      initialDelaySeconds: 1
      periodSeconds: 10
      timeoutSeconds: 1
      failureThreshold: 3
      successThreshold: 1
    extraEnvVars: []
    nodeSelector: {}
    tolerations: []
    affinity: {}
    priorityClassName:
    initContainers: []
    # Redis分库索引
    jobserviceDatabaseIndex: "1"
    registryDatabaseIndex: "2"
    trivyAdapterIndex: "5"
  # 外部Redis/Redis哨兵
  external:
    addr: "192.168.0.2:6379" # 哨兵填写多节点逗号分隔
    sentinelMasterSet: "" # 哨兵主库名称
    tlsOptions:
      enable: false # Redis连接开启TLS
    coreDatabaseIndex: "0"
    jobserviceDatabaseIndex: "1"
    registryDatabaseIndex: "2"
    trivyAdapterIndex: "5"
    username: "" # Redis ACL用户名
    password: ""
    existingSecret: ""
  podAnnotations: {}
  podLabels: {}

# 监控指标导出器
exporter:
  image:
    repository: docker.io/goharbor/harbor-exporter
    tag: v2.15.1
  serviceAccountName: ""
  automountServiceAccountToken: false
  replicas: 1
  podDisruptionBudget:
    enabled: false
    minAvailable: 1
  revisionHistoryLimit: 10
  # resources:
  #  requests:
  #    memory: 256Mi
  #    cpu: 100m
  livenessProbe:
    initialDelaySeconds: 300
    periodSeconds: 10
    timeoutSeconds: 1
    failureThreshold: 3
    successThreshold: 1
  readinessProbe:
    initialDelaySeconds: 30
    periodSeconds: 10
    timeoutSeconds: 1
    failureThreshold: 3
    successThreshold: 1
  extraEnvVars: []
  podAnnotations: {}
  podLabels: {}
  nodeSelector: {}
  tolerations: []
  affinity: {}
  topologySpreadConstraints: []
  priorityClassName:
  cacheDuration: 23 # 指标缓存时长
  cacheCleanInterval: 14400 # 缓存清理间隔（秒）
```

### 5.2 TLS 与证书配置详解

TLS 是 Harbor 最容易出问题的环节。理解证书信任链是排查 401、x509 错误的关键。

#### 5.2.1 TLS 核心配置块

```yaml
expose:
  type: ingress
  tls:
    enabled: true
    certSource: secret # 切换为读取自有tls secret
    auto:
      commonName: "" # auto模块完全失效，留空
    secret:
      secretName: "harbor-rstyro-tls" # 自定义Secret名称，下文创建时保持一致
  ingress:
    hosts:
      core: harbor.rstyro.com # 证书绑定域名必须完全匹配
    className: "higress"
    annotations:
      ingress.kubernetes.io/ssl-redirect: "true"
      ingress.kubernetes.io/proxy-body-size: "0"
      nginx.ingress.kubernetes.io/ssl-redirect: "true"
      nginx.ingkubernetes.io/proxy-body-size: "0"
      nginx.ingress.kubernetes.io/proxy-read-timeout: "600"
      nginx.ingress.kubernetes.io/proxy-send-timeout: "600"
externalURL: https://harbor.rstyro.com
# 若使用企业自建CA，配置全局可信CA Secret（可选）
# caSecretName: "harbor-root-ca"
```

| 字段 | 说明 |
| --- | --- |
| `enabled` | 是否启用 HTTPS。生产必须 `true` |
| `certSource` | 证书来源：`auto` 自签、`secret` 自有证书、`none` 使用 Ingress 默认证书 |
| `auto.commonName` | 非 Ingress 模式必填域名 |
| `secret.secretName` | `certSource: secret` 时，指定 TLS Secret 名称 |

#### 5.2.2 配套全局关联配置

```yaml
externalURL: https://harbor.rstyro.com

expose:
  ingress:
    hosts:
      core: harbor.rstyro.com
```

**注意**：`externalURL` 和 `ingress.hosts.core` 必须完全一致，否则：

- 浏览器报证书域名不匹配
- Docker login 报 401 鉴权失败
- Token 服务返回错误地址

#### 5.2.3 模式一：certSource = auto（自动生成证书）

适用场景：测试、内网临时环境、快速验证。

```yaml
expose:
  type: ingress
  tls:
    enabled: true
    certSource: auto
  ingress:
    hosts:
      core: harbor.rstyro.com

externalURL: https://harbor.rstyro.com
```

**优点**：

- 零证书准备，一条命令部署
- 自动创建 TLS Secret 并绑定 Ingress

**缺点**：

- 自签证书不被浏览器/客户端信任
- Docker login 会报 `x509: certificate signed by unknown authority`
- 升级 Harbor 可能重新生成证书，导致客户端信任失效
- 企业等保、合规场景不认可

#### 5.2.4 模式二：certSource = secret（企业生产标准）

支持三种证书来源：

1. 公网可信 SSL（Let's Encrypt、云厂商付费证书）
2. 企业自建 OpenCA 签发的内网域名证书
3. cert-manager 自动签发

配置示例：

```yaml
expose:
  type: ingress
  tls:
    enabled: true
    certSource: secret
    secret:
      secretName: "harbor-tls"
  ingress:
    hosts:
      core: harbor.rstyro.com

externalURL: https://harbor.rstyro.com

# 企业自建CA
caSecretName: "harbor-root-ca"
```

前置要求：

```bash
# 云平台下载压缩包，得到 3 个文件：
# domain.crt  域名证书
# domain.key  私钥
# chain.crt  中间 CA 证
# 拼接完整证书链
cat domain.crt chain.crt > fullchain.crt

# 提前在 harbor 命名空间创建 TLS Secret
kubectl create secret tls harbor-tls \
  -n harbor \
  --cert ./fullchain.crt \
  --key ./domain.key

# 如果是自建 CA，同时创建根 CA Secret
kubectl create secret generic harbor-root-ca \
  -n harbor \
  --from-file=ca.crt=./ca.crt
```

证书文件要求：

- `tls.crt`：完整证书链，顺序为 **域名证书 → 中间 CA 证书**（部分场景需包含根 CA）
- `tls.key`：无密码的 RSA/ECC 私钥
- SAN/CN 必须包含 `harbor.example.com`

#### 5.2.5 自建 CA 签发证书完整流程

适用于企业内网没有公网域名的场景。

- 示例需要配置域名：harbor.rstyro.com

**步骤 1：创建根 CA**

```bash
# 根 CA 私钥
openssl genrsa -out ca.key 4096

# 根 CA 证书，有效期 10 年
openssl req -x509 -new -nodes -key ca.key -sha256 -days 3650 \
  -subj "/C=CN/ST=Guangdong/L=Shenzhen/O=Company/OU=DevOps/CN=Company-Internal-CA" \
  -out ca.crt
```

**步骤 2：创建域名证书请求并签发**

创建 `v3.ext` 文件：

```ini
[req]
distinguished_name = dn
x509_extensions = v3
prompt = no

[dn]
C=CN
ST=Guangdong
L=Shenzhen
O=Company
OU=DevOps
CN=harbor.rstyro.com

[v3]
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt

[alt]
DNS.1=harbor.rstyro.com
# 如有泛域名可添加 DNS.2=*.rstyro.com
# 如有内网IP访问可添加 IP.1=192.168.xx.xx
```

签发：

```bash
# 域名私钥
openssl genrsa -out harbor.key 2048

# 证书请求
openssl req -new -key harbor.key -out harbor.csr -config v3.ext

# 使用根 CA 签发
# -CAcreateserial会生成 harbor-ca.srl，妥善保存，后续签发其他内网证书需要，不要删除
openssl x509 -req -in harbor.csr -CA ca.crt -CAkey ca.key -CAcreateserial \
  -out harbor.crt -days 1095 -sha256 -extfile v3.ext -extensions v3
```

**步骤 3：创建 K8s Secret**

```bash
# 拼接证书链
cat harbor.crt ca.crt > fullchain.crt

# Ingress对外HTTPS tls类型secret
kubectl create secret tls harbor-tls -n harbor --cert fullchain.crt --key harbor.key

# 全局根CA信任secret，对应caSecretName: harbor-root-ca
kubectl create secret generic harbor-root-ca -n harbor --from-file=ca.crt=ca.crt

# 验证根 CA secret 存在
kubectl get secret harbor-root-ca -n harbor


# 查看Ingress 是否切换到你指定的 Secret
kubectl get ingress -n harbor -o yaml | grep secretName


# 查看证书有效期，30145对应443端口
echo | openssl s_client -connect harbor.rstyro.com:30145 -servername harbor.rstyro.com 2>/dev/null | openssl x509 -noout -text | grep -E "Not Before|Not After|Issuer:"
```

#### 5.2.6 客户端信任自建 CA

服务器端配置完成后，客户端（Docker/containerd/nerdctl）也需要信任该 CA：

```bash
# Linux 系统信任
cp ca.crt /usr/local/share/ca-certificates/harbor-ca.crt
update-ca-certificates

# containerd 配置信任
cp ca.crt /etc/containerd/certs.d/harbor.rstyro.com/ca.crt

# 重启 containerd
systemctl restart containerd
```

### 5.3 使用cert-manager自动管理证书

cert-manager 是 Kubernetes 上最常用的证书自动化管理工具，支持 Let's Encrypt、ACME、私有 CA 等多种 Issuer。与 Harbor 配合后，可以实现证书自动申请、自动续期、自动更新 Secret，无需人工干预。

#### 适用场景

- 使用公网域名（如 `harbor.example.com`）
- 集群已安装 cert-manager
- 有可用的 Issuer：`ClusterIssuer` 或 `NamespaceIssuer`
- 希望证书到期前自动续期

#### 步骤 1：安装 cert-manager（如未安装）

```bash
# 安装
helm install \
  cert-manager oci://quay.io/jetstack/charts/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.21.0 \
  --set crds.enabled=true
  
  
# 卸载,使用 uninstall 或 delete
helm uninstall cert-manager --namespace cert-manager
# 如果你想完全卸载 cert-manager，需要删除之前安装的 CustomResourceDefinition 资源
kubectl delete crd \
  issuers.cert-manager.io \
  clusterissuers.cert-manager.io \
  certificates.cert-manager.io \
  certificaterequests.cert-manager.io \
  orders.acme.cert-manager.io \
  challenges.acme.cert-manager.io

```

#### 步骤 2：创建 ClusterIssuer（以 Let's Encrypt 为例）

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@example.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
      - http01:
          ingress:
            class: nginx
```

如果是公司自建 CA（参考 [5.2.5 自建 CA 签发证书完整流程](#525-自建-ca-签发证书完整流程)），可改用 `Issuer` + `CA` 类型，复用已有的根 CA 证书：

```bash
# 将自建根 CA 证书创建为 Secret（cert-manager 会用它签发域名证书）
kubectl create secret tls company-root-ca-secret \
  -n cert-manager \
  --cert ./ca.crt \
  --key ./ca.key
```

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: rstyro-internal-ca
spec:
  ca:
    secretName: company-root-ca-secret
    

# 新建文件
cat > ca-clusterissuer.yaml<<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: rstyro-internal-ca
spec:
  ca:
    secretName: company-root-ca-secret
EOF    
```

#### 步骤 3：创建 Certificate 资源

在 Harbor 命名空间创建 Certificate，cert-manager 会自动签发并写入 Secret：

```yaml
cat > ca-certificate.yaml<<EOF
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: harbor-tls
  namespace: harbor
spec:
  secretName: harbor-tls
  issuerRef:
    name: rstyro-internal-ca      # 或 letsencrypt-prod
    kind: ClusterIssuer
  dnsNames:
    - harbor.rstyro.com
  duration: 8760h        # 证书有效期 1 年
  renewBefore: 720h      # 到期前 30 天续期
EOF  
```

创建后检查证书状态：

```bash
kubectl get certificate -n harbor
kubectl describe certificate harbor-tls -n harbor

# 因为之前我们自建证书的时候，已经创建了harbor-tls，需要删除掉，不然会冲突（要么就改名）
kubectl delete secret harbor-tls -n harbor
```

正常状态应为 `Ready=True`，并自动创建 `harbor-tls` Secret。

#### 步骤 4：Harbor values 使用 cert-manager 生成的 Secret（如果之前secretName不一样的话）

```yaml
expose:
  type: ingress
  tls:
    enabled: true
    certSource: secret
    secret:
      secretName: "harbor-tls"   # 与 Certificate.spec.secretName 一致
  ingress:
    hosts:
      core: harbor.rstyro.com
    className: nginx
    annotations:
      ingress.kubernetes.io/ssl-redirect: "true"
      nginx.ingress.kubernetes.io/ssl-redirect: "true"
      nginx.ingress.kubernetes.io/proxy-body-size: "0"

externalURL: https://harbor.rstyro.com
```

然后升级 Harbor：

```bash
# 如果secretName 和之前配置的一样就不用升级，直接把之前的secret删掉就行
helm upgrade harbor harbor/harbor -n harbor -f harbor-values.yaml
```

#### 步骤 5：验证 cert-manager 接管成功

```bash
# 查看证书资源
kubectl get certificate -n harbor

# 查看 Secret
kubectl get secret harbor-tls -n harbor

# 验证证书信息，这个 30145 是我higress-gateway网关暴露443的映射端口
echo | openssl s_client -connect harbor.rstyro.com:30145 -servername harbor.rstyro.com 2>/dev/null \
  | openssl x509 -noout -text | grep -E "Issuer:|Not After|DNS:"
```



![](harbor-cert.png)







#### 自动续期机制

cert-manager 默认在证书有效期剩余 **1/3** 时自动续期。例如 90 天有效期的 Let's Encrypt 证书，会在到期前 30 天左右自动：

1. 向 ACME/CA 申请新证书
2. 更新 `harbor-rstyro-tls` Secret 中的 `tls.crt` 和 `tls.key`
3. Ingress 控制器 watch 到 Secret 变化后自动热加载

可以通过以下命令查看下次续期时间：

```bash
kubectl get certificate harbor-tls -n harbor -o wide
```

#### 注意事项

- 使用 Let's Encrypt 时，域名必须能从公网访问并通过 HTTP-01 或 DNS-01 挑战
- 内网域名建议使用 DNS-01 挑战，或部署私有 ACME（如 step-ca）
- 使用私有 CA 时，客户端仍需手动信任根 CA
- 不要同时用 Helm 自动证书（`certSource: auto`）和 cert-manager，两者会冲突
- 建议设置 Prometheus 告警监控 `Certificate` 资源的 `Ready=False` 状态

#### 自建 CA 续期自动化补充

如果使用公司自建 CA，也可以将续期脚本与 cert-manager 结合：

1. 编写一个 CronJob，定期调用内部 CA 接口签发新证书
2. 签发后将 `tls.crt` 和 `tls.key` 写入 `harbor-rstyro-tls` Secret
3. 或者实现自定义 cert-manager `Issuer`/`ClusterIssuer`，对接公司 CA

更简单的方式是使用 [step-ca](https://smallstep.com/docs/step-ca) 作为内部 ACME 服务器，cert-manager 直接通过 ACME 协议申请和续期。

### 5.4 外部数据库与 Redis

生产环境建议将 PG 和 Redis 外置：

```yaml
database:
  type: external
  external:
    host: "192.168.0.10"
    port: "5432"
    username: "harbor"
    password: "password"
    coreDatabase: "registry"
    sslmode: "require"

redis:
  type: external
  external:
    addr: "192.168.0.11:6379"
    coreDatabaseIndex: "0"
    jobserviceDatabaseIndex: "1"
    registryDatabaseIndex: "2"
    trivyAdapterIndex: "5"
```



## 六、客户端配置与镜像操作

### 6.1 常用客户端工具

| 工具 | 适用场景 |
| --- | --- |
| docker | 传统 Docker 环境 |
| nerdctl | containerd 环境（K8s 节点常用） |
| crictl | 仅用于排查，不推荐日常推送拉取 |
| helm | 推送/拉取 Helm Chart |
| oras | 推送/拉取 OCI Artifact |

### 6.2 配置 containerd / nerdctl 访问 Harbor

#### 6.2.1 方式一：配置 hosts.toml 跳过 TLS 校验（测试）

```bash
mkdir -p /etc/containerd/certs.d/harbor.rstyro.com:30145

cat > /etc/containerd/certs.d/harbor.rstyro.com:30145/hosts.toml << EOF
server = "https://harbor.rstyro.com:30145"

[host."https://harbor.rstyro.com:30145"]
  capabilities = ["pull", "push", "resolve"]
  skip_verify = true
EOF

systemctl restart containerd
nerdctl login harbor.rstyro.com
```

#### 6.2.2 方式二：配置 CA 证书信任（生产）

```bash
# 下载 CA 证书
kubectl get secret -n harbor harbor-tls \
  -o jsonpath='{.data.ca\.crt}' | base64 -d > /etc/containerd/certs.d/harbor.rstyro.com:30145/ca.crt

# 可选：加入系统信任
cp /etc/containerd/certs.d/harbor.rstyro.com:30145/ca.crt /usr/local/share/ca-certificates/harbor-ca.crt
update-ca-certificates

systemctl restart containerd
nerdctl login harbor.rstyro.com:30145
```

#### 6.2.3 Docker 配置 insecure registry（不推荐生产使用）

```json
{
  "insecure-registries": ["harbor.rstyro.com:30145"]
}
```

### 6.3 镜像推送与拉取

```bash
# 登录
nerdctl login harbor.rstyro.com:30145

# 拉取公共镜像测试
nerdctl pull nginx:alpine

# 打标签
nerdctl tag nginx:alpine harbor.rstyro.com:30145/library/nginx:alpine

# 推送
nerdctl push harbor.rstyro.com:30145/library/nginx:alpine

# 拉取
nerdctl pull harbor.rstyro.com:30145/library/nginx:alpine

# 删除本地镜像
nerdctl rmi harbor.rstyro.com:30145/library/nginx:alpine
```


![](harbor-nerdctl.png)



### 6.4 推送 Helm Chart

```bash
# 拉取 harbor Chart,
# --untar 参数会解压出 harbor 文件夹
helm pull harbor/harbor --untar

# 登录 Helm
helm registry login harbor.rstyro.com:30145

# 打包 Chart
helm package ./harbor

# 推送 Chart
helm push harbor-1.19.1.tgz oci://harbor.rstyro.com:30145/library

# 拉取 Chart
helm pull oci://harbor.rstyro.com:30145/library/harbor --version 1.19.1
```



![](harbor-use.png)



## 七、Harbor 日常使用

### 7.1 核心概念：项目、仓库、Artifact

| 概念 | 说明 | 类比 |
| --- | --- | --- |
| **项目（Project）** | 镜像/Chart 的命名空间，用于权限隔离 | GitLab Group |
| **仓库（Repository）** | 同一镜像/Chart 的不同版本集合 | GitLab Project |
| **Artifact** | 单个镜像或 Chart 版本 | Git Commit |
| **Tag** | Artifact 的可读标识 | Git Tag |
| **Digest** | Artifact 的内容寻址哈希 | Git SHA |

**示例**：`harbor.rstyro.com:30145/library/nginx:alpine`

- `library` 是项目
- `nginx` 是仓库
- `alpine` 是 tag

### 7.2 项目规划建议

| 项目类型 | 用途 | 访问控制 |
| --- | --- | --- |
| `library` | 基础镜像（nginx、alpine、busybox） | 公开只读，管理员推送 |
| `middleware` | 中间件镜像（redis、mysql、kafka） | 团队只读，运维推送 |
| `business/<team>` | 业务镜像 | 团队读写，其他团队只读或无权限 |
| `public` | 允许外部拉取的镜像 | 公开只读 |
| `sandbox` | 测试/实验镜像 | 团队成员读写 |

### 7.3 用户与权限模型

Harbor 支持三类账户：

- **本地用户**：Harbor 内置数据库用户
- **LDAP/AD 用户**：对接企业目录服务
- **OIDC 用户**：对接 OIDC 身份提供商（如 Keycloak、Dex）

#### 7.3.1 项目角色

| 角色 | 权限 |
| --- | --- |
| **项目管理员（Project Admin）** | 管理项目成员、配置、策略、推送/拉取/删除 |
| **维护人员（Maintainer）** | 推送/拉取/删除镜像、管理标签、扫描 |
| **开发人员（Developer）** | 推送/拉取镜像 |
| **访客（Guest）** | 只能拉取 |
| **受限访客（Limited Guest）** | 只能拉取，看不到日志和扫描结果 |

#### 7.3.2 系统角色

| 角色 | 权限 |
| --- | --- |
| **Harbor 系统管理员** | 管理所有项目、用户、配置、执行系统级操作 |
| **普通用户** | 只能访问有权限的项目 |

### 7.4 镜像清理策略

#### 7.4.1 保留策略（Tag Retention）

按规则自动保留/删除 Tag，避免仓库无限膨胀。

常见规则：

- 保留最近推送的 10 个 Tag
- 保留最近 30 天内推送的 Tag
- 删除匹配 `*-snapshot-*` 的 Tag
- 永远保留匹配 `release-*` 的 Tag

#### 7.4.2 不可变规则（Tag Immutability）

防止重要 Tag 被覆盖或删除，例如 `latest`、`v1.0.0`、`release-*`。

#### 7.4.3 垃圾回收（Garbage Collection）

删除不再被任何 Tag 引用的 blob，释放存储空间。

操作路径：**系统管理 → 垃圾回收 → 立即执行**

**注意**：

- GC 会锁定 Registry，执行期间禁止推送
- 大仓库 GC 可能耗时较长，建议低峰期执行
- 可以配置定时任务自动执行

### 7.5 镜像复制（Replication）

Harbor 支持将镜像从一个 Harbor 实例复制到另一个 Harbor，或复制到 Docker Hub、ACR 等外部仓库。

#### 7.5.1 典型场景

- 多地域部署，就近拉取镜像
- 生产/测试环境镜像同步
- 灾备备份
- 向公网仓库发布镜像

#### 7.5.2 配置步骤

1. **创建目标 Registry**：系统管理 → 仓库管理 → 新建目标
2. **创建复制规则**：系统管理 → 复制管理 → 新建规则
3. 选择源项目/仓库、目标仓库、触发方式
4. 支持手动触发、事件触发（推送时自动复制）、定时触发

#### 7.5.3 复制过滤器

- 按项目名称过滤
- 按 Tag 过滤（支持通配符）
- 按标签/资源类型过滤（镜像/Chart）

### 7.6 漏洞扫描

Harbor 默认集成 Trivy，可以对镜像执行安全扫描。

#### 7.6.1 手动扫描

在仓库页面选择一个 Artifact，点击"扫描"。

#### 7.6.2 自动扫描

在项目配置中开启"推送时自动扫描"。

#### 7.6.3 扫描结果解读

| 级别 | 说明 |
| --- | --- |
| CRITICAL | 严重漏洞，建议立即修复 |
| HIGH | 高危漏洞，建议尽快修复 |
| MEDIUM | 中危漏洞，安排修复 |
| LOW | 低危漏洞，视情况处理 |
| UNKNOWN | 信息不足 |

#### 7.6.4 扫描器配置

```yaml
trivy:
  enabled: true
  vulnType: "os,library"
  severity: "UNKNOWN,LOW,MEDIUM,HIGH,CRITICAL"
  skipUpdate: false          # 离线环境设为 true
  offlineScan: false
  timeout: 5m
  resources:
    limits:
      cpu: 1
      memory: 2Gi
```

### 7.7 Webhook 与事件通知

Harbor 支持在镜像推送、拉取、删除、扫描完成等事件时发送 Webhook。

常见用途：

- CI/CD 触发部署
- 企业微信/钉钉/飞书通知
- 安全事件告警
- 审计日志同步

---

## 八、安全与合规

### 8.1 镜像签名与验证

镜像签名可以确保镜像在传输和存储过程中未被篡改。

Harbor 支持两种签名方案：

| 方案 | 工具 | 特点 |
| --- | --- | --- |
| Notation | notation CLI | CNCF 推荐，兼容 OCI 1.0 |
| Cosign | cosign | Sigstore 生态，支持密钥less 签名 |

#### 8.1.1 Notation 签名流程

```bash
# 生成密钥对
notation cert generate-test --default "harbor-signing"

# 登录 Harbor
notation login harbor.rstyro.com:30145

# 签名镜像
notation sign harbor.rstyro.com:30145/library/nginx:alpine

# 验证签名
notation verify harbor.rstyro.com:30145/library/nginx:alpine
```

#### 8.1.2 在 Harbor 中启用签名策略

可以在项目中配置"部署安全"策略：

- 仅允许签名的镜像
- 仅允许来自特定 CVE 级别的镜像
- 阻止存在 CRITICAL 漏洞的镜像拉取

### 8.2 访问控制最佳实践

- 禁止使用 admin 账户日常操作
- 为每个团队/项目分配独立项目
- 最小权限原则：只给需要的角色
- 定期审计用户和机器人账户
- 对接 LDAP/OIDC 实现统一身份管理

### 8.3 机器人账户（Robot Account）

机器人账户用于 CI/CD 流水线推送镜像，避免使用个人账号。

创建路径：项目 → 机器人账户 → 新建

建议：

- 按流水线/项目创建独立机器人账户
- 只分配 Developer 或 Maintainer 权限
- 设置过期时间
- 定期轮换 Token

### 8.4 审计日志

Harbor 记录以下操作：

- 用户登录/登出
- 镜像推送/拉取/删除
- 项目创建/删除
- 成员权限变更
- 配置修改

**注意**：审计日志存储在 PostgreSQL 中，长期运行会占用大量空间，建议定期归档或外接审计系统。

---

## 九、高可用与扩展

### 9.1 高可用架构设计

生产 Harbor 高可用需要考虑三个层面的冗余：

| 层面 | 高可用方案 |
| --- | --- |
| 无状态服务 | Portal/Core/Jobservice 多副本 + K8s Deployment |
| 数据库 | 外部 PostgreSQL 主从/集群（如 Patroni、RDS、Cloud SQL） |
| 缓存 | 外部 Redis Sentinel/Cluster |
| 镜像存储 | 对象存储（S3/OSS/GCS/MinIO）或共享 SAN |
| 入口 | Ingress 多副本 + LB |

### 9.2 不推荐的高可用误区

- **内置 PG/Redis 多副本 + NFS 共享**：内置 PG 不支持多实例共享存储，会导致数据损坏
- **Registry 使用 ReadWriteOnce PVC 多副本**：Pod 无法同时挂载
- **单节点对象存储网关**：对象存储本身也要高可用

### 9.3 性能优化

- **开启 Redis 缓存**：

```yaml
cache:
  enabled: true
  expireHours: 24
```

- **Registry 多副本 + 对象存储**：分散拉取压力
- **CDN 加速**：大镜像分发时在前端加 CDN
- **配额限制**：防止单个项目占用全部存储
- **镜像精简**：使用多阶段构建，减少层数

### 9.4 容量规划

| 场景 | 估算 |
| --- | --- |
| 小型团队（10-50 镜像） | 50-100 GB |
| 中型企业（数百镜像） | 500 GB - 2 TB |
| 大型企业/多地域 | 5 TB+，使用对象存储 |

---

## 十、运维与故障排查

### 10.1 常用排查命令

```bash
# 查看 Pod 状态
kubectl get pods -n harbor

# 查看 Core 日志
kubectl logs -n harbor deployment/harbor-core -f

# 查看 Registry 日志
kubectl logs -n harbor deployment/harbor-registry -c registry -f

# 进入 Core 容器排查
kubectl exec -it -n harbor deployment/harbor-core -- sh

# 查看 Jobservice 任务
kubectl logs -n harbor deployment/harbor-jobservice -f
```

### 10.2 常见问题与解决方案

#### 问题 1：Docker login 报 `x509: certificate signed by unknown authority`

**原因**：客户端不信任 Harbor 的 CA。

**解决**：

- 将 CA 证书加入系统信任
- containerd 配置 `certs.d/<domain>/ca.crt`
- 或使用 `--insecure-registry`（仅限测试）

#### 问题 2：推送镜像报 `unauthorized: authentication required`

**原因**：

- 未登录或 Token 过期
- 用户没有该项目的推送权限
- 项目不存在且用户没有创建项目权限

**解决**：

- 执行 `docker login`
- 检查项目权限
- 确认项目已创建

#### 问题 3：页面能打开，但 Docker pull 报 401

**原因**：

- `externalURL` 与 Ingress 域名不一致
- Core 返回的 Token 服务地址错误

**解决**：

- 检查 `externalURL` 配置
- 检查 Ingress/Service 是否正确路由到 Core

#### 问题 4：GC 执行后空间没有释放

**原因**：

- GC 设置为 dryrun 模式
- 镜像 Tag 仍被引用
- 底层存储未真正删除（对象存储需检查生命周期策略）

**解决**：

- 关闭 dryrun
- 删除不再需要的 Tag 后再执行 GC
- 检查对象存储侧是否有删除延迟

#### 问题 5：Trivy 扫描失败或超时

**原因**：

- 无法下载漏洞库（离线/网络问题）
- 镜像过大或层数过多
- 资源限制过低

**解决**：

- 离线环境设置 `skipUpdate: true` 并预置漏洞库
- 增加 `timeout`
- 增加 Trivy 的 CPU/内存限制

### 10.3 备份与恢复

#### 10.3.1 需要备份的数据

| 数据 | 备份方式 |
| --- | --- |
| PostgreSQL 数据库 | pg_dump / 数据库备份工具 |
| Registry 镜像 blob | 对象存储跨区域复制 / 文件系统快照 |
| Redis | 可重建，通常不需要持久化备份 |
| Harbor 配置文件 | Git 版本化 |
| TLS 证书 Secret | Vault / 安全存储 |

#### 10.3.2 数据库备份脚本示例

```bash
# 进入 PostgreSQL Pod 执行备份
kubectl exec -it -n harbor deployment/harbor-database -- bash -c \
  "pg_dump -U postgres registry" > harbor_registry_$(date +%F).sql
```

#### 10.3.3 恢复流程

1. 在新环境部署 Harbor（使用相同版本或兼容版本）
2. 恢复 PostgreSQL 数据库
3. 挂载原有的 Registry 存储
4. 验证登录、推送、拉取
5. 执行一次 GC 清理孤儿 blob
