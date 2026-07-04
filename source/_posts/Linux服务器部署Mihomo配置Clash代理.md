---
title: Linux服务器部署Mihomo配置Clash代理
tags: [Clash, Linux,vpn]
categories: 网络运维
date: 2026-07-04 11:16:32
updated: 2026-07-04 11:16:32
---

在我们电脑上，我们大部分使用 Clash 桌面版和订阅链接轻松访问外网，但当需求迁移到 Linux 服务器时，桌面客户端便无法直接使用。此时，Mihomo 作为一款轻量、稳定且资源占用极低的 Clash 内核，完美适配绝大多数 Linux 发行版，是服务器代理的理想选择。本文将从零开始，详细记录完整的部署流程，你只需逐条执行命令，无需任何额外复杂操作，即可一次跑通，快速拥有稳定可靠的代理服务。


## 一、安装 Mihomo 主程序
### 1. 先确认服务器架构
不同系统架构对应不同安装包，先执行命令查看本机架构：
```bash
uname -m
```
- 输出 `x86_64`：下载 amd64 版本
- 输出 `aarch64`：下载 arm64 版本

### 2. 一键下载、解压、配置全局命令
以主流 x86_64 架构为例，复制下面整套命令依次执行：
```bash
# 下载对应版本安装包（可去官方GitHub Releases替换最新版本号）
wget https://github.com/MetaCubeX/mihomo/releases/download/v1.19.27/mihomo-linux-amd64-v1.19.27.gz

# 解压压缩包
gunzip mihomo-linux-amd64-v1.19.27.gz

# 简化程序名，赋予运行权限
mv mihomo-linux-amd64-v1.19.27 mihomo
chmod +x mihomo

# 移动到系统全局目录，任意位置直接调用mihomo命令
sudo mv mihomo /usr/local/bin/
```


<!--more-->


![](download.png)



## 二、创建并修改核心配置文件

Mihomo 的所有规则、订阅、端口参数都写在 `config.yaml` 里，先新建专属配置文件夹，再写入配置模板。
### 1. 新建配置目录
```bash
mkdir -p ~/.config/mihomo
```
### 2. 打开配置文件编辑
```bash
vim ~/.config/mihomo/config.yaml
```
进入编辑界面后按 `i` 粘贴下方完整配置，**务必替换代码里的订阅链接为自己的 Clash 订阅地址**，改完按 `ESC`，输入 `:wq` 保存退出。
```yaml
# HTTP代理端口
port: 7890
# SOCKS5代理端口
socks-port: 7891
# 混合端口，同时兼容HTTP/SOCKS5协议
mixed-port: 7890

# 局域网访问开关，服务器自用建议关闭false
allow-lan: false
# 运行模式：rule规则分流 / global全局代理 / direct全部直连
mode: rule
# 日志输出等级，日常使用填info足够，调试可改为debug
log-level: info

# 后台控制接口，可搭配图形化面板远程管理
external-controller: 127.0.0.1:9090
# 接口访问密码，按需自行设置
# secret: ""

# 订阅节点拉取配置
proxy-providers:
  mysub:
    type: http
    # 替换成你自己的订阅链接
    url: "https://替换成你自己的订阅链接"
    interval: 3600
    health-check:
      enable: true
      interval: 600
      url: http://www.gstatic.com/generate_204

# 节点策略分组
proxy-groups:
  # 自动测速优选节点组
  - name: "♻️ 自动选择"
    type: url-test
    use:
      - mysub
    url: 'http://www.gstatic.com/generate_204'
    interval: 300

  # 手动切换节点主分组
  - name: "节点选择"
    type: select
    proxies:
      - "♻️ 自动选择"
      - DIRECT
      - REJECT
    use:
      - mysub

# 流量分流规则
rules:
  # 海外站点走代理
  - DOMAIN-SUFFIX,google.com,节点选择
  - DOMAIN-SUFFIX,gstatic.com,节点选择
  - DOMAIN-SUFFIX,github.com,节点选择
  - DOMAIN-SUFFIX,githubusercontent.com,节点选择
  - DOMAIN-SUFFIX,cloudflare.com,节点选择

  # 国内主流网站直连，不走代理节省流量
  - DOMAIN-SUFFIX,cn, DIRECT
  - DOMAIN-SUFFIX,baidu.com, DIRECT
  - DOMAIN-SUFFIX,qq.com, DIRECT
  - DOMAIN-SUFFIX,taobao.com, DIRECT
  - DOMAIN-SUFFIX,weixin.qq.com, DIRECT

  # 本地局域网、内网地址强制直连
  - IP-CIDR,127.0.0.0/8,DIRECT
  - IP-CIDR,10.0.0.0/8,DIRECT
  - IP-CIDR,172.16.0.0/12,DIRECT
  - IP-CIDR,192.168.0.0/16,DIRECT

  # 国内IP段全部直连（依赖GeoIP数据库）
  - GEOIP,CN,DIRECT

  # 兜底规则：未匹配到的流量统一走代理节点
  - MATCH,节点选择

# 规则数据库自动下载地址
geox-url:
  geoip: "https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/geoip.dat"
  geosite: "https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/geosite.dat"
  mmdb: "https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/country-lite.mmdb"
```

### 3. 手动下载IP归属数据库
部分服务器自动拉取数据库会失败，手动下载放置到配置目录更稳妥：
```bash
# 进入配置文件夹
cd ~/.config/mihomo
# 下载IP库文件并重命名
wget -O country.mmdb https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/country-lite.mmdb
```

## 三、启动 Mihomo 服务
### 1. 前台试运行，排查报错
先前台运行一遍，确认配置无错误再后台常驻，方便查看日志定位问题：
```bash
mihomo -d ~/.config/mihomo
```
页面无报错、正常加载订阅节点，代表配置没问题，按下 `Ctrl+C` 终止程序。



![测试运行](test.png)


![测试运行](test2.png)


### 2. 后台静默运行
```bash
nohup mihomo -d ~/.config/mihomo > ~/.config/mihomo.log 2>&1 &
```
运行日志会统一存入 `mihomo.log` 文件，后续排查问题直接查看日志即可。

### 3. 验证代理是否生效
执行这条测试命令，能正常返回页面内容即搭建成功：
```bash
curl -x http://127.0.0.1:7890 https://www.google.com



```

## 四、全局系统代理环境变量
需要服务器全局走代理时，执行下面三条命令临时生效：
```bash
export http_proxy="http://127.0.0.1:7890"
export https_proxy="http://127.0.0.1:7890"
# 内网、本地地址不走代理，避免网络异常
export no_proxy="localhost,127.0.0.1,.local,.k8s.internal"
```

## 五、进程管理：查看/关闭 Mihomo
### 查看占用7890端口的进程
两种命令任选其一：
```bash
lsof -i :7890
ss -tulpn | grep 7890
```

### 终止程序进程
1. 根据查到的PID精准关闭（替换12345为实际PID）
```bash
kill -9 12345
```
2. 一键杀掉所有 Mihomo 进程，简单粗暴
```bash
pkill -9 mihomo
```

