---
title: 别再手动敲kubectl logs了！运维大佬封装高效查日志脚本，解放你的双手
tags: [Kubernetes]
categories: 网络运维
date: 2025-12-29 16:35:52
---


## 概述

在日常的 Kubernetes 开发和运维工作中，频繁查看容器日志是必不可少的一环。然而，原生的 `kubectl logs`命令在实际使用中存在诸多不便：

- **Pod 标识不稳定**：Pod 重启后名称会变化，需要重新查找
- **命令冗长繁琐**：每次都需要指定命名空间、Pod 名称等参数
- **缺乏交互体验**：多实例情况下需要手动选择，无颜色高亮
- **功能受限**：简单的日志查看，缺乏过滤、分页等高级功能

为此，我封装了一个 `klog.sh`工具，极大提升了 Kubernetes 日志查询的效率和体验。

<!--more-->


#### 设计理念

这个脚本的核心设计理念是：**让简单的事情更简单，让复杂的事情成为可能**。通过封装常见查询模式，提供一致的用户体验。



####  解决的痛点

- 现在查询日志比较麻烦的就是拿到pod的唯一标识，因为只要Pod重启，它的唯一标识就会变化
- 对于Deployment创建的Pod，命名格式是：`[Deployment名称]-[随机字符串]-[随机字符串]`
  - 例如：`user-service-7d8f6c5b4b-abc12`

- 只要重启Pod之前精心敲下的命令又得重写



## 一、klog.sh 工具详解



### 1、工具特性

- **智能 Pod 发现**：通过服务名模糊匹配，自动识别相关 Pod
- **交互式选择**：多实例时提供序号选择界面
- **丰富参数支持**：支持实时跟踪、grep 过滤、上下文查看等
-  **分页功能**：支持 Pod 列表分页显示
- **颜色高亮**：终端输出彩色标识，提升可读性
- **默认配置**：支持默认命名空间、行数等配置




![](klog0.png)



### 2、脚本部署

```bash
# 创建脚本文件
vim ~/klog.sh

# 添加执行权限
chmod +x ~/klog.sh

# 建议创建软链接到 PATH 路径
sudo ln -s ~/klog.sh /usr/local/bin/klog
```



### 3、完整脚本内容

- 在`klog.sh`,编辑内容如下：

```bash
#!/bin/bash
# 文件名: klog.sh
# 描述: Kubernetes 日志查询增强工具
# 版本: 1.0
# 作者: rstyro

# 默认配置
# 默认的pod命名空间
DEFAULT_NAMESPACE="test"
DEFAULT_TAIL=200
DEFAULT_CONTEXT=50
DEFAULT_PAGE_SIZE=20  # 分页默认每页显示数量

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# 显示帮助
show_help() {
    echo -e "${GREEN}Kubernetes 日志查询工具${NC}"
    echo "用法: $0 [选项] [服务名]"
    echo ""
    echo "选项:"
    echo "  -n NAMESPACE   命名空间 (默认: $DEFAULT_NAMESPACE)"
    echo "  -t LINES       显示最后N行 (默认: $DEFAULT_TAIL)"
    echo "  -f             实时跟踪日志"
    echo "  -g PATTERN     grep过滤模式"
    echo "  -c CONTEXT     grep上下文行数 (默认: $DEFAULT_CONTEXT)"
    echo "  -l             列出包含指定名称的pod"
    echo "  -a             列出所有pod（支持分页）"
    echo "  -p PAGE_SIZE   分页大小，与 -a 一起使用 (默认: $DEFAULT_PAGE_SIZE)"
    echo "  -s PAGE_NUM    指定页码，与 -a 一起使用 (默认: 1)"
    echo "  -h             显示帮助"
    echo ""
    echo -e "${BOLD}使用示例:${NC}"
    echo "  ${CYAN}# 基本使用${NC}"
    echo "  klog user-service              # 查看 user-service 日志"
    echo "  klog -n prod api-gateway       # 查看生产环境 api-gateway 日志"
    echo ""
    echo "  ${CYAN}# 实时日志${NC}"
    echo "  klog -f auth-service           # 实时跟踪日志"
    echo "  klog -f -t 50 payment-service  # 实时跟踪最后50行"
    echo ""
    echo "  ${CYAN}# 日志过滤${NC}"
    echo "  klog -g ERROR order-service    # 过滤 ERROR 日志"
    echo "  klog -g 'payment.*fail' -c 20  # 过滤并显示20行上下文"
    echo ""
    echo "  ${CYAN}# Pod 管理${NC}"
    echo "  klog -l user                    # 列出包含 'user' 的 Pod"
    echo "  klog -a -n default              # 列出 default 命名空间所有 Pod"
    echo "  klog -a -p 10 -s 2              # 分页查看，每页10条，第2页"
    echo ""
    exit 0
}

# 列出所有pod（分页功能）
list_all_pods() {
    local namespace="$1"
    local page_size="$2"
    local page_num="$3"
    
    echo -e "${GREEN}获取命名空间 '$namespace' 中的所有pod...${NC}"
    
    # 获取所有pod
    local all_pods=$(kubectl get pods -n "$namespace" 2>/dev/null | tail -n +2)
    
    if [ -z "$all_pods" ]; then
        echo -e "${YELLOW}命名空间 '$namespace' 中没有找到pod${NC}"
        return 0
    fi
    
    # 计算总数和总页数
    local total_pods=$(echo "$all_pods" | wc -l)
    local total_pages=$(( (total_pods + page_size - 1) / page_size ))
    
    # 检查页码是否有效
    if [ "$page_num" -lt 1 ] || [ "$page_num" -gt "$total_pages" ]; then
        echo -e "${RED}错误: 页码 $page_num 无效，有效范围: 1-$total_pages${NC}"
        return 1
    fi
    
    # 计算起始和结束行
    local start_line=$(( (page_num - 1) * page_size + 1 ))
    local end_line=$(( start_line + page_size - 1 ))
    
    # 如果结束行超过总数，则调整
    if [ "$end_line" -gt "$total_pods" ]; then
        end_line=$total_pods
    fi
    
    # 显示分页信息
    echo -e "${BLUE}==============================${NC}"
    echo -e "${CYAN}命名空间:    ${NC}$namespace"
    echo -e "${CYAN}总pod数:     ${NC}$total_pods"
    echo -e "${CYAN}当前页码:    ${NC}$page_num/$total_pages"
    echo -e "${CYAN}本页显示:    ${NC}$start_line-$end_line"
    echo -e "${BLUE}==============================${NC}"
    
    # 显示表头
    echo -e "${PURPLE}$(kubectl get pods -n "$namespace" 2>/dev/null | head -n 1)${NC}"
    echo "----------------------------------------"
    
    # 显示当前页的pod
    echo "$all_pods" | sed -n "${start_line},${end_line}p"
    
    echo "----------------------------------------"
    echo -e "${YELLOW}使用 -s 参数切换页码，如: -s $((page_num + 1))${NC}"
    echo -e "${YELLOW}使用 -p 参数调整每页数量，如: -p 30${NC}"
    
    return 0
}

# 主函数
main() {
    # 参数初始化
    local namespace="$DEFAULT_NAMESPACE"
    local tail_lines="$DEFAULT_TAIL"
    local follow=""
    local grep_pattern=""
    local context_lines="$DEFAULT_CONTEXT"
    local list_only=false
    local list_all=false
    local page_size="$DEFAULT_PAGE_SIZE"
    local page_num=1
    local service_name=""
    
    # getopts是 Linux/Unix 系统内置的 shell 命令，用于解析命令行参数
    while getopts "n:t:fg:c:lap:s:h" opt; do
        case $opt in
            n) namespace="$OPTARG" ;;
            t) tail_lines="$OPTARG" ;;
            f) follow="-f" ;;
            g) grep_pattern="$OPTARG" ;;
            c) context_lines="$OPTARG" ;;
            l) list_only=true ;;
            a) list_all=true ;;
            p) page_size="$OPTARG" ;;
            s) page_num="$OPTARG" ;;
            h) show_help ;;
            *) show_help ;;
        esac
    done
    
    # 检查list_all模式
    if [ "$list_all" = true ]; then
        # 列出所有pod（分页）
        list_all_pods "$namespace" "$page_size" "$page_num"
        exit 0
    fi
    
    # 获取服务名（最后一个非选项参数）
    shift $((OPTIND-1))
    
    if [ $# -eq 0 ]; then
        echo -e "${RED}错误: 请指定服务名或使用 -a 选项列出所有pod${NC}"
        show_help
    fi
    
    service_name="$1"
    
    # 列出pod模式
    if [ "$list_only" = true ]; then
        echo -e "${GREEN}搜索命名空间 '$namespace' 中包含 '$service_name' 的pod...${NC}"
        
        # 获取匹配的pod
        local pods=$(kubectl get pods -n "$namespace" 2>/dev/null | grep "$service_name" || true)
        
        if [ -z "$pods" ]; then
            echo -e "${YELLOW}未找到包含 '$service_name' 的pod${NC}"
            
            # 提供建议
            echo -e "${CYAN}尝试使用 -a 选项查看所有pod:${NC}"
            echo "  $0 -a -n $namespace"
        else
            echo -e "${GREEN}找到以下pod:${NC}"
            echo "----------------------------------------"
            echo "$pods"
            echo "----------------------------------------"
            
            local pod_count=$(echo "$pods" | wc -l)
            echo -e "${CYAN}总计: $pod_count 个pod${NC}"
        fi
        exit 0
    fi
    
    # 查找pod
    echo -e "${BLUE}在命名空间 '$namespace' 中查找包含 '$service_name' 的pod...${NC}"
    local pods=$(kubectl get pods -n "$namespace" 2>/dev/null | grep "$service_name" | head -20)
    
    if [ -z "$pods" ]; then
        echo -e "${RED}错误: 未找到包含 '$service_name' 的pod${NC}"
        echo -e "${YELLOW}建议:${NC}"
        echo "  1. 检查服务名是否正确"
        echo "  2. 使用 -a 选项查看所有pod: $0 -a -n $namespace"
        echo "  3. 使用 -l 选项只列出pod: $0 -l $service_name"
        exit 1
    fi
    
    # 处理pod选择
    local pod_count=$(echo "$pods" | wc -l)
    local pod_name=""
    local pod_namespace="$namespace"
    
    if [ "$pod_count" -eq 1 ]; then
        # 只有一个pod
        pod_name=$(echo "$pods" | awk '{print $1}')
        echo -e "${GREEN}找到pod: $pod_name${NC}"
    else
        # 多个pod，让用户选择
        echo -e "${YELLOW}找到多个pod:${NC}"
        echo "----------------------------------------"
        echo "$pods"
        echo "----------------------------------------"
        
        local idx=1
        local pod_list=()
        while IFS= read -r line; do
            if [ -n "$line" ]; then
                pod_list[$idx]=$(echo "$line" | awk '{print $1}')
                echo "$idx) ${pod_list[$idx]}"
                idx=$((idx + 1))
            fi
        # 将pods变量的内容作为while的输入
        done <<< "$pods"
        
        echo -e "${YELLOW}请选择pod (1-$((pod_count))): ${NC}"
        # 读取用户输入
        read -r choice
        
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "$pod_count" ]; then
            pod_name="${pod_list[$choice]}"
            echo -e "${GREEN}已选择: $pod_name${NC}"
        else
            echo -e "${RED}无效的选择${NC}"
            exit 1
        fi
    fi
    
    # 构建命令
    echo -e "${BLUE}==============================${NC}"
    echo -e "${GREEN}开始查看日志${NC}"
    echo -e "${BLUE}Pod:      ${NC}$pod_name"
    echo -e "${BLUE}命名空间: ${NC}$namespace"
    echo -e "${BLUE}显示行数: ${NC}$tail_lines"
    [ -n "$follow" ] && echo -e "${BLUE}模式:     ${NC}实时跟踪"
    [ -n "$grep_pattern" ] && echo -e "${BLUE}过滤:     ${NC}grep '$grep_pattern'"
    [ -n "$grep_pattern" ] && echo -e "${BLUE}上下文:   ${NC}$context_lines 行"
    echo -e "${BLUE}==============================${NC}"
    
    # 执行命令
    local cmd="kubectl logs -n $namespace $pod_name --tail=$tail_lines"
    [ -n "$follow" ] && cmd="$cmd -f"
    
    if [ -n "$grep_pattern" ]; then
        cmd="$cmd | grep --color=always -C $context_lines '$grep_pattern'"
    fi
    
    echo -e "${YELLOW}执行命令: $cmd${NC}"
    echo ""
    
    eval "$cmd"
}

# 运行主函数
main "$@"
```


### 4、脚本部分代码解释

- `${NC}`是 No Color 的缩写，用于重置终端的文本颜色和样式，避免后面的文本继续使用之前的颜色。

- getopts是 Linux/Unix 系统内置的 shell 命令，用于解析命令行参数。它是 Bash shell 的一部分，所以不需要额外安装。
- 基本语法:


```bash
while getopts "选项字符串" 选项变量; do
    case $选项变量 in
        选项1) 处理代码 ;;
        选项2) 处理代码 ;;
        \?) 无效选项处理 ;;
    esac
done

# 我们的脚本示例：
# 选项字符串定义了哪些选项需要参数：
# n: 需要参数 (命名空间)
# t: 需要参数 (行数)
# g: 需要参数 (grep模式)
# c: 需要参数 (上下文行数)
# f,l,a,h 不需要参数,后面没有冒号，f参数特殊处理
while getopts "n:t:fg:c:lap:s:h" opt; do
    case $opt in
        n) namespace="$OPTARG" ;;
        t) tail_lines="$OPTARG" ;;
        f) follow="-f" ;;
        g) grep_pattern="$OPTARG" ;;
        c) context_lines="$OPTARG" ;;
        l) list_only=true ;;
        a) list_all=true ;;
        p) page_size="$OPTARG" ;;
        s) page_num="$OPTARG" ;;
        h) show_help ;;
        *) show_help ;;
    esac
done
```

**选项字符串 `"n:t:fg:c:lap:s:h"`的解释：**

- `$OPTARG`是`getopts`内置的一个**特殊变量**，用于存储**选项的参数值**。

- `n:`- 冒号表示这个选项需要参数（`-n test`）
- `t:`- 需要参数（`-t 100`）
- `f`- 没有冒号，表示不需要参数（`-f`）
- `g:`- 需要参数（`-g ERROR`）
- `c:`- 需要参数（`-c 50`）
- `l`- 不需要参数
- `h`- 不需要参数





## 二、功能详解



### 1、智能 Pod 发现机制

- 工具的核心功能之一是智能 Pod 发现。传统的 `kubectl logs`需要完整的 Pod 名称，而我们的工具支持模糊匹配：



```bash
# 传统方式（需要完整名称）
kubectl logs -n test user-service-7d8f6c5b4b-abc12

# 使用 klog（智能匹配）
klog user-service
```

**工作原理**：

- 在指定命名空间中查找包含 "user-service" 的所有 Pod
- 如果找到多个，提供交互式选择界面
- 自动获取完整的 Pod 名称并执行日志查看

### 2、参数详解

#### 基本参数

- `-n, --namespace`：指定 Kubernetes 命名空间
- `-t, --tail`：显示最后 N 行日志
- `-f, --follow`：实时跟踪日志（类似 `tail -f`）

#### 高级过滤

- `-g, --grep`：使用 grep 过滤日志内容
- `-c, --context`：grep 上下文行数（默认 50 行）

#### Pod 管理

- `-l, --list`：列出匹配的 Pod（不查看日志）
- `-a, --all`：列出所有 Pod（支持分页）
- `-p, --page-size`：分页大小
- `-s, --page`：指定页码




- 命令：`klog.sh -a -n 命名空间`，-a 是获取所有pod列表

![](klog1.png)


- 默认的命名空间是`test`,如果你的命名空间刚好是test 那就不需要加`-n`参数，还有如果pod太多，可以使用 `-s 或 -p 进行分页调整`




### 3、常用命令

- 快速上手命令



#### 3.1、最简单日志查询



```bash
# 最简单的用法：查看服务最新200行日志
klog user-service

# 指定行数，就加`-t 100` 参数
klog -t 100 user-service  # 只看最后100行

# 指定命名空间为：kube-system
klog -n kube-system -t 50 user-service
```




![简单命令示例](klog2.png)


#### 3.2、实时日志

- 如果想要查询实时日志，那就加上 `-f` 参数，`-t 和 -f` 都是可以一起使用的



```bash
# 实时跟踪日志（类似tail -f）
klog -f api-gateway

# 组合使用：实时跟踪并限制行数
klog -f -t 500 api-gateway

# 生产环境调试（指定命名空间）
klog -n prod -f -t 1000 api-gateway
```






![实时日志示例](klog3.png)


#### 3.3、智能日志过滤

- 我们经常会用到过滤参数，因为正常服务的实时日志有些日志刷太快了，可能我们没看到都被其他日志刷上去了。
- 我们就可以使用grep管道符进行过滤，我们可以使用 `-g`,-g后面接 需要过滤的字符串，比如要过滤日期：`-g 2025-12-29`



![日志过滤示例](klog4.png)



```bash
# 基本过滤：查找错误日志
klog -g "ERROR" -c 10 user-service

# 多条件过滤（通过管道组合）
klog user-service | grep -E "ERROR|WARN"

# 时间范围过滤
klog -g "2025-12-29" user-service

# 实时跟踪特定错误模式
klog -f -g "OutOfMemory" user-service

# 组合使用：实时跟踪 + 过滤 + 指定命名空间
klog -f -g "timeout" -n prd user-service

# 查看最后 500 行，过滤包含 "exception" 的行
klog -t 500 -g exception -c 10 user-service

# 复杂模式匹配
klog -g "Exception.*NullPointer" -c 20 user-service


```

### 4、扩展

将常用命令设为别名，进一步提升效率：



```bash
# 添加到 ~/.bashrc 或 ~/.zshrc
alias klog='~/klog.sh'
alias kl='klog -f'          # 实时日志
alias klg='klog -g ERROR'   # 只看错误
alias klp='klog -a'         # 列出所有 Pod
```







## 三、最后



#### 优势对比

| 功能         | 原生 kubectl     | klog 工具       |
| ------------ | ---------------- | --------------- |
| Pod 名称输入 | 需要完整名称     | 支持模糊匹配    |
| 多实例处理   | 需要手动复制名称 | 交互式选择      |
| 命名空间     | 每次需指定       | 支持默认配置    |
| 实时跟踪     | 需要 -f 参数     | 支持 -f 参数    |
| 日志过滤     | 需要管道组合     | 内置 -g 参数    |
| Pod 浏览     | 需要完整命令     | 内置 -l/-a 参数 |
| 输出美化     | 无               | 彩色高亮        |



- 感兴趣的同学可自行扩展脚本，好的工具都是基于懒惰产生的。
- **技术工作的价值不在于解决了多少复杂问题，而在于让复杂问题不再出现**。希望这个脚本能帮你和你的团队从繁琐的日志查询中解放出来，将精力投入到更有价值的工作中。



**如果这个工具也对你有帮助：**

- **点赞** 👉 让更多被 K8s 日志困扰的伙伴看到这个解决方案
- **关注** 👉 获取后续更多提升研发效能的工具与技巧
- **收藏** ⭐️ 下次查日志时，你会回来感谢现在的自己
- **转发** 🔄 帮助更多被日志查询困扰的同事