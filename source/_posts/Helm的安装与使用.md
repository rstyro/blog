---
title: Helm的安装与使用
tags: [k8s,Helm,Kubernetes]
categories: 网络运维
date: 2026-07-04 12:03:01
updated: 2026-07-04 12:03:01
---


玩 K8s 的朋友肯定都有过这种体验：部署一个微服务，Deployment、Service、ConfigMap、Ingress…… 一堆 YAML 文件写得头晕眼花。换个环境还得挨个改配置，一旦升级出错，回滚更是噩梦。

这时候，你就需要 Helm 了。

作为 K8s 事实上的“包管理器”，Helm 能把这些零散的资源打包，让你像用 `apt` 或 `yum` 装软件一样，一条命令搞定复杂应用的部署。这篇文章不整虚的，直接带你搞懂 Helm 的核心逻辑，并手把手完成安装和基础配置。

<!--more-->


## 一、为什么 K8s 需要 Helm？

### 1.1 原生 Kubernetes 部署的痛点
假设你要部署一个微服务应用，它通常包含：
- Deployment（部署）
- Service（服务暴露）
- ConfigMap（配置）
- Secret（敏感信息）
- Ingress（路由）
- PersistentVolumeClaim（存储）

你需要维护数十甚至上百个 YAML 文件，且每个环境（开发、测试、生产）的配置还有差异。更麻烦的是，**版本升级时你要小心翼翼地修改参数，回滚时更是噩梦**——因为 Kubernetes 原生并不提供“应用级”的版本管理。

### 1.2 Helm 的解法
Helm 的出现，正是为了解决上述问题。它的灵感来自 Linux 的包管理器（如 apt、yum）——就像 `apt install nginx` 能帮你搞定所有依赖和配置一样，Helm 让你用一条命令就能安装一个完整的应用栈。

- **诞生时间**：2015 年，由 Deis 公司开源，后来成为 CNCF（云原生计算基金会）的顶级项目。
- **核心目标**：定义、安装、升级复杂的 Kubernetes 应用，并管理其生命周期。

### 1.3 Helm 的核心概念
要理解 Helm，只需记住三个关键词：

| 概念 | 类比 | 解释 |
| :--- | :--- | :--- |
| **Chart** | 软件包（如 .deb/.rpm） | 包含运行一个应用所需的所有 K8s 资源 YAML 模板和元数据。 |
| **Release** | 运行中的实例（如一个已安装的软件） | 当你在集群中安装一个 Chart 后，就产生了一个 Release，可以多次安装同一个 Chart 得到多个 Release（如 dev-nginx、prod-nginx）。 |
| **Repository** | 软件源（如 APT 仓库） | 存放 Chart 的 HTTP 服务器，Helm 从仓库中拉取 Chart。 |

有了这三个抽象，Helm 就能像管理软件包一样管理你的应用。

---

## 二、Helm的核心能力

日常使用中，Helm 主要帮你干这几件事：

1. **一键部署与升级**：用 `helm install` 部署，用 `helm upgrade` 更新。改个配置或换个镜像，K8s 资源会自动滚动更新。
2. **后悔药（回滚）**：Helm 会记录每次升级的 Revision（修订版号）。生产环境出事故时，一句 `helm rollback` 就能瞬间回到上一个正常版本。
3. **模板化配置**：Chart 内部使用 Go 模板。你只需维护一个 `values.yaml`，就能用同一套模板适配 dev、test、prod 不同环境。
4. **依赖与钩子**：支持应用依赖管理（如 WordPress 自动拉取 MySQL）；支持生命周期钩子（Hooks），可以在安装前后自动执行数据库初始化等 Job。



---

## 三、Helm安装指南

*注：Helm v3 之后已经移除了服务端组件 Tiller，所以现在安装 Helm，实际上就是安装客户端 CLI 工具。*

这里提供两种最常用的安装方式。

### 3.1 方式一：官方脚本一键安装（推荐，最快捷）

适合所有 Linux 发行版，脚本会自动检测系统架构并下载对应二进制文件。

```bash
# 下载安装脚本并执行（自动检测最新版本）
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4
chmod 700 get_helm.sh
./get_helm.sh

# 或者简单粗暴的一行命令版：
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4 | bash
```

**原理**：脚本会检测系统架构，从 GitHub Releases 下载对应二进制文件，并放到 `/usr/local/bin/helm`。

安装完成后，检查版本：
```bash
helm version
# 输出类似: version.BuildInfo{Version:"v3.18.5", ...}
```



> *国内网络如果拉取 GitHub 脚本较慢，建议配置代理，或者直接使用下面的 APT 方式*

### 3.2 方式二：APT 包管理器安装（适合 Ubuntu/Debian）

利用 APT 管理，优点是支持签名校验和后续的自动更新。

```bash
# 定义Helm官方APT仓库密钥指纹，用于校验密钥合法性，防止密钥被篡改
HELM_BUILDKITE_APT_KEY_ID="DDF78C3E6EBB2D2CC223C95C62BA89D07698DBC6"

# 安装必备工具：curl下载文件、gpg校验密钥、apt-transport-https支持https源；--yes自动确认安装
sudo apt-get install curl gpg apt-transport-https --yes

# 静默下载Helm仓库GPG公钥，保存到临时目录，无TMPDIR则默认存/tmp/helm.gpg
curl -fsSL https://packages.buildkite.com/helm-linux/helm-debian/gpgkey > "${TMPDIR:-/tmp}/helm.gpg"

# 校验下载的公钥指纹和预设指纹是否一致，防止中间人篡改密钥
# gpg --show-keys --with-colons：机器可读格式输出密钥信息
# awk -F: '$1 == "fpr" {print $10}'：提取指纹字段
# head -n 1：取第一条指纹
# 不一致则打印错误并直接退出脚本
if [ "$(gpg --show-keys --with-colons "${TMPDIR:-/tmp}/helm.gpg" | awk -F: '$1 == "fpr" {print $10}' | head -n 1)" != "${HELM_BUILDKITE_APT_KEY_ID}" ]; then echo "ERROR: Unexpected Helm APT key ID: potential key compromise"; exit 1; fi

# 将明文GPG密钥转为apt兼容的二进制密钥，保存到系统可信密钥目录，屏蔽标准输出
cat "${TMPDIR:-/tmp}/helm.gpg" | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null

# 写入Helm软件源配置文件，指定该源使用上面导入的密钥校验包签名
echo "deb [signed-by=/usr/share/keyrings/helm.gpg] https://packages.buildkite.com/helm-linux/helm-debian/any/ any main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list

# 更新apt软件源索引，读取刚添加的helm源
sudo apt-get update

# 通过apt包管理器安装helm客户端
sudo apt-get install helm


# 卸载
apt remove helm
```



### 3.3 验证安装与配置

安装完毕后，运行 `helm version`，如果显示客户端版本信息，则成功。

> **注意**：Helm 默认使用 `~/.kube/config` 与集群通信，所以请确保你的 `kubectl` 已正确配置。如果没有，Helm 命令会报错。





![](version.png)



## 四、日常高频命令速查

装好 Helm 后，把下面这些命令混个脸熟，日常运维基本够用了。

### 4.1 仓库管理
```bash
# 添加仓库（以知名的 Bitnami、Higress 为例）
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add higress https://higress.io/helm-charts

# 更新仓库索引（安装前务必执行）
helm repo update

# 查看已添加的仓库列表
helm repo list

# 删除仓库
helm repo remove higress
```

### 4.2 安装与升级
```bash
# 基本安装（创建命名空间）
helm install my-nginx bitnami/nginx -n my-ns --create-namespace

# 指定自定义 values.yaml 安装
helm install my-app ./my-chart -f values-prod.yaml

# 安装特定版本
helm install my-app bitnami/nginx --version 15.0.0

# 升级（如果 release 不存在则执行 install）
helm upgrade my-app bitnami/nginx -n my-ns --install -f new-values.yaml
```

### 4.3 查看与调试
```bash
# 列出所有命名空间的 Release
helm list -A

# 查看 Release 状态
helm status my-app -n my-ns

# 查看历史版本（含 Revision 编号）
helm history my-app -n my-ns

# 只渲染 YAML 而不实际安装（用于调试模板）
helm template my-app ./my-chart

# 模拟执行（dry-run）
helm upgrade my-app ./my-chart --dry-run
```

### 4.4 回滚与卸载
```bash
# 回滚到上一个版本
helm rollback my-app -n my-ns

# 回滚到指定 Revision（如 2）
helm rollback my-app 2 -n my-ns

# 卸载 Release
helm uninstall my-app -n my-ns
```

### 4.5 导出配置与查看 Chart 信息
```bash
# 查看 Chart 的默认 values（调参必看）
helm show values bitnami/nginx

# 查看 Chart 的 README
helm show readme bitnami/nginx

# 导出当前 Release 的已生效配置（用于备份）
helm get values my-app -n my-ns -o yaml > current-values.yaml
```

---

## 五、最佳实践与避坑指南

1. **始终使用 `--dry-run` 预览**：在正式安装或升级前，先执行 `--dry-run` 和 `--debug`，检查生成的 YAML 是否符合预期，避免直接犯错。

2. **管理 values 文件**：将不同环境的配置（dev/staging/prod）分离，不要直接在命令行传参，否则难以维护。

3. **善用 Helm 钩子（Hooks）**：如果 Chart 提供了 `pre-install`、`post-upgrade` 等钩子，利用它们来做数据库迁移等初始化操作。

4. **注意 CRD 管理**：Helm 默认不会升级 CRD（自定义资源），请参考 Chart 官方文档单独处理。

5. **国内网络优化**：如果从 GitHub 下载脚本慢，可以设置代理或使用 APT 方式（已经过 CDN 加速）。



## 六、结语

Helm 早就成了 K8s 生态里绕不开的基础设施，把 Helm 玩溜了，你的 K8s 交付效率绝对能翻倍。

从这篇的安装和基础命令开始，你已经掌握了 Helm 的核心玩法。接下来，我打算写一期实战，用 Helm 部署  **NFS 动态存储 Provisioner** 和 **Harbor 镜像仓库**，真正将理论落地到生产级别的环境中。



大家在安装或使用 Helm 时踩过什么坑？或者有什么好用的私有 Chart 仓库推荐？欢迎在评论区交流，我们下期见。
