---
title: EMQX安装指南与基础配置详解
tags: [EMQX,MQTT]
categories: 物联网
date: 2025-05-10 18:15:17
updated: 2025-05-10 18:15:17
---

## 一、什么是EMQX
- EMQX是一个开源的、高性能的MQTT消息服务器，支持多种MQTT协议版本和QoS等级，能够在分布式环境下扩展数百万连接。它采用了Erlang语言和OTP平台开发，这些技术以其可靠性、容错性和并发处理能力而著称，确保了系统的高可用性和稳定性。
- EMQX提供了丰富的API接口和管理工具，方便用户进行开发和管理。它完全遵循Apache License 2.0开源协议，允许用户自由修改和分发源代码。由于其出色的性能和扩展性，EMQX被广泛应用于物联网（IoT）、智能家居、智慧城市等领域。
- EMQX不仅支持MQTT协议，还支持其他物联网协议如CoAP、LwM2M等，并且可以与各种数据库和消息队列系统集成，比如通过插件实现数据持久化到关系型数据库或NoSQL数据库，或者桥接转发消息到Kafka、RabbitMQ等。
- EMQX有多个版本，包括开源版EMQX Broker，企业版EMQX Enterprise以及针对超大型IoT网络和应用设计的EMQX Platform。每个版本在支持的连接数量、功能特性和商业服务方面有所不同，以满足不同规模和需求的用户。

- **Github地址：** [https://github.com/emqx/emqx](https://github.com/emqx/emqx)
- **官网：** [https://www.emqx.com/zh](https://www.emqx.com/zh)


<!--more-->

## 二、EMQX有什么用
- EMQX 是一个专门设计用于物联网（IoT）通信的开源消息服务器，主要用于处理大规模设备之间的实时消息传输。它基于 MQTT（Message Queuing Telemetry Transport）协议以及其他支持的物联网协议（如 CoAP、LwM2M等），能够高效、可靠地在分布式环境中扩展至数百万的并发连接。以下是 EMQX 的主要用途和特点：

  ### 主要用途

    1. **物联网设备通信**：EMQX 支持通过MQTT协议进行设备与服务器之间的双向通信，适合于智能家居、智慧城市、工业互联网等多种应用场景。
    2. **数据采集与监控**：可以用来收集传感器数据，并将其转发到后端系统进行处理或存储，适用于需要远程监控和管理的场景。
    3. **消息路由和转发**：EMQX 可以作为中间件，将来自不同设备的消息路由到相应的服务或者应用中去，实现复杂的消息分发逻辑。
    4. **高可用性和可扩展性**：针对大规模物联网部署，EMQX 提供了集群功能，确保系统的高可用性以及水平扩展能力。

  ### 特点

    - **高性能**：采用Erlang语言开发，具有优秀的并发处理能力和低延迟特性。
    - **多协议支持**：除了MQTT之外，还支持CoAP、LwM2M等物联网协议。
    - **丰富的插件生态**：可以通过插件扩展EMQX的功能，比如增强安全性、集成第三方服务等。
    - **易用性**：提供直观的管理界面和详细的文档，便于用户快速上手。
    - **开放源代码**：遵循Apache License 2.0开源协议，允许自由修改和分发。
    - **全新物联网数据集成**:

        - EMQX 5.x 的规则引擎在原有 SQL 的基础上集成了 [jq](https://stedolan.github.io/jq/)，支持更多复杂格式 JSON 数据的处理。更多信息详见：[jq 函数](https://docs.emqx.com/zh/emqx/latest/data-integration/rule-sql-jq.html)。

          EMQX 默认支持将数据发送到 Webhook，或与外部 MQTT 服务建立双向桥接，同时还支持将物联网数据实时处理并发送到 40 多个云服务和企业系统，或者从其中获取数据，经处理后下发到指定 MQTT 主题中。同时，EMQX 5.0 还提供了数据集成可视化查看能力（Flows）。通过 Dashboard 页面，您可以清晰看到设备与云端之间的物联网数据处理和流转步骤。


总之，EMQX 是为了解决物联网领域内设备间通信的需求而生，特别适用于需要处理大量并发连接和实时数据传输的应用场景。

## 三、安装EMQX
- EMQX 支持多种安装方式，比如[容器化部署](https://docs.emqx.com/zh/emqx/latest/deploy/install-docker.html)，通过 [EMQX Kubernetes Operator](https://www.emqx.com/zh/emqx-kubernetes-operator) 安装部署、或通过安装包的形式部署在物理服务器或虚拟机上，针对安装包部署形式，目前支持以下操作系统：

    - RedHat
    - CentOS
    - RockyLinux
    - AmazonLinux
    - Ubuntu
    - Debian
    - macOS
    - Linux

### Docker容器运行

- 容器化部署是体验 EMQX 的最快方式。
- 1、在命令行工具中输入如下命令，下载并运行最新版 EMQX。
    - 运行此命令前，请确保 [Docker](https://www.docker.com/) 已安装且已启动。



```bash
# 启动emqx
docker run -d --name emqx -p 1883:1883 -p 8083:8083 -p 8084:8084 -p 8883:8883 -p 18083:18083 emqx/emqx:5.8.6

# 从容器复制文件到主机,命令格式：docker cp <container_id>:/opt/emqx/etc C:/emqx/etc
# 下面把etc和data文件夹复制出来
docker cp d330d:/opt/emqx/etc d:/emqx/etc
docker cp d330d:/opt/emqx/data d:/emqx/data

# 停止容器并删除容器
docker stop d330d
docker rm d330d

# 重启启动容器，并映射文件，这样文件数据是保留再宿主机的。
docker run -d --name emqx -p 1883:1883 -p 8083:8083 -p 8084:8084 -p 8883:8883  -p 18083:18083 -v d:/emqx/etc:/opt/emqx/etc -v d:/emqx/data:/opt/emqx/data emqx/emqx:5.8.6

# 查看容器启动情况
docker ps

```

- **MQTT 协议端口**
    - **1883**：这是 MQTT 协议的标准端口，用于非加密的 MQTT 连接。
    - **8883**：这是 MQTT+SSL（MQTTS）的标准端口，用于加密的 MQTT 连接，提供更高的安全性。
- **WebSocket 端口**
    - **8083**：通过 WebSocket 进行 MQTT 通信的端口，默认使用非加密连接。通常用于浏览器客户端通过 WebSocket 协议与 EMQX 服务器进行通信。
    - **8084**：类似于 8083，但是使用了 SSL 加密，即 WSS（WebSocket Secure），为 WebSocket 通信提供了安全层。
- **Dashboard 和 API 端口**
    - **18083**：这是 EMQX 的 Dashboard 管理界面以及 HTTP API 的默认端口。你可以通过这个端口访问 EMQX 提供的 Web 管理界面来监控和管理你的 MQTT 服务。此外，EMQX 提供的 RESTful API 也通过这个端口提供服务。
- 命令运行示例图如下：

![](docker1.png)


- 2、通过浏览器访问 http://localhost:18083/（localhost 可替换为您的实际 IP 地址）以访问 [EMQX Dashboard](https://docs.emqx.com/zh/emqx/latest/dashboard/introduction.html) 管理控制台，进行设备连接与相关指标监控管理。
- 默认用户名及密码：`admin`与`public`

![](login.png)

- 重新设置密码

![](initpwd.png)

- 首页面板

![](dashboard.png)

#### 配置用户
- 如上，已经是安装完成了，可以使用了，但是默认是没有添加客户端认证的，不安全所有知道地址的都可以进行访问。
- 所以我们可以配置客户端认证

![](auth1.png)

![](auth2.png)

![](auth3.png)

![](auth4.png)

- 添加用户之后我们就需要登录用户名密码才能访问了
- 可以下载MQTTX客户端，进行消息的发送与接收测试

![](mqttx.png)

## 四、总结
- 随着物联网技术的发展，EMQX 将在更多场景中发挥重要作用。无论是智能家居、工业自动化还是智慧城市，EMQX 都能提供可靠的消息传输服务和数据集成能力。希望本文能够帮助您顺利入门 EMQX，并在实际项目中加以应用。