---
title: 安装Ollama与使用
tags: [AI]
categories: AI
date: 2025-10-24 19:09:52
---

## 一、安装Ollama与使用

Ollama是一个轻量级、模块化的开源框架，采用模块化设计支持多模型并行运行，专为在本地计算机上运行、部署和管理大型语言模型（LLM）而设计



选择Ollama进行本地化部署有几个核心优势：

- **数据隐私保障**：敏感数据完全在本地处理，不会外传
- **定制化开发**：可以自由修改模型参数和提示词
- **成本可控**：一次性部署，无需持续支付API调用费用
- **离线可用**：无网络环境仍可运行AI能力
- **多模型支持**：支持同时运行多个不同模型，满足多样化需求



### 1、系统要求与环境准备

#### 硬件要求

| 组件     | 最低要求              | 推荐配置                           |
  | :------- | :-------------------- | :--------------------------------- |
| **CPU**  | 多核处理器（4核以上） | 8核以上，支持 AVX2 指令集          |
| **内存** | 8GB RAM               | 16GB 或更高（大型模型需要 32GB+）  |
| **存储** | 50GB 可用空间         | 200GB+ SSD（模型文件较大）         |
| **GPU**  | 集成显卡（CPU 模式）  | NVIDIA GPU（8GB+ 显存，支持 CUDA） |

#### 软件要求

- **操作系统**：Windows 10/11、macOS 14+、Linux（Ubuntu 18.04+）
- **依赖环境**：.NET Runtime（Windows）、Python 3.8+（可选）


### 2、安装步骤

#### ①、下载安装程序
- 访问 Ollama 官方网站（https://ollama.com/download），选择 "Download for Windows" 按钮下载安装程序（文件名为 `OllamaSetup.exe`）
- **技巧**：国内用户如遇下载速度慢的情况，可尝试使用迅雷等下载工具加速，或将下载链接复制到下载工具中


#### ②、运行安装程序

- 双击下载的 `OllamaSetup.exe`文件，如果出现用户账户控制提示，点击"是"授权安装，**默认是安装在C盘的**。

- **自定义安装路径**：如果希望将 Ollama 安装到非系统盘，可以按照以下步骤操作：

  - 1. 打开命令提示符（CMD）或 PowerShell
  - 2. 切换到安装程序所在目录
  - 3. 执行以下命令（以安装到 D 盘为例）：

    ```bash
    # 打开命令提示符或 PowerShell，执行：
    OllamaSetup.exe /DIR="D:\install\ollama"
    
    # 或者使用绝对路径
    "C:\Users\用户名\Downloads\OllamaSetup.exe" /DIR="D:\install\ollama"
    ```

- 推荐使用此方法，可以释放系统盘空间  。

- 安装过程会自动完成，最后关闭窗口即可



#### ③. 验证安装

- 安装完成后，打开命令提示符（CMD）或 PowerShell，输入以下命令验证安装是否成功：

```bash
ollama --version
# 或者
ollama -v
```

- 如果显示版本号（如 `ollama version is 0.12.6`），则表明安装成功


## 二、基本使用教程



### 1、下载和运行模型

- Ollama 支持丰富的模型库，包括 Llama、DeepSeek 等热门模型。
- **查看模型库**：访问 Ollama
  - 官方模型库（https://ollama.com/library）选择所需模型 。
  - 检索模型：[https://ollama.com/search](https://ollama.com/search)
- **下载并运行模型**（以 DeepSeek R1 为例）：

```bash
# 下载并运行模型
ollama run deepseek-r1

# 仅下载模型（不运行）
ollama pull deepseek-r1

# 运行已下载的模型
ollama run 模型名称
```



![](ollama2.png)



### 2、Ollama相关命令

- Ollama 提供了多种命令行工具（CLI）供用户与本地运行的模型进行交互。
- 我们可以用 ollama --help 查看包含有哪些命令


```bash
# 启动 Ollama 服务以在后台运行
ollama serve

# 查看当前安装的 Ollama 版本
ollama version

# 查看本地模型列表
ollama list

# 查看模型详细信息
ollama show 模型名称

# 复制模型
ollama cp 原模型名 新模型名

# 删除模型
ollama rm 模型名称

# 停止运行中的模型
ollama stop 模型名称

# 查看运行中的模型
ollama ps
```




## 三、总结

Ollama 作为一个功能完善的本地大模型部署工具，具有以下核心价值：

#### 核心优势

- **隐私安全**：数据完全本地处理，保障敏感信息安全
- **成本效益**：一次部署，长期使用，避免持续 API 费用
- **灵活定制**：支持模型参数调整和自定义配置
-  **多模型支持**：可同时管理运行多个不同模型

#### 适用场景

- **企业内部**：处理敏感数据的 AI 应用
- **开发测试**：模型调优和功能验证
- **离线环境**：无网络连接的 AI 需求
- **教育研究**：学术研究和实验验证