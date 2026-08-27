---
title: 安装Higress与使用
tags: [k8s,Higress]
categories: 网络运维
date: 2026-07-10 18:49:21
---

## 前言

在云原生与AI大模型快速落地的当下，传统网关难以适配智能流量调度、AI模型服务治理、高弹性云原生业务场景。Higress 作为阿里开源的轻量化云原生API网关，深度适配Kubernetes生态，基于Envoy与Istio架构重构优化，兼具高性能、高扩展性与AI场景适配能力，可完美支撑云原生微服务、AI模型服务的流量管理、安全管控、可观测等核心需求。本文将详细介绍Higress核心能力，并提供低资源测试环境的Helm标准化部署方案。


## 一、Higress 概述

### 1.什么是 Higress

Higress 是阿里巴巴开源的**云原生一体化API网关**，基于Envoy数据面、Istio控制面深度构建，区别于传统网关，针对性优化了AI服务调度、云原生微服务治理场景，具备轻量化、高性能、易扩展、全场景适配的特点，是兼顾微服务网关、Ingress网关、AI网关的一站式流量治理组件。

<!--more-->


### 2.核心能力

Higress 集成了流量调度、安全防护、AI服务治理、发布灰度、可观测等全维度能力，覆盖云原生与AI业务全生命周期流量管理需求，核心能力汇总如下：

```
核心能力:
├── AI 网关能力（兼容OpenAI标准API，适配大模型服务调度）
├── 多模型智能路由（模型负载均衡、故障自动转移、流量分发）
├── Token级精细化限流（支持按分钟Token用量精准限流，适配AI场景）
├── 全方位认证鉴权（支持API Key、JWT、OAuth主流鉴权方式）
├── AI流量统计监控（Token消耗量、请求延迟、成功率等指标监控）
├── Wasm动态插件扩展（支持自定义业务逻辑，无需重构网关）
├── 精细化灰度发布（金丝雀发布、A/B测试、流量灰度分流）
└── 多协议智能转换（支持HTTP、gRPC、WebSocket协议互通转换）
```



## 二、安装Higress

> 在标准 K8s 集群中使用



### Helm安装Higress

Higress 官方提供了 Helm Chart，推荐使用 Helm 进行安装与管理。


#### 1、自定义配置文件

- 我的服务器资源有限，通过自定义配置文件`higress-values.yaml`降低各组件的资源配额，如下:

```yaml
global:
  ingressClass: higress

# 这是父 Chart 引用子 Chart higress-core 的命名空间
higress-core:
  gateway:
  	# 网关单副本部署
    replicas: 1
    service:
      # NodePort方式暴露服务，方便测试访问
      type: NodePort
    resources:
      requests:
        cpu: 100m
        memory: 256Mi
      limits:
        cpu: 500m
        memory: 512Mi
  controller:
    replicas: 1
    resources:
      requests:
        cpu: 100m
        memory: 256Mi
      limits:
        cpu: 500m
        memory: 512Mi
  # pilot 应该就是discovery ，默认是2Gi内存，有点多，替换一下
  pilot:
    resources:
      requests:
        cpu: 100m
        memory: 256Mi
      limits:
        cpu: 300m
        memory: 512Mi

higress-console:
  replicaCount: 1
  service:
  	# 控制台NodePort暴露，方便测试访问
    type: NodePort
  resources:
    requests:
      cpu: 50m
      memory: 128Mi
    limits:
      cpu: 200m
      memory: 256Mi
```

#### 2、添加 Helm 仓库并安装

```bash
# 添加 Higress Helm 仓库
helm repo add higress.io https://higress.io/helm-charts
helm repo update


# 服务器资源不够，使用自定义配置文件安装
helm install higress higress.io/higress \
  -n higress-system --create-namespace \
  -f higress-values.yaml

# 若不使用配置文件，也可通过 --set 参数逐个指定
helm install higress -n higress-system higress.io/higress \
  --create-namespace \
  --set global.ingressClass=higress \
  --set higress-console.service.type=NodePort \
  --set higress-core.gateway.replicas=1 \
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
  --set higress-console.resources.limits.memory=256Mi \
  --set higress-core.discovery.resources.requests.cpu=50m \
  --set higress-core.discovery.resources.requests.memory=128Mi \
  --set higress-core.discovery.resources.limits.cpu=200m \
  --set higress-core.discovery.resources.limits.memory=256Mi 
  
# --render-subchart-notes 参数可选，用于渲染子 Chart 的说明信息。
helm install higress -n higress-system higress.io/higress --create-namespace --render-subchart-notes

```

#### 3、升级与卸载

```bash
# 升级已部署的 Higress（例如修改副本数）
helm upgrade higress -n higress-system higress.io/higress \
  --set global.gateway.replicas=1

# 升级已部署的 Higress-通过自定义文件
helm upgrade higress higress.io/higress \
  -n higress-system \
  -f higress-values.yaml
  

# 卸载 Higress
helm uninstall higress -n higress-system
```





## 三、Higress简单使用

安装完成后，我们可以通过一个简单的 Demo 来验证 Higress 的路由功能。下面将在集群中部署一个后端服务，并创建 Ingress 规则，将外部请求转发至该服务。



### 1、部署后端测试服务

包含 Deployment + Service，使用 Higress 官方回显镜像，访问接口会返回请求完整信息，方便调试路由规则。

创建 `demo1.yaml` 文件，内容如下：

```yaml
apiVersion: v1
kind: Service
metadata:
  name: backend
  labels:
    app: backend
spec:
  ports:
  - name: http
    port: 3000
    targetPort: 3000
  selector:
    app: backend
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
spec:
  replicas: 1
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
      - name: backend
        image: higress-registry.cn-hangzhou.cr.aliyuncs.com/higress/echoserver:v20221109-7ee2f3e
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 3000
```

执行部署命令：

```bash
kubectl apply -f demo1.yaml
# 验证服务 Pod 正常启动
kubectl get pods
kubectl get svc backend
```



### 2、创建 Higress 路由规则

通过标准 Kubernetes Ingress 资源声明路由，指定 `ingressClassName: higress` 交由 Higress 接管流量，匹配路径 `/hello-world` 转发至 backend 服务 3000 端口。

创建 `demo1-ingress.yaml` 文件，内容如下：

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: hello-world
spec:
  ingressClassName: higress
  rules:
  - http:
      paths:
      - pathType: Prefix
        path: "/hello-world"
        backend:
          service:
            name: backend
            port:
              number: 3000
```

执行以下命令创建 Ingress：

```bash
kubectl apply -f demo1-ingress.yaml
# 查看 Ingress 配置是否生效
kubectl get ingress hello-world
```



### 3、访问测试

由于我们在安装时设置了网关服务类型为 `NodePort`，需要获取 Higress 网关的 NodePort 端口：

```bash
# 先获取 Higress 网关 NodePort 端口
kubectl get svc -n higress-system higress-gateway

```



![](higress.png)



网关（`higress-gateway`）暴露的端口，`80:31320/TCP,443:30145/TCP ` 所以可以访问：

- `http://服务器IP:31320/hello-world`
- `https://服务器IP:30145/hello-world`

 

![](test1.png)



### 4、配置Key认证

Higress 支持为路由配置 API Key 认证，增强访问安全性。

可以添加一个路由指向 `backend` 服务，然后给这个路由配置key认证



![域名管理-先创建一个域名](c1.png)

创建`hw.com` 测试域名（随便取）



![点击创建路由按钮](c2.png)



创建一个路由

![创建路由的各个配置项](c3.png)



目标服务，选择backend 服务



![保存路由成功后，点击路由策略](c4.png)



配置策略



![策略选择-Key认证](c5.png)



选择key认证，进行配置



![调用方添加apikey的列表](c6.png)



在电脑上配置域名hosts文件

![在电脑上配置域名hosts文件](r1.png)



访问测试，
- 添加apikey参数，访问成功
- 不加apikey参数，访问失败



![添加apikey参数，访问成功](c7.png)

![不加apikey参数，访问失败](c8.png)



### 5、访问 Prometheus 指标

Higress的默认 Prometheus 监控的端口为15020
Prometheus 指标实际上是由 `higress-gateway` Pod 本身在 15020 端口上暴露的。Service 只是没有将这个端口映射出来

```bash

# 方法一：
# 获取 Pod IP
kubectl get pods -n higress-system -o wide | grep higress-gateway
# 在集群内部 ，直接访问
curl http://<Pod_IP>:15020/stats/prometheus


# 方法二：
# 为 higress-gateway Service 添加端口映射 (推荐)

# 修改 Service，使其也能转发 15020 端口的流量
kubectl edit svc higress-gateway -n higress-system

# 在 spec.ports 部分下，添加一个新的端口映射。例如，添加一个 NodePort 类型的端口
spec:
  ports:
  # ... 原有的 80, 443 端口配置 ...
  - name: http-monitoring  # 端口名称
    port: 15020
    targetPort: 15020
    nodePort: 31520      # 可选，指定一个 30000-32767 范围内的端口
    protocol: TCP
```

保存后，你就可以通过 `http://<任意节点IP>:31520/stats/prometheus` (如果你设置了 nodePort) 
或 `http://<ClusterIP>:15020/stats/prometheus` (在集群内) 来访问了。



至此，Higress 的基础安装和路由认证功能已成功验证。后续可根据业务需求配置更复杂的灰度发布、限流和 AI 路由策略。
