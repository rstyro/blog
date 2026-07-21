---
title: KServe的安装与使用
tags: [Kserve,k8s]
categories: 网络运维
date: 2026-07-21 18:31:22
---

## 前言

随着大模型、传统机器学习和深度学习推理业务的大规模落地，企业在实际生产中普遍面临以下运维挑战：

- 多框架模型（TensorFlow、PyTorch、ONNX、XGBoost、TensorRT、LLM 等）部署方式各异，缺乏统一运维手段；
- 推理流量波动剧烈，在线服务与离线批处理并存，静态资源分配导致大量浪费；
- 模型版本管理缺失，灰度发布、A/B 测试、流量切分等高级发布策略难以实现；
- 推理接口协议不统一，REST/gRPC 接口格式各异，上层业务集成成本高；
- 可观测性不足，监控、日志、链路追踪等能力需自行开发，无法开箱即用。

原生 Kubernetes 仅提供基础的容器编排能力，无法满足上述 AI 推理场景的专属需求。

<!--more-->


**KServe** 应运而生，它是一个由 CNCF 托管的云原生模型推理平台，基于 Kubernetes 构建，提供标准化、高性能、轻量化的推理服务解决方案。本文将从概念、架构、安装到实际案例，全方位介绍 KServe，覆盖 **Standard（标准）** 与 **Knative Serverless（无服务器）** 两种主流部署模式，助您快速落地 AI 推理服务。



## 一、概述



### 1、什么是 KServe

KServe（前身 KFServing）是面向机器学习 / 深度学习推理场景的开源云原生框架，运行在 Kubernetes 之上，目标是提供统一、标准化的模型推理服务平台。

它屏蔽不同 AI 框架、推理引擎的部署差异，通过自定义资源 `InferenceService` 统一管理模型服务生命周期，内置弹性伸缩、流量路由、灰度发布、模型监控、日志追踪、安全鉴权等企业级能力，兼容传统机器学习、CV 视觉模型、大语言模型 LLM 各类推理业务。



### 2、KServe 诞生背景与解决的核心问题

- **部署繁琐**：TensorFlow、PyTorch、ONNX、XGBoost、TensorRT、LLM 各自推理服务镜像、接口不统一，运维成本极高；
- **算力资源浪费**：推理流量波峰波谷差异显著，原生 Deployment 无法缩容至零，空闲时仍占用资源；
- **缺少模型版本管控能力**：不支持灰度发布、A/B 测试、流量权重切分，模型上线风险高；
- **接口协议混乱**：不同模型服务 Rest/gRPC 接口格式不统一，业务对接成本高；
- **推理可观测能力缺失**：模型输入输出监控、推理延迟、错误率、样本日志采集需要自行开发。



#### KServe 核心解决能力

- **统一 CRD**：使用 `InferenceService` 一套 YAML 即可部署任意框架模型；
- **Serverless 伸缩**：基于 Knative 支持缩容至零副本，大幅节省成本；
- **精细流量管理**：集成 Istio 原生能力，支持灰度、蓝绿、A/B 测试、流量镜像；
- **标准化推理协议**：遵循 v2 推理协议（REST/gRPC），统一预测和元数据接口；
- **内置可观测性**：自动采集 QPS、延迟、错误率等指标，集成日志和分布式追踪；
- **异构硬件调度**：支持 GPU 调度，模型存储支持 S3/OSS/MinIO/PVC 及本地挂载，同时支持离线批量推理。



### 3、什么是 InferenceService

`InferenceService` 是 KServe 的核心自定义资源（CRD），是用户定义模型推理服务的唯一入口，替代原生 Kubernetes的 Deployment/Service/Ingress。

只需要一份 `InferenceService` YAML，KServe Controller 会自动创建底层所有资源：

- 推理后端容器（**Predictor**）
- 数据预处理/后处理容器（**Transformer**）
- 模型可解释性容器（**Explainer**）
- 流量路由规则、VirtualService、弹性伸缩策略（HPA 或 Knative Autoscaler）



#### 三大核心组件

| 组件                      | 职责                                                         |
| :------------------------ | :----------------------------------------------------------- |
| **Predictor（预测器）**   | 加载模型，处理核心推理请求，支持多种运行时（Triton、TorchServe、TensorFlow Serving、vLLM、MLServer 等） |
| **Transformer（转换器）** | 执行请求前数据预处理和响应后处理，解耦业务逻辑与推理引擎     |
| **Explainer（解释器）**   | 提供模型可解释性分析（如特征贡献度），适用于风控、医疗等需解释性的场景 |



### 4、核心组件

| 组件                          | 说明                                                         |
| :---------------------------- | :----------------------------------------------------------- |
| **KServe Controller**         | 核心控制器，监听 `InferenceService` CRD，协调创建/更新/删除底层工作负载 |
| **Model Storage Initializer** | 初始化 Sidecar 容器，自动从 对象存储（S3）、PVC、宿主机目录拉取模型文件至 Pod； |
| **Predictor Runtimes**        | 官方预置的多框架推理镜像（Triton、TorchServe、TensorFlow Serving、vLLM、MLServer 等） |
| **KServe Agent**              | Sidecar 容器，负责指标采集、日志转发、健康检查、推理协议适配 |
| **Ingress Gateway**           | 基于 Istio 或 KServe Gateway，统一推理流量入口，实现路由、限流、灰度、鉴权 |
| **Autoscaler**                | 两种伸缩模式： <br />• **Standard 模式**：基于 K8s HPA（CPU/QPS 指标），不支持缩容至零 <br />• **Knative 模式**：基于 Knative Autoscaler，支持零副本缩容 |





## 二、整体架构



### 1、KServe 全局架构



KServe 整体架构分为四层，完全基于 Kubernetes 生态扩展：

| 层级                         | 组件说明                                                     |
| :--------------------------- | :----------------------------------------------------------- |
| **控制平面层**               | KServe Controller、CRD（`InferenceService`、`ClusterServingRuntime`），依赖 Kubernetes API Server、etcd、调度器及 GPU 调度插件 |
| **流量管理层**               | Istio Gateway / Knative Ingress 提供外部流量入口；<br />VirtualService 实现流量切分、灰度、路由规则 |
| **推理运行时层**（Pod 内部） | Model Storage Initializer + KServe Agent Sidecar + Predictor/Transformer/Explainer 主容器 |
| **存储与可观测层**           | • **存储**：MinIO/S3/云对象存储/PVC 等 <br />• **监控**：Prometheus + Grafana 采集推理 QPS、延迟、错误率 <br />• **日志**：Loki/ELK 采集推理输入输出日志 <br />• **链路追踪**：Jaeger/Zipkin 追踪推理请求全链路 |



## 三、安装KServe



### 1、前置环境准备

- 可用 Kubernetes 集群 1.24+；
- 已安装 Helm 3；
- 若使用 GPU 推理：部署 nvidia-device-plugin；



### 2、拉取源码

```bash
# 克隆 kserve 官方代码仓库
git clone https://github.com/kserve/kserve.git

cd kserve

# 切换稳定版本，本文示例 v0.18.0
git checkout release-0.18
```


### 3、一键安装脚本（推荐）

KServe 源码提供了自动化安装脚本 `hack/kserve-install.sh`，可一键安装所有依赖（cert-manager、Istio、Knative 等）及 KServe 自身，比手动 Helm 操作简便许多。



#### 脚本核心参数说明

| 参数 | 含义 | 选项 |
|------|------|------|
| `--kserve-version` | KServe 版本 | `v0.18.0` 等 |
| `--type` | 安装哪些组件 | `kserve`（核心）/ `localmodel`（本地模型节点）/ `llmisvc`（LLM 推理服务） |
| `--standard` | Standard 模式 | 无 Istio/Knative 依赖，最简单 |
| `--knative` | Knative 模式 | 自动装 Istio + Knative，支持缩容到零 |
| `--deps-only` | 只装依赖 | 只装 Istio、Knative、cert-manager，不装 KServe 本身 |

#### 场景化安装命令（按需选择）

1. **新手快速体验（传统机器学习模型）**：Standard 模式，KServe 核心 + 本地模型挂载

```bash
cd kserve/

# 安装内容：KServe 核心 + 本地模型节点支持。
./hack/kserve-install.sh \
  --kserve-version v0.18.0 \
  --type kserve,localmodel \
  --standard
```

2. **LLM 大模型部署（vLLM 推理）**：Standard 模式，集成 LLM 专用运行时

```bash
./hack/kserve-install.sh \
  --kserve-version v0.18.0 \
  --type kserve,llmisvc,localmodel \
  --standard
```

3. **已有 Istio/Knative，仅补充依赖**


```bash
./hack/kserve-install.sh \
  --kserve-version v0.18.0 \
  --type kserve,llmisvc,localmodel \
  --knative \
  --deps-only
```

4. **全新完整 Serverless 平台（支持 0 缩容）**

```bash
./hack/kserve-install.sh \
  --kserve-version v0.18.0 \
  --type kserve,llmisvc,localmodel \
  --knative
```

> 安装耗时参考：Standard 模式 3~5 分钟；Knative 模式含 Istio+Knative 部署，耗时 8~12 分钟。（视网络环境而定）



### 4、手动分步安装（理解每一步在做什么）

> 上一节的脚本帮你一键搞定，适合快速上手。这一节把每个组件拆开装，适合**离线环境、内网部署、或者你想搞清楚 KServe 到底装了哪些东西**。

整个安装分为四步，按顺序执行：

```
步骤一：装 CRD（告诉 K8s 有 InferenceService 这种东西）
   ↓
步骤二：装运行时配置（告诉 KServe 支持哪些推理框架）
   ↓
步骤三：装 KServe 控制器（核心引擎，真正干活的组件）
   ↓
步骤四：装扩展资源（本地模型节点、LLM 推理服务等，可选）
```

#### 步骤一：安装 CRD（自定义资源定义）

CRD 是基础，必须先装。根据你的需求选装：

```bash
# 必装：核心CRD
# 在线环境
helm install kserve-crd oci://ghcr.io/kserve/charts/kserve-crd \
  --version v0.18.0 \
  --namespace kserve \
  --create-namespace

# 离线环境（先用 git clone 拉源码到本地）
helm install kserve-crd ./charts/kserve-crd \
  --namespace kserve \
  --create-namespace


# 可选：本地模型节点 CRD（宿主机HostPath挂载模型使用）
helm install kserve-localmodel-crd ./charts/kserve-localmodel-crd \
  --namespace kserve \
  --create-namespace

# 可选：LLM 推理服务 CRD（部署 vLLM 等大语言模型时需要）
helm install kserve-llmisvc-crd ./charts/kserve-llmisvc-crd \
  --namespace kserve \
  --create-namespace
```

> **选装建议**：新手先把第一条核心 CRD 装了就行，后面两条用到再装。

#### 步骤二：安装推理运行时配置

这一步告诉 KServe"我支持哪些推理框架"。`servingruntime` 控制传统模型运行时（SKLearn/PyTorch/TensorFlow），`llmisvcConfigs` 控制大模型运行时（vLLM 等）。

```bash
helm install kserve-runtime-configs oci://ghcr.io/kserve/charts/kserve-runtime-configs \
  --set kserve.servingruntime.enabled=true \
  --set kserve.llmisvcConfigs.enabled=true \
  --version v0.18.0 \
  --namespace kserve

# 如果安装中断或参数改错了，可使用 upgrade（无需卸载重装）
helm upgrade -i kserve-runtime-configs \
  oci://ghcr.io/kserve/charts/kserve-runtime-configs \
  --set kserve.servingruntime.enabled=true \
  --set kserve.llmisvcConfigs.enabled=true \
  --version v0.18.0 \
  --namespace kserve
```

#### 步骤三：安装 KServe 控制器（二选一）

这是核心组件，负责监听 InferenceService 并创建对应的 Deployment/Service 等资源。

```bash
# 模式 A：Standard 标准模式（推荐生产使用）
helm install kserve-resources oci://ghcr.io/kserve/charts/kserve-resources \
  --version v0.18.0 \
  --namespace kserve \
  --set kserve.controller.deploymentMode=Standard \
  --wait

# 离线环境用本地 Chart
helm install kserve-resources ./charts/kserve-resources \
  --version v0.18.0 \
  --namespace kserve \
  --set kserve.controller.deploymentMode=Standard \
  --wait





# 模式 B：Knative Serverless 模式
# 前置条件：已安装 Istio + Knative Serving
# 优势：支持缩容到零，按请求自动扩缩
helm install kserve-resources oci://ghcr.io/kserve/charts/kserve-resources \
  --version v0.18.0 \
  --namespace kserve \
  --set kserve.controller.deploymentMode=Knative \
  --wait
```

#### 步骤四：安装扩展资源（可选）

如果你在步骤一装了对应的 CRD，这里装对应的控制器：

```bash
# 本地模型节点控制器（配合步骤一的 localmodel CRD）
helm install kserve-localmodel-resources ./charts/kserve-localmodel-resources \
  --version v0.18.0 \
  --namespace kserve \
  --wait

# LLM 推理服务控制器（配合步骤一的 llmisvc CRD）
helm install kserve-llmisvc-resources ./charts/kserve-llmisvc-resources \
  --version v0.18.0 \
  --namespace kserve \
  --set kserve.controller.deploymentMode=Standard \
  --wait
```

#### 快速对照：最低安装 vs 完整安装

| 场景 | 需要执行的步骤 |
|------|--------------|
| **最小化体验**（只跑 SKLearn/PyTorch） | 步骤一（核心CRD）→ 步骤二 → 步骤三 |
| **生产标准部署**（传统模型 + 本地存储） | 步骤一（核心 + localmodel CRD）→ 步骤二 → 步骤三 → 步骤四（localmodel） |
| **LLM 大模型部署**（vLLM 等） | 步骤一（核心 + llmisvc CRD）→ 步骤二 → 步骤三 → 步骤四（llmisvc） |
| **全家桶**（什么都装） | 步骤一（全部 CRD）→ 步骤二 → 步骤三 → 步骤四（全部） |




### 5、安装验证

无论你用脚本还是手动安装，装完都跑一遍下面的检查，确认一切就绪。

#### 5.1 必检项（三条全部通过即为成功）

```bash
# ① Controller 是否在运行
kubectl get pods -n kserve
# 期望看到：kserve-controller-manager-xxx   2/2   Running

# ② InferenceService CRD 是否注册成功
kubectl get crd | grep inferenceservice
# 期望看到：inferenceservices.serving.kserve.io

# ③ 推理运行时是否就绪
kubectl get clusterservingruntimes
# 期望看到：多个运行时（Triton、TorchServe 等），状态就绪
```

#### 5.2 可选检查项

```bash
# 检查 LLM CRD（若已安装）
kubectl get crd | grep llminferenceservices

# 检查 Envoy Gateway（若已安装）
kubectl get pods -n envoy-gateway-system

# 查看 KServe 版本信息
kubectl get crd inferenceservices.serving.kserve.io -o yaml | grep -A 5 "versions:"
```



## 四、使用

本节演示如何使用 KServe 部署一个 Hugging Face 上的小型大语言模型，并通过 hostPath 直接挂载本地模型文件。

完整流程：HuggingFace 模型下载 → K8s 资源 YAML 编写 → 部署验证 → 接口调用测试



### 1、下载Hugging Face模型到本地



#### ①、安装python环境

```bash
# 安装python3主程序 + 工具
sudo apt install -y python3 python3-dev python3-venv
# 安装 pip3（Python 包管理器，用来装 huggingface_hub）
sudo apt install -y python3-pip

# 查看python版本
python3 --version
# 查看pip版本
pip3 --version

# 配置软连接，设置 python 指向 python3（方便直接敲 python）
sudo ln -s /usr/bin/python3 /usr/bin/python
sudo ln -s /usr/bin/pip3 /usr/bin/pip
```



#### ②、安装huggingface-cli

```bash
# 建个虚拟环境
python3 -m venv venv && source venv/bin/activate

# 国内清华源加速安装
# 加-U：强制更新到最新版
pip install huggingface_hub -i https://pypi.tuna.tsinghua.edu.cn/simple
pip install -U huggingface_hub -i https://pypi.tuna.tsinghua.edu.cn/simple

# 上面安装报错PEP 668：加参数 --break-system-packages 绕过限制
pip install -U huggingface_hub -i https://pypi.tuna.tsinghua.edu.cn/simple --break-system-packages

# 旧版使用 huggingface-cli ，新版改为： hf
hf version
# 输出版本号即正常，例如 huggingface_hub version 0.26.2


# 私有模型才需要登录（公开模型不用登录）
hf auth login


# 标准下载命令
# 参数说明：
# Qwen/Qwen3-0.6B：模型仓库名
# --local-dir：本地存放路径（给 KServe 挂载用）
# 新版没有下面这2个参数了
# --local-dir-use-symlinks False：不生成缓存软链接，直接存完整文件，挂载 PVC 不会丢文件
# --resume-download：断点续传，断网后重新执行接着下
hf download \
Qwen/Qwen3-0.6B \
--local-dir /data/models/Qwen3-0.6B 

# 下载Qwen2.5-0.5B
hf download \
Qwen/Qwen2.5-0.5B-Instruct \
--local-dir /opt/models/Qwen2.5-0.5B-Instruct
```

![](kserve-models.png)



##### 配置国内镜像加速

```bash
# 临时生效（当前终端）
export HF_ENDPOINT=https://hf-mirror.com

# 永久生效（所有终端）
echo "export HF_ENDPOINT=https://hf-mirror.com" >> ~/.bashrc
source ~/.bashrc

```



### 2、配置yaml



```bash
# ==========================================================
# 0. 命名空间定义
# ==========================================================
apiVersion: v1
kind: Namespace
metadata:
  name: edge-ai
---
# ==========================================================
# 1. InferenceService（使用 hostPath 直挂本地模型）
# ==========================================================
apiVersion: serving.kserve.io/v1beta1
kind: InferenceService
metadata:
  name: qwen2-05b
  namespace: edge-ai
spec:
  predictor:
    minReplicas: 1
    maxReplicas: 1
    nodeSelector:
      kubernetes.io/hostname: edge01          # 指定模型所在节点
    tolerations:                           
    - key: node-role.kubernetes.io/edge
      operator: Exists
      effect: NoSchedule
    containers:
    - name: vllm
      image: vllm/vllm-openai-cpu:v0.25.0-x86_64   # CPU 版 vLLM 镜像
      imagePullPolicy: IfNotPresent
      command: ["vllm", "serve"]
      args:
        - /mnt/models
        - --served-model-name=Qwen2.5-0.5B-Instruct
        - --port=8080
        - --trust-remote-code
        - --dtype=bfloat16
        - --max-model-len=1024
        - --tensor-parallel-size=1
        - --pipeline-parallel-size=1
        - --max-num-seqs=1
      env:
        - name: VLLM_ENABLE_V1_MULTIPROCESSING
          value: "0"
        - name: OMP_NUM_THREADS
          value: "6"
        - name: VLLM_CPU_OMP_THREADS_BIND
          value: "auto"
        - name: VLLM_CPU_KVCACHE_SPACE
          value: "3"
      resources:
        limits:
          cpu: "8"
          memory: "10Gi"
        requests:
          cpu: "4"
          memory: "8Gi"
      volumeMounts:
        - name: model-storage
          mountPath: /mnt/models
          readOnly: true
        - name: shm
          mountPath: /dev/shm
    volumes:
    - name: model-storage
      hostPath:
        path: /opt/models/Qwen2.5-0.5B-Instruct   # 宿主机模型路径
        type: Directory
    - name: shm
      emptyDir:
        medium: Memory
        sizeLimit: 8Gi
```



### 3、部署



```bash
# 部署
kubectl apply -f qwen2-05b-vllm-edge.yaml

# 查看推理服务状态
kubectl get inferenceservice -n edge-ai
# 查看Pod运行日志，排查模型加载异常
kubectl logs -f deploy/qwen2-05b-predictor -n edge-ai

# 获取服务端点
kubectl get svc -n edge-ai qwen2-05b-predictor -o wide


# 删除
kubectl delete inferenceservice qwen2-05b
# 或全删除
kubectl delete -f qwen2-05b-vllm-edge.yaml

# 重新应用
kubectl apply -f qwen2-05b-vllm-edge.yaml
```





![](kserve-logs.png)

启动成功，监听8080端口

![](kserve-pod.png)



### 4、测试



```bash
# 测试-请求模型列表
curl http://10.88.0.29:8080/v1/models

# 对话推理接口调用
curl http://10.88.0.29:8080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model":"Qwen2.5-0.5B-Instruct","max_tokens":100,"messages":[{"role":"user","content":"你好"}]}'
```



![](kserve-request.png)



## 五、最后

大部分内容是基于我的笔记记录，更多内容可参考官网：

[https://kserve.github.io/website/docs/install/overview](https://kserve.github.io/website/docs/install/overview)

