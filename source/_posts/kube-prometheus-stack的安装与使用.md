---
title: kube-prometheus-stack的安装与使用
tags: [k8s,Prometheus,Grafana]
categories: 网络运维
date: 2026-08-02 13:54:57
---


在 Kubernetes 集群中，监控是确保系统稳定性和性能的关键环节。根据 CNCF 2025 年年度调查，82% 的容器用户在生产环境中运行 Kubernetes，而其中绝大多数用户选择 Prometheus 和 Grafana 作为监控方案。

<!--more-->


**kube-prometheus-stack** 正是这一生态中最受欢迎的监控解决方案。它是一个 Helm Chart，将 Prometheus、Grafana、Alertmanager 以及 Prometheus Operator 等组件打包在一起，提供开箱即用的 Kubernetes 集群监控能力。



## 一、入门篇

### 1.1 什么是 Kube-Prometheus-Stack？

kube-prometheus-stack 是一个 Helm Chart，它收集了 Kubernetes 清单、Grafana 仪表盘和 Prometheus 告警规则，并结合文档和脚本，提供易于操作的端到端 Kubernetes 集群监控能力。

简单来说，它把原本需要分别安装和配置的多个组件打包成了一个整体：

- **Prometheus Operator**：通过 Kubernetes CRD 管理 Prometheus 实例，是整个系统的控制中心
- **Prometheus**：收集和存储时间序列指标数据
- **Grafana**：提供可视化仪表盘，内置 40+ 预置 Kubernetes 仪表盘
- **Alertmanager**：处理告警路由和通知
- **Node Exporter**：采集节点级别的系统指标（CPU、内存、磁盘、网络等）
- **kube-state-metrics**：采集 Kubernetes 对象状态指标（Deployment、Pod、Service 等）

### 1.2 架构概览

整个监控数据流如下：

```
Node Exporter → Prometheus → Alertmanager → Grafana
kube-state-metrics ↗
```

- **Node Exporter** 以 DaemonSet 方式运行在每个节点上，采集主机级数据
- **kube-state-metrics** 通过查询 Kubernetes API 获取对象状态信息
- **Prometheus** 从这些 exporter 拉取（pull）数据并存储
- **Alertmanager** 根据告警规则触发通知
- **Grafana** 将数据可视化展示

### 1.3 前置条件

在开始安装之前，请确保满足以下条件：

| 条件 | 最低版本 | 验证命令 |
|------|---------|---------|
| Kubernetes 集群 | 1.19+ | `kubectl version` |
| Helm | 3.10+ | `helm version` |
| kubectl 已配置 | - | `kubectl cluster-info` |
| 可用存储 | 10Gi+ | `kubectl get pv` |

兼容的集群类型包括：minikube、kind、k3s、EKS、GKE、AKS 等。

### 1.4 安装 Kube-Prometheus-Stack

#### 步骤 1：添加 Helm 仓库

首先添加 Prometheus 社区官方 Helm 仓库：

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
```

> **提示**：定期执行 `helm repo update` 可以获取安全更新和新功能。

#### 步骤 2：安装 Chart

在 `monitoring` 命名空间中安装：

```bash
helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace
```

> 你也可以使用 OCI 镜像仓库方式安装：
> ```bash
> helm upgrade --install kube-prometheus-stack oci://ghcr.io/prometheus-community/charts/kube-prometheus-stack \
> 		-n monitoring --create-namespace \
>         --version 87.18.1 \
>         --set grafana.enabled=true \
>         --set prometheus.enabled=true 
> ```

#### 步骤 3：验证安装

查看 Pod 运行状态：

```bash
kubectl get pods -n monitoring
```

你应该会看到类似以下的输出：

```bash
NAME                                                        READY   STATUS    RESTARTS   AGE
alertmanager-kube-prometheus-stack-alertmanager-0           2/2     Running   0          27m
kube-prometheus-stack-grafana-fd48944fc-2l2qr               3/3     Running   0          27m
kube-prometheus-stack-kube-state-metrics-6ff49f8969-hstwn   1/1     Running   0          27m
kube-prometheus-stack-operator-6c97785b54-ggrf9             1/1     Running   0          27m
kube-prometheus-stack-prometheus-node-exporter-kthkp        1/1     Running   0          27m
prometheus-kube-prometheus-stack-prometheus-0               2/2     Running   0          27m
```

### 1.5 访问监控界面

#### 访问 Grafana

Grafana服务默认是ClusterIP类型，直接改成NodePort以便我们外部访问

```bash
# 修改为 NodePort
kubectl patch svc -n monitoring kube-prometheus-stack-grafana -p '{"spec":{"type":"NodePort"}}'
kubectl -n higress-system patch svc higress-console -p '{"spec":{"type":"NodePort"}}'

#修改为 NodePort，指定grafana暴露端口为32000
kubectl patch svc -n monitoring kube-prometheus-stack-grafana \
  -p '{"spec":{"type":"NodePort","ports":[{"port":80,"targetPort":3000,"nodePort":32000,"name":"http-web"}]}}'

# 执行如下命令，找到kube-prometheus-stack-grafana 服务对外暴露的端口，例如：80:31877/TCP 
kubectl get svc -n monitoring
```

在浏览器中访问 `http://localhost:31877`，默认登录凭证：
- 用户名：`admin`
- 密码：`prom-operator`（不同版本可能不同，请查看安装输出或 Secret）

登录后，你会看到已经预置了 40+ 个 Kubernetes 相关的仪表盘。

##### 查看Grafana的admin密码

```bash
# 替换 monitoring 为你的实际命名空间
# Secret 名通常是 <release名>-grafana，例如 kube-prometheus-stack-grafana 或 prometheus-grafana

# 如果不确定 Secret 的具体名字，可以先列出来
kubectl get secrets -n monitoring | grep grafana

# 查看用户名
kubectl get secret kube-prometheus-stack-grafana -n monitoring \
  -o jsonpath="{.data.admin-user}" | base64 --decode; echo

# 查看密码
kubectl get secret kube-prometheus-stack-grafana -n monitoring \
  -o jsonpath="{.data.admin-password}" | base64 --decode; echo
  
  
# 查看密码  
kubectl get secret --namespace monitoring -l app.kubernetes.io/component=admin-secret -o jsonpath="{.items[0].data.admin-password}" | base64 --decode ; echo

```



![](prometheus-2.png)



![](prometheus-3.png)


![](prometheus-4.png)


#### 访问 Prometheus

同样可以改为 NodePort 访问：

```bash
# 修改为NodePort
kubectl patch svc -n monitoring kube-prometheus-stack-prometheus -p '{"spec":{"type":"NodePort"}}'

# 查看kube-prometheus-stack-prometheus服务暴露的端口，例如：9090:31713/TCP,8080:30473/TCP
kubectl get svc -n monitoring
```

访问 `http://localhost:31713`，在 **Status → Targets** 页面可以检查所有抓取目标是否健康。





## 二、进阶篇

### 1、使用自定义 Values 配置

kube-prometheus-stack 的强大之处在于可以通过 `values.yaml` 文件进行灵活配置。

#### 查看所有可配置项

kube-prometheus-stack 的 `values.yaml` 包含上千行配置，直接修改容易出错。建议先导出完整配置作为参考：

```bash
helm show values prometheus-community/kube-prometheus-stack > kube-prometheus-stack-values.yaml
```



![](prometheus-1.png)



关键的三个配置层级：

- **`prometheus.prometheusSpec`**：控制 Prometheus 状态集（StatefulSet）的行为（副本数、存储、资源配置、抓取配置）
- **`grafana`**：控制 Grafana 部署（镜像、插件、数据源、持久化、Service 类型）
- **`alertmanager`**：控制告警管理器（路由、接收器、持久化）

后续所有自定义配置均可通过 `-f custom-values.yaml` 或 `--set` 传入。





### 2、持久化存储详解

默认情况下，Prometheus 和 Grafana 使用 `emptyDir`，Pod 重启后数据会丢失。**生产环境必须配置持久化**。以下分场景介绍如何配置。



#### 2.1、场景一：集群已有默认 StorageClass（最简单）

如果集群有默认 StorageClass（通过 `kubectl get sc` 查看，带有 `(default)` 标记），只需指定存储大小即可：

```yaml
prometheus:
  prometheusSpec:
    storageSpec:
      volumeClaimTemplate:
        spec:
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 50Gi
    retention: 15d
```



#### 2.2、场景二：指定特定的 StorageClass

如果你的集群有多个 StorageClass，可以显式指定：

```yaml
prometheus:
  prometheusSpec:
    storageSpec:
      volumeClaimTemplate:
        spec:
          storageClassName: "nfs-client"   # 替换为实际 SC 名称
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 50Gi
```

Grafana 同样可以配置持久化：

```yaml
grafana:
  persistence:
    enabled: true
    storageClassName: "nfs-client"
    accessModes:
      - ReadWriteOnce
    size: 10Gi
```



#### 2.3、场景三：集群没有StorageClass,静态PV+hostPath

很多自建集群（Kubeadm、二进制部署）没有配置任何 StorageClass，也没有 NFS 等共享存储。此时我们可以利用节点本地磁盘，通过 **静态 PV + hostPath** 或 **部署本地供给器** 来解决。



> **适用环境**：单节点或可接受 Pod 固定在特定节点的场景。
> **原理**：管理员在节点上创建目录，手动定义 PV，并在 PVC 中指定 `storageClassName: ""` 以匹配这些静态 PV。

##### ①、在节点上创建数据目录

```bash
mkdir -p /data/{prometheus,grafana,alertmanager}
# 注意：Prometheus 容器默认以 nobody（UID 65534）运行，需赋予写权限
chown -R 65534:65534 /data/prometheus
chmod 755 /data/{prometheus,grafana,alertmanager}
```



##### ②、编写一个包含所有 PV 的 YAML 文件

创建 `local-storage.yaml`，内容如下（**请将 `<your-node-name>` 替换为实际节点名**）：

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: prometheus-pv
  labels:
    app: prometheus
    type: local
spec:
  capacity:
    storage: 50Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: ""                    # 必须为空，禁用动态供给
  hostPath:
    path: /data/prometheus
  nodeAffinity:                           # 强制绑定到当前节点
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - <your-node-name>              # 替换为 `kubectl get nodes` 显示的名称
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: grafana-pv
  labels:
    app: grafana
    type: local
spec:
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: ""
  hostPath:
    path: /data/grafana
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - <your-node-name>
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: alertmanager-pv
  labels:
    app: alertmanager
    type: local
spec:
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: ""
  hostPath:
    path: /data/alertmanager
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - <your-node-name>
```



##### ③、应用 PV 配置

一键apply执行

```bash
kubectl apply -f local-storage.yaml
```



##### ④、配置 Helm values 使用这些静态 PV

创建 `prometheus-custom-values.yaml`，设置 `storageClassName: ""` 并强制调度到该节点：

```yaml
prometheus:
  prometheusSpec:
    # prometheus权限修复核心配置
    securityContext:
      runAsUser: 65534
      runAsGroup: 65534
      runAsNonRoot: true
      fsGroup: 65534
    storageSpec:
      volumeClaimTemplate:
        spec:
          storageClassName: ""    # 必须为空，匹配上述静态 PV
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 50Gi       # 不得超过 PV 容量
    nodeSelector:
      kubernetes.io/hostname: <your-node-name>   # 与 PV 的 nodeAffinity 保持一致

grafana:
  persistence:
    enabled: true
    storageClassName: ""
    size: 10Gi
  nodeSelector:
    kubernetes.io/hostname: <your-node-name>

alertmanager:
  alertmanagerSpec:
    storage:
      volumeClaimTemplate:
        spec:
          storageClassName: ""
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 10Gi
    nodeSelector:
      kubernetes.io/hostname: <your-node-name>
```



##### ⑤、安装或升级 Helm Release



```bash
# 安装或升级
helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  -f prometheus-custom-values.yaml \
  --version 87.18.1 \
  -n monitoring --create-namespace

# 验证持久化是否生效
kubectl get pv
kubectl get pvc -n monitoring  
```



##### 常见问题：

报错：`msg="Error opening query log file" component=activeQueryTracker file=/prometheus/queries.active err="open /prometheus/queries.active: permission denied"` 这是Prometheus 容器内部进程是 **nobody 用户**，无写入权限，无法创建查询日志文件直接崩溃

```bash
# 重新执行授权
chown -R 65534:65534 /data/prometheus

# 删除旧statefulset pod重建
kubectl delete pod prometheus-kube-prometheus-stack-prometheus-0 -n monitoring

# 稍微等一下就由CrashLoopBackOff变为Running了
```



##### 卸载

```bash
# 卸载helm release
helm uninstall kube-prometheus-stack -n monitoring

# 删除本地静态PV
kubectl delete -f local-storage.yaml

# 删除命名空间
kubectl delete ns monitoring

# 清理监控CRD资源
kubectl delete crd alertmanagerconfigs.monitoring.coreos.com --ignore-not-found
kubectl delete crd alertmanagers.monitoring.coreos.com --ignore-not-found
kubectl delete crd prometheuses.monitoring.coreos.com --ignore-not-found
kubectl delete crd servicemonitors.monitoring.coreos.com --ignore-not-found
kubectl delete crd podmonitors.monitoring.coreos.com --ignore-not-found
kubectl delete crd prometheusrules.monitoring.coreos.com --ignore-not-found
```



### 3、自定义监控指标：ServiceMonitor 与 PodMonitor

kube-prometheus-stack 通过 **ServiceMonitor** 和 **PodMonitor** 这两个 CRD 来实现动态的服务发现和指标采集。

- **ServiceMonitor**：通过 Service 对象发现目标，适合监控稳定的服务
- **PodMonitor**：直接通过 Pod 标签发现目标，适合监控动态或临时性的 Pod

#### 示例：监控一个自定义应用

假设你有一个名为 `my-app` 的 Service，暴露了 `/metrics` 端点：

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: my-app-monitor
  namespace: default
  labels:
    release: prometheus-stack  # 必须匹配 Helm release 标签
spec:
  selector:
    matchLabels:
      app: my-app
  endpoints:
    - port: metrics
      path: /metrics
      interval: 30s
```

应用该配置后，Prometheus 会自动发现并开始采集 `my-app` 的指标。

> **注意**：默认情况下，kube-prometheus-stack 只监控带有特定标签（与 Helm release 匹配）的 ServiceMonitor。如需监控所有命名空间的 ServiceMonitor，可配置：
> ```yaml
> prometheus:
>   prometheusSpec:
>     serviceMonitorSelectorNilUsesHelmValues: false
> ```

### 4、配置告警规则

告警规则通过 **PrometheusRule** CRD 定义。

#### 查看默认告警规则

kube-prometheus-stack 内置了 200+ 条默认告警规则。查看它们：

```bash
kubectl get prometheusrules -n monitoring
```

#### 添加自定义告警规则

在 `custom-values.yaml` 中添加：

```yaml
additionalPrometheusRules:
  - name: custom-alerts
    groups:
      - name: cpu-alerts
        rules:
          - alert: HighCPUUsage
            expr: 100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
            for: 5m
            labels:
              severity: warning
            annotations:
              summary: "CPU usage is above 80%"
              description: "CPU usage is {{ $value }}% on {{ $labels.instance }}"
```

#### 配置 Alertmanager

Alertmanager 负责将告警路由到不同的接收端。配置示例：

```yaml
alertmanager:
  config:
    global:
      resolve_timeout: 5m # 故障恢复后等待5min消除告警
    route:
      group_by: ['alertname','cluster'] # 同类型、同集群告警合并
      group_wait: 30s # 首次告警等待30s聚合
      group_interval: 5m # 同组新告警间隔5min推送
      repeat_interval: 4h # 告警重复推送间隔4小时
      receiver: 'mail-default' # 默认接收渠道
      # 分级路由
      routes:
        - match:
            severity: critical
          receiver: 'critical-pager'
    receivers:
      # 普通告警：邮件推送
      - name: 'mail-default'
        email_configs:
          - to: 'dev-team@company.com'
      # 严重故障：加急通知渠道
      - name: 'critical-pager'
        pagerduty_configs:
          - service_key: "你的pagerduty密钥"
```

### 5、生产环境高可用配置

生产环境中，需要配置 Prometheus 多副本以实现高可用。

```yaml
prometheus:
  prometheusSpec:
    replicas: 2
    podAntiAffinity: "hard"
    externalLabels:
      cluster: "prod-cluster"
```

- **replicas: 2**：启动 2 个 Prometheus 副本
- **podAntiAffinity: hard**：确保副本调度在不同节点上
- **externalLabels**：为指标添加集群标签，便于多集群场景区分



## 三、最后

- 入门文档够用，更多内容可参考官方文档及社区最佳实践
