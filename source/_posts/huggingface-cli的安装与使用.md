---
title: huggingface-cli的安装与使用
tags: [Hugging Face]
categories: AI
date: 2026-08-01 14:56:33
---




`hf`（原 huggingface-cli）作为 Hugging Face Hub 官方原生命令行工具，一站式搞定模型 / 数据集拉取上传、仓库运维、缓存清理、镜像加速、账号权限管理全流程，是 AI 工程、推理部署、离线模型本地化必备利器。


<!--more-->



## 一、安装python环境

在安装 CLI 工具前，请确保系统已具备 Python 3 环境及相关包管理工具。

```bash
# 安装python3主程序 + 工具
sudo apt install -y python3 python3-dev python3-venv
# 安装 pip3（Python 包管理器）
sudo apt install -y python3-pip

# 查看python版本
python3 --version
# 查看pip版本
pip3 --version

# 配置软连接，设置 python 指向 python3（方便直接敲 python）
sudo ln -s /usr/bin/python3 /usr/bin/python
sudo ln -s /usr/bin/pip3 /usr/bin/pip
```



## 二、安装方式选择

推荐使用 **pipx** 或 **虚拟环境** 两种方式安装 `huggingface_hub` 包，以获得干净隔离的运行环境。

### 1、通过pipx安装

`pipx` 专为 Python 命令行工具设计，会自动为每个工具创建独立虚拟环境，并将可执行文件链接到系统 PATH，避免依赖冲突。

- `pipx` 可以通俗地理解为：**专门为“安装和运行 Python 命令行工具”而生的应用商店**。
- 它在后台自动为**每一个**你要装的工具（比如 `huggingface-cli`、`black`、`httpie`）创建一个**独立的虚拟环境（venv）**。
- 然后，它**只把那个环境里的可执行命令（`bin` 目录）**，通过软链接（symlink）放到系统的 `PATH` 环境变量里。



```bash
# 安装 pipx
apt install -y pipx


# 用 pipx 全局安装 huggingface_hub
pipx install huggingface_hub


# 安装成功,把 ~/.local/bin 加到系统 PATH 
# 这个命令会自动修改你的 Shell 配置文件（如 ~/.bashrc），把 ~/.local/bin 添加进去
pipx ensurepath

# 重新加载配置
source ~/.bashrc


# 验证安装
hf version 

# 列出所有通过 pipx 安装的工具
pipx list


# 升级某个工具
pipx upgrade huggingface_hub

# 卸载（干干净净，不留任何依赖残留）
pipx uninstall huggingface_hub
```



![](pipx-install.png)



### 2、通过虚拟环境安装



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
```



## 三、基础配置




### 1、配置国内镜像加速

```bash
# 临时生效（当前终端）
export HF_ENDPOINT=https://hf-mirror.com

# 永久生效（所有终端）
echo "export HF_ENDPOINT=https://hf-mirror.com" >> ~/.bashrc
source ~/.bashrc

```



### 2、登录认证

公开模型无需登录，只有访问私有模型或执行上传、创建等写操作时才需要认证。

```bash
# 交互式登录（OAuth Device Code 流程）
hf auth login

# 查看当前登录用户
hf auth whoami

# 登出
hf auth logout

# 切换或管理已存储的访问令牌
hf auth switch
hf auth list
```





## 四、常用命令

基础命令



```bash
# 显示帮助信息
hf --help

# 安装 Shell 补全 (bash/zsh/fish)
hf --install-completion

# 显示补全脚本（供复制或自定义）
hf --show-completion

# 查看版本
hf version

# 查看环境信息
hf env

# 更新 CLI 到最新版本
hf update
```





### 1、下载模型/数据集

```bash
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


# 下载整个模型（自动缓存到 ~/.cache/huggingface/hub）
hf download meta-llama/Llama-3.2-1B-Instruct

# 下载数据集（指定仓库类型）
hf download --repo-type dataset username/dataset-name

# 指定版本（分支 / tag / commit）
hf download meta-llama/Llama-3.2-1B-Instruct --revision main

# 过滤文件（glob 模式）
hf download bigscience/bloom --include "*.json"
hf download bigscience/bloom --exclude "*.bin"

# 下载到指定本地目录（绕过缓存，适合挂载 PVC 等场景）
hf download Qwen/Qwen3-Embedding-4B --local-dir /data/models/Qwen3-Embedding-4B

# 强制重新下载（覆盖已有）
hf download meta-llama/Llama-3.2-1B-Instruct --force-download

# 预览要下载的文件（不实际下载）
hf download meta-llama/Llama-3.2-1B-Instruct --dry-run

# 调整并发线程数（默认 8）
hf download meta-llama/Llama-3.2-1B-Instruct --max-workers 4

```



### 2、上传文件

```bash
# 上传当前目录所有内容到仓库根目录（自动创建仓库）
hf upload my-cool-model . .

# 上传单个文件
hf upload my-cool-model ./model.safetensors

# 指定远程路径
hf upload my-cool-model ./data/train.csv remote/data/

# 上传到数据集或 Space 仓库
hf upload --repo-type dataset username/dataset-name ./data/ remote/data/
hf upload --repo-type space username/space-name ./app/ .

# 私有仓库或指定版本
hf upload my-cool-model . . --private --revision v1.0
```



### 3、仓库管理



```bash
# 创建新仓库（模型类型）
hf repo create my-new-model
# 创建数据集或私有仓库
hf repo create my-dataset --repo-type dataset --private

# 删除仓库（谨慎操作）
hf repo delete my-old-model

# 移动 / 重命名仓库
hf repo move old-namespace/my-model new-namespace/my-model
hf repo rename my-model new-name

# 分支管理
hf repo branch create my-branch
hf repo branch delete my-branch
hf repo branch list

# 修改仓库设置（可见性、门控访问等）
hf repo settings my-repo --visibility public
hf repo settings my-repo --gated
```



### 4、查看与管理缓存

```bash
# 列出缓存中的所有仓库
hf cache ls

# 显示每个仓库的版本详情
hf cache ls --revisions

# 验证仓库完整性（示例：gpt2）
hf cache verify gpt2

# 指定自定义缓存目录
hf cache ls --cache-dir /custom/cache
```





### 5、模型 / 数据集 / Spaces 查询

```bash
# 搜索模型
hf models ls --search "Qwen3" --author Qwen --limit 10

# 查看模型内文件列表
hf models ls Qwen/Qwen-Image-2512 --path ./

# 查看模型详细信息（标签、下载量等）
hf models info Qwen/Qwen-Image-2512

# 数据集类似操作
hf datasets ls --search "code" --sort downloads
# 列出数据集内的文件
hf datasets ls HuggingFaceFW/fineweb --path data/
hf datasets info HuggingFaceFW/fineweb

# Spaces 操作
hf spaces ls --author username
hf spaces info username/my-space
hf spaces logs username/my-space   # 查看构建日志
```



### 6、文件复制与同步

```bash
# 从 Hub 复制到本地
hf cp hf://username/my-model/config.json ./config.json

# 从本地复制到 Hub
hf cp ./config.json hf://username/my-model/config.json

# Hub 仓库间复制
hf cp hf://src/repo/file.txt hf://dst/repo/file.txt

# 递归复制整个目录
hf cp -r hf://username/my-model/ ./my-model-backup/

# 与 S3 等存储桶同步
hf sync ./local_dir/ s3://my-bucket/remote_dir/

# 同步到 Hub 仓库（需先创建仓库）
hf sync ./local_dir/ hf://username/my-model/

# 可设置排除模式、干运行等
hf sync ./data/ hf://username/dataset/data/ --exclude "*.tmp" --dry-run
```



### 7、其他命令大全


```bash
# -----------------------------------------------------------------------------
# 一、讨论与 PR (hf discussions)
# -----------------------------------------------------------------------------

# 查看仓库的讨论/PR 列表
hf discussions list username/my-repo

# 创建新讨论
hf discussions create username/my-repo --title "Bug report" --description "..."

# 创建 Pull Request
hf discussions create username/my-repo --title "Fix bug" --type pr

# 查看特定讨论详情
hf discussions view username/my-repo 123

# 发表评论
hf discussions comment username/my-repo 123 --message "LGTM"

# 合并 PR
hf discussions merge username/my-repo 123

# 关闭讨论/PR
hf discussions close username/my-repo 123

# -----------------------------------------------------------------------------
# 二、Inference Endpoints (hf endpoints)
# -----------------------------------------------------------------------------

# 列出所有端点
hf endpoints ls

# 创建端点（需要指定模型、实例类型等）
hf endpoints create --name my-endpoint --model my-model --type gpu-small

# 查看端点详情
hf endpoints info my-endpoint

# 更新端点配置
hf endpoints update my-endpoint --instance-type gpu-large

# 删除端点
hf endpoints delete my-endpoint

# -----------------------------------------------------------------------------
# 三、Jobs (hf jobs)
# -----------------------------------------------------------------------------

# 列出当前用户的所有 Jobs
hf jobs ls

# 运行一个新 Job（需指定配置）
hf jobs run --script train.py --requirements requirements.txt

# 查看 Job 状态
hf jobs info job-id

# 取消 Job
hf jobs cancel job-id

# 查看 Job 日志
hf jobs logs job-id

# -----------------------------------------------------------------------------
# 四、Sandbox (hf sandbox)
# -----------------------------------------------------------------------------

# 创建并运行一个沙盒环境（用于交互式开发）
hf sandbox create --name my-sandbox --cpu 2 --memory 8GB

# 列出沙盒
hf sandbox ls

# 进入沙盒（SSH 或 Web terminal）
hf sandbox ssh my-sandbox

# 停止沙盒
hf sandbox stop my-sandbox

# 删除沙盒
hf sandbox delete my-sandbox

# -----------------------------------------------------------------------------
# 五、Collections (hf collections)
# -----------------------------------------------------------------------------

# 查看某个集合详情
hf collections view username/my-collection

# 列出用户的集合
hf collections list username

# 创建新集合
hf collections create --title "My Collection" --description "..."

# 向集合添加条目（模型/数据集/Spaces）
hf collections add username/my-collection --item hf://username/model

# 从集合移除条目
hf collections remove username/my-collection --item hf://username/model

# -----------------------------------------------------------------------------
# 六、Papers (hf papers)
# -----------------------------------------------------------------------------

# 列出论文
hf papers ls

# 查看论文详情
hf papers info paper-id

# 上传论文（PDF 等）
hf papers upload ./paper.pdf --title "My Paper" --authors "Me"

# -----------------------------------------------------------------------------
# 七、Skills (hf skills)
# -----------------------------------------------------------------------------

# 管理 AI 助手的技能（Skill）
hf skills ls
hf skills create --name my-skill --description "..."
hf skills update my-skill --config config.yaml
hf skills delete my-skill

# -----------------------------------------------------------------------------
# 八、Webhooks (hf webhooks)
# -----------------------------------------------------------------------------

# 列出 Webhook
hf webhooks ls

# 创建 Webhook（指定 URL 和事件）
hf webhooks create --url https://example.com/webhook --events push,pr

# 查看 Webhook 详情
hf webhooks info webhook-id

# 更新 Webhook
hf webhooks update webhook-id --url https://new-url.com

# 删除 Webhook
hf webhooks delete webhook-id

# -----------------------------------------------------------------------------
# 九、存储桶 (hf buckets)
# -----------------------------------------------------------------------------

# 列出存储桶
hf buckets ls

# 创建存储桶
hf buckets create my-bucket

# 查看存储桶信息
hf buckets info my-bucket

# 删除存储桶
hf buckets delete my-bucket

# 存储桶内文件操作（可与 cp, sync 结合使用）

# -----------------------------------------------------------------------------
# 十、扩展管理 (hf extensions)
# -----------------------------------------------------------------------------

# 列出已安装的扩展
hf extensions ls

# 安装扩展
hf extensions install my-extension

# 卸载扩展
hf extensions uninstall my-extension

# 更新扩展
hf extensions update my-extension

# 别名：hf ext

# -----------------------------------------------------------------------------
# 十一、常用工作流示例
# -----------------------------------------------------------------------------

# 1. 登录并下载模型
hf auth login
hf download meta-llama/Llama-3.2-1B-Instruct

# 2. 创建私有模型仓库并上传文件
hf repo create my-org/my-model --private
hf upload my-org/my-model ./model_files/ .

# 3. 下载数据集到本地指定目录
hf download --repo-type dataset username/dataset --local-dir ./dataset

# 4. 查看缓存并清理（手动删除旧版本）
hf cache ls --revisions
# 然后可通过 rm -rf 删除对应缓存目录（需谨慎）

# 5. 使用 hf cp 快速获取单个配置文件
hf cp hf://microsoft/DialoGPT-medium/config.json .

# 6. 同步本地数据到数据集仓库
hf sync ./data/ hf://username/my-dataset/data/ --exclude "*.log"

# -----------------------------------------------------------------------------
# 十二、帮助与文档
# -----------------------------------------------------------------------------

# 任何子命令都可追加 --help 获取详细帮助
hf auth --help
hf download --help
hf upload --help
hf repo create --help

# 官方文档：https://huggingface.co/docs/huggingface_hub/en/guides/cli
# 完整参考：https://huggingface.co/package_reference/cli
```