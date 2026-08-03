---
title: kuboard的安装与使用
tags: [k8s,Kuboard]
categories: 网络运维
date: 2026-08-02 18:55:35
---





## 一、Kuboard 是什么？

Kuboard 是一款专为 Kubernetes 设计的免费 Web 管理界面，自 2019 年 8 月发布第一个版本以来，经过持续迭代和优化，目前已获得超过 `25.1k` 个 GitHub Star，并有 1000 多家企业将其应用于生产环境。它通过直观的可视化界面和零代码操作，大幅降低了 Kubernetes 的使用门槛。

简单来说，Kuboard 就是一个让你**用鼠标点一点就能管理 Kubernetes 集群**的工具，而不是只能面对黑乎乎的终端敲命令。

<!--more-->


## 二、为什么需要 Kuboard？



Kubernetes 虽然强大，但原生的管理方式存在不少痛点：

**命令行门槛高。** 管理 Kubernetes 主要依赖 `kubectl` 命令行工具，需要记忆大量命令和参数，对不熟悉命令行的开发或测试人员来说极不友好。

**多集群管理困难。** 当团队同时维护开发、测试、生产等多个集群时，在多个集群之间来回切换、统一管理变得非常繁琐。

**排障效率低。** 查看日志、监控资源、排查问题往往需要在命令行、监控系统、日志系统之间反复切换，效率低下。

而 Kuboard 正是为解决这些问题而生的。



## 三、Kuboard 能做什么？

### 1. 多集群统一管理

Kuboard 支持同时连接和管理多个 Kubernetes 集群（如开发、测试、生产环境），管理员可以将不同集群导入到 Kuboard 中，并通过统一的界面进行监控和管理。你可以在一个页面中同时查看多个集群、多个命名空间的资源状态，无需频繁切换上下文。

### 2. 资源可视化操作

Kuboard 提供了图形化的资源管理界面：

- **拓扑视图**：以图形化方式展示 Pod、Deployment、Service 等资源的依赖关系，直观呈现集群状态。
- **工作负载展示**：将 Deployment 的历史版本、所属 Pod 列表、关联事件、容器信息合理组织在同一页面，帮助快速诊断问题。
- **YAML 生成器**：通过表单填写（如选择镜像、设置副本数）即可自动生成 YAML 文件，避免手动编写错误。
- **批量操作**：一键扩缩容、滚动更新、重启 Pod，减少重复性命令行操作。

### 3. 权限控制与多租户

Kuboard 支持多种认证方式——可以使用内建用户库，也可以对接 GitLab/GitHub 单点登录或 LDAP 用户库进行认证。管理员可以通过权限控制，将不同集群或命名空间的权限分配给指定的用户或用户组，实现精细化的多租户隔离。

### 4. 监控与日志

Kuboard 提供了丰富的可观测性能力：

- **资源监控**：集成 Prometheus/Grafana，展示集群、节点、工作负载、容器等各级别的 CPU、内存、网络、磁盘使用情况。
- **日志聚合**：支持按 Pod 或容器级别查看日志，并可关联 Kubernetes 事件快速定位问题。
- **告警配置**：支持通过邮件、微信发送告警消息，并支持告警路由和告警规则配置。

### 5. 丰富的互操作性

Kuboard 提供了许多通常只在 `kubectl` 命令行中才有的功能：

- 查看节点和 Pod 的资源占用（Top Nodes / Top Pods）
- 容器的日志查看和终端访问
- 容器的文件浏览器（支持上传和下载文件）
- KuboardProxy（在浏览器中提供 `kubectl proxy` 的功能）

### 6. 操作审计

Kuboard 支持操作审计功能，可以审计用户通过 Kuboard 界面和 API 执行的所有操作，满足企业安全合规需求




## 四、安装kuboard v4

### 1. 环境准备

Kuboard v4 需要依赖一个外部数据库作为持久化存储，支持的数据库类型有：

- MySQL >= 5.7
- MariaDB >= 8.0
- OpenGauss >= 3.0

本文档使用 MariaDB 作为数据库，通过 Docker Compose 一键部署。



### 2、配置docker-compose.yml文件

- 配置`docker-compose.yml` 文件

```yaml
services:
  db:
    image: mariadb:11.8.7-noble
    container_name: kuboard-db
    environment:
      MARIADB_ROOT_PASSWORD: root
      MYSQL_ROOT_PASSWORD: root
      TZ: Asia/Shanghai
    volumes:
      # 持久化数据库数据，防止容器删除数据丢失
      - ./mariadb-data:/var/lib/mysql
      # 挂载初始化SQL脚本，只读权限
      - /opt/kuboard/init.sql:/docker-entrypoint-initdb.d/create_db.sql:ro
    # 数据库健康检测，确保就绪后再启动面板
    healthcheck:
      test: ["CMD", "healthcheck.sh", "--connect", "--innodb_initialized"]
      interval: 10s
      timeout: 5s
      retries: 12
    restart: unless-stopped
    networks:
      - kuboard-net

  kuboard:
    image: eipwork/kuboard:v4
    container_name: kuboard
    environment:
      DB_DRIVER: org.mariadb.jdbc.Driver
      DB_URL: jdbc:mariadb://db:3306/kuboard?serverTimezone=Asia/Shanghai
      DB_USERNAME: kuboard
      DB_PASSWORD: Admin123
    # 对外暴露8800端口，映射容器内部80服务端口
    ports:
      - "8800:80"
    volumes:
      - ./kuboard-logs:/app/logs
    depends_on:
      db:
        condition: service_healthy
    restart: unless-stopped
    networks:
      - kuboard-net

# 自定义桥接网络，隔离服务网络
networks:
  kuboard-net:
    driver: bridge

```



> - 数据库容器使用 MariaDB 11.8，数据卷 `./mariadb-data` 和日志卷 `./kuboard-logs` 会保存在当前目录下，确保容器重启后数据不丢失。
> - Kuboard 容器通过 `depends_on` 等待数据库健康检查通过后再启动，避免因数据库未就绪而导致连接失败。



#### init.sql

- 初始化脚本，修改数据库用户`kuboard`密码为：`Admin123`

```sql
CREATE DATABASE IF NOT EXISTS kuboard DEFAULT CHARACTER SET = 'utf8mb4' DEFAULT COLLATE = 'utf8mb4_unicode_ci';
CREATE USER IF NOT EXISTS 'kuboard'@'%' IDENTIFIED BY 'Admin123';
GRANT ALL PRIVILEGES ON kuboard.* TO 'kuboard'@'%';
FLUSH PRIVILEGES;

```



> 此init.sql脚本会在数据库容器首次启动时自动执行，确保 Kuboard 拥有专用账号和库。密码 `Admin123` 与 Compose 中 `DB_PASSWORD` 保持一致，如需变更请同时修改两处。



在 `docker-compose.yml` 所在目录执行以下命令：

```bash
mkdir -p kuboard-logs mariadb-data
# 执行启动命令
docker-compose up -d

# 查看服务运行状态，确认 db、kuboard 容器均正常运行
docker-compose ps


# 查看数据库日志
docker compose logs -f db

# 查看kuboard日志
docker compose logs -f kuboard


# 重启服务
docker-compose restart
# 停止服务（保留数据卷）
docker-compose down
# 彻底销毁（连带删除数据，谨慎执行）
docker-compose down -v
```



等待片刻，容器启动后即可访问 Kuboard。

![](kuboard-1.png)





### 3、访问后台

访问：`http://ip:8800` 8800是docker-compose.yml文件配置的，监听容器内80端口

![](kuboard-login.png)



#### 默认账号密码

```
账号：admin
密码：Kuboard123
```

### 4、导入集群

导入集群后就可以开始操作使用集群了



![](kuboard-2.png)

![](kuboard-3.png)

![](kuboard-4.png)

![](kuboard-5.png)

![](kuboard-6.png)

![](kuboard-7.png)