---
title: Harbor的安装与使用
tags: [k8s,Harbor,Kubernetes]
categories: 网络运维
date: 2026-07-04 20:08:52
updated: 2026-07-04 20:08:52
---



## 前言



## Harbor是什么



### Harbor的结构化认知模式

### -  起源 → 定义 → 用途 → 模式归属？



很多坑其实源于没想清楚 Harbor 的**数据分层**。它不是一个单体，而是把"元数据"和"镜像 blob"拆成了两层：

| 层级     | 组件                       | 存什么                | 是否状态           |
| -------- | -------------------------- | --------------------- | ------------------ |
| 接入层   | Nginx（Ingress）           | TLS 终止、路由        | 无                 |
| 服务层   | Portal / Core / Jobservice | API、UI、异步任务     | **无**（可多副本） |
| 安全层   | Trivy（Scanner）           | 漏洞扫描              | 无                 |
| 镜像层   | Registry + RegistryCTL     | 镜像 blob 实际存储    | **有**             |
| 元数据层 | PostgreSQL                 | 项目/用户/镜像索引    | **有**             |
| 缓存层   | Redis                      | 会话、Job 队列、Token | **有**             |





## 一、安装Harbor



### 方案一：docker-compose安装

```bash
# 下离线包
wget https://github.com/goharbor/harbor/releases/download/v2.15.2/harbor-offline-installer-v2.15.2.tgz
tar xzf harbor-offline-installer-v2.15.2.tgz && cd harbor
cp harbor.yml.tmpl harbor.yml
# 改 hostname + 端口 + 管理员密码，然后
./install.sh

```





### 方案二：Helm安装

```bash
# 添加仓库并部署
helm repo add harbor https://helm.goharbor.io
helm repo update

# 确认版本存在
helm search repo harbor/harbor --versions | head

#  查看harbor的 Chart 的默认 values
helm show values harbor/harbor > harbor-values.yaml

# 创建命名空间
# kubectl create ns harbor

# 安装harbor
helm install harbor harbor/harbor -n harbor --create-namespace -f harbor-values.yaml 

# 升级harbor配置
helm upgrade harbor harbor/harbor -n harbor -f harbor-values.yaml


# 卸载
helm uninstall harbor -n  harbor

# 删除镜像/模型数据
kubectl delete pvc -n harbor --all

# === 删除 Namespace ===
kubectl delete namespace harbor
# ⚠️ 会删除 namespace 下所有资源!
```

#### 默认配置详解
- 总体配置模板如下：

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



#### 我的配置

- 我提前配置nfs动态分配

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
    className: "nginx"  # 若使用 nginx-ingress，可指定
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

# ---------------------- CA 证书 Secret ----------------------
caSecretName: ""  # 若需提供自定义 CA 证书供下载，可指定

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
    password: "harbor_registry_password"  # 【需修改】

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





## 二、配置解析



### TLS 总配置区块

```
expose:
  type: ingress
  tls:
    # 生产必须开启HTTPS
    enabled: true
    # 核心切换字段：auto / secret / none
    certSource: auto
    auto:
      # auto模式下证书域名
      commonName: ""
    secret:
      # secret模式下tls类型Secret名称
      secretName: ""
```

### 字段核心释义

1. `enabled: true`：全局开关，关闭则不启用 HTTPS，生产禁止关闭

2. ```
   certSource
   ```

   

   三选一：

   - `auto`：Harbor Chart 自动生成一套自签 CA + 域名证书，零证书文件准备
   - `secret`：读取集群预先创建的 `kubernetes.io/tls` 类型 Secret，使用企业 / 云厂商可信证书、自建 CA 证书
   - `none`：Ingress Controller 全局默认证书，极少使用

3. `auto.commonName`：非 Ingress 暴露模式必填，Ingress 场景会自动复用 `expose.ingress.hosts.core` 域名

4. `secret.secretName`：仅 `certSource: secret` 生效，必须提前在 harbor 命名空间创建 tls Secret

### 配套全局关联配置（必须同步匹配）

```yaml
externalURL: https://harbor.rstyro.com
ingress:
  hosts:
    core: harbor.rstyro.com
```

域名必须完全一致，否则证书域名不匹配、docker 推拉 401 鉴权失败。




## 三、安装Higress



```bash
helm repo add higress.io https://higress.io/helm-charts
helm repo update


helm install higress -n higress-system higress.io/higress --create-namespace --render-subchart-notes


helm upgrade higress -n higress-system higress.io/higress --create-namespace --render-subchart-notes --set global.gateway.replicas=1



# 服务器资源不够，测试用
helm install higress -n higress-system higress.io/higress \
  --create-namespace \
  --set gateway.replicas=1 \
  --set higress-core.gateway.resources.requests.cpu=50m \
  --set higress-core.gateway.resources.requests.memory=128Mi \
  --set higress-core.gateway.resources.limits.cpu=200m \
  --set higress-core.gateway.resources.limits.memory=256Mi \
  --set higress-core.controller.replicas=1 \
  --set higress-core.controller.resources.requests.cpu=100m \
  --set higress-core.controller.resources.requests.memory=256Mi \
  --set higress-core.controller.resources.limits.cpu=500m \
  --set higress-core.controller.resources.limits.memory=512Mi \
  --set higress-console.resources.requests.cpu=50m \
  --set higress-console.resources.requests.memory=128Mi \
  --set higress-console.resources.limits.cpu=200m \
  --set higress-console.resources.limits.memory=256Mi


# 卸载
helm uninstall higress -n higress-system
```

