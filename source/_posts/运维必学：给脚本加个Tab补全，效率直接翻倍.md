---
title: 运维必学：给脚本加个Tab补全，效率直接翻倍
tags: [Linux]
categories: 网络运维
date: 2026-01-04 15:07:54
---

每天在Linux终端敲命令，谁没依赖过Tab键的命令补全？输入`cd /ho`按Tab自动补全成`cd /home/`，输入`$JAV`按Tab秒出`$JAVA_HOME`——这个小功能帮我们省了无数记参数、拼路径的时间。

但你有没有想过：这背后是怎么实现的？更重要的是，自己写的运维脚本（比如服务管理、系统查询脚本），能不能也加上这种“Tab补全buff”？

今天就从底层逻辑到实操落地，把Linux脚本参数补全讲透。不管是日常运维还是团队协作，学会这招能让你的脚本从“能用”直接升级到“好用”，大幅降低操作成本。

<!--more-->




## 一、先搞懂：命令补全的底层靠什么支撑？

很多人以为命令补全是Shell自带的“天赋技能”，其实核心是两个组件的协同配合——**readline库**和**Shell补全规则库**。搞懂这俩，就理解了补全的本质。



#### 1、输入处理中枢：readline库

说白了，所有Shell（bash、zsh等）的命令输入、编辑、补全触发，核心都依赖这个叫**readline**的GNU开源库。它就像个“中间人”，负责衔接用户操作和Shell逻辑：

- 接收用户输入（比如`serverctl st`）；
- 监听Tab键的补全信号——这是触发补全的关键；
- 把当前输入的字符串传给Shell，再把Shell返回的匹配结果展示给用户。

底层逻辑很简单：你按下Tab的瞬间，readline会立刻调用Shell注册的“补全回调函数”，把“st”这个待补全的字符串发过去，等着Shell返回匹配的结果（比如start、stop）。





#### 2、规则核心：Shell的补全规则库

如果说readline是“传话筒”，那Shell的补全规则库就是“决策大脑”。它本质是一套“输入模式→匹配逻辑→结果列表”的映射，主要分为两类：

- **内置规则**：Shell 默认支持的补全场景（无需额外配置）：
    - 命令补全：匹配`$PATH`环境变量下的可执行文件（如`jav`→`java`）；
    - 路径补全：匹配当前目录或指定路径下的文件 / 目录（如`cd /us`→`cd /usr/`）；
    - 变量补全：输入`$`后按 Tab，匹配系统环境变量（如`$JAV`→`$JAVA_HOME`）；
    - 选项补全：部分命令的参数补全（如`ls -`→`ls -l`、`ls -a`）。

- **自定义规则**：内置规则只覆盖系统命令和路径，但我们写的自定义脚本（比如服务管理脚本、自研工具）就搞不定了。这时候就需要用`complete`命令或补全脚本，自己定义补全规则。



**命令补全完整的工作流程：**

![命令补全完整的工作流程图](complete1.png)



## 二、实操落地：给自定义脚本加补全（从基础到进阶）

- 搞懂底层逻辑后，重点来了
- 怎么给我们自己的运维脚本加Tab补全？分两步走：先从简单的服务管理脚本入门，再升级到复杂的系统信息查询脚本，覆盖日常运维核心场景。



### 1、Bash自动补全入门：从0到1

- 让我们从一个简单的例子开始。假设我们有一个管理服务器的脚本 `serverctl`：


#### ①、脚本内容

```bash
#!/bin/bash
# 文件名: serverctl

case $1 in
    start)
        echo "启动服务..."
        ;;
    stop)
        echo "停止服务..."
        ;;
    restart)
        echo "重启服务..."
        ;;
    status)
        echo "服务状态..."
        ;;
    *)
        echo "用法: $0 {start|stop|restart|status}"
        ;;
esac
```

目前，这个脚本没有任何补全功能。让我们为它“赋能”：





#### ②、添加自动补全功能

- 新建一个补全脚本，核心是定义补全函数，再用`complete`命令注册到Shell：


```bash
# 文件名: serverctl-completion.bash
_serverctl_completion() {
	# 声明局部变量，避免污染全局命名空间
    local cur prev opts
    # 存储补全结果的数组，必须定义
    COMPREPLY=()
    # 获取当前正在输入的单词（光标位置所在的单词）
    cur="${COMP_WORDS[COMP_CWORD]}"
    
    # 获取前一个单词，用于判断上下文
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    
    # 定义 serverctl 命令支持的所有选项和子命令
    opts="start stop restart status --help --version"
    
    if [[ ${cur} == -* ]]; then
        COMPREPLY=( $(compgen -W "--help --version" -- ${cur}) )
        return 0
    fi
    
    # compgen 命令根据当前输入过滤可用的选项
    # -W指定候选列表，--后面跟当前输入，实现前缀匹配
    COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
    return 0
}

# complete 是 Bash 内建命令，用于为指定命令注册补全函数
# -F 选项指定要使用的补全函数名
# serverctl 是要为其添加补全功能的命令名或脚本名称
complete -F _serverctl_completion serverctl
```

#### ③、启用补全功能

- 使用source命令使脚本生效



```bash
# 加载自动补全
source serverctl-completion.bash

# 现在尝试输入以下命令并按Tab键：
# serverctl st<Tab>  # 会自动补全为 serverctl start
# serverctl --h<Tab> # 会自动补全为 serverctl --help
```



![示例图1](complete2.png)



#### 小坑提醒

细心的同学会发现，直接输`serverctl`按Tab没反应，必须输全路径（比如`/root/serverctl`）才行。解决办法有两个，任选其一：

- **方法1**：创建软链接到系统PATH目录（推荐） `ln -s /root/serverctl /usr/local/bin/serverctl`
- **方法2**：添加别名到Shell配置文件 在`~/.bashrc`或`~/.bash_profile`里加一行： `alias serverctl='/root/serverctl'` 然后执行`source ~/.bashrc`生效

效果演示：



![示例图2](complete3.png)



### 2、进阶实战

- 实际工作中，我们的脚本通常更复杂，支持多种参数和选项。下面是一个**专业级的系统信息查询脚本**，内置了完整的补全功能：



#### ①、完整脚本(含补全函数）

```bash
#!/bin/bash
# ==============================================================================
# SysInfo.sh - 系统信息查询工具（CPU/内存/磁盘/网络/系统）
# 功能：一键查询Linux系统核心硬件/系统信息，支持精准筛选查询类型
# 使用：
#   基础用法：./SysInfo.sh -t cpu
#   完整用法：./SysInfo.sh --type all
#   启用补全：source ./SysInfo.sh（Tab键补全所有参数）
# 兼容：CentOS/Ubuntu/Debian等主流Linux发行版
# ==============================================================================


# 支持的查询类型（补全+校验用）
SUPPORTED_TYPES=("cpu" "mem" "disk" "net" "sys" "all")
# 默认查询类型（未传参时查CPU）
DEFAULT_TYPE="cpu"

# 颜色定义（区分信息层级，提升可读性）
COLOR_TITLE="\033[1;36m" 
COLOR_KEY="\033[1;33m"   
COLOR_VALUE="\033[1;37m" 
COLOR_WARN="\033[1;31m"  
COLOR_RESET="\033[0m"    


# 函数：打印错误信息并退出
print_error() {
    local msg="$1"
    local exit_code="${2:-1}"
    echo -e "${COLOR_WARN}❌ 错误：$msg${COLOR_RESET}"
    exit $exit_code
}

# 函数：打印分隔线（美化输出）
print_separator() {
    echo -e "${COLOR_TITLE}----------------------------------------${COLOR_RESET}"
}


# 查询CPU信息（型号/核心数/使用率）
query_cpu() {
    echo -e "\n${COLOR_TITLE}🖥️ CPU 信息${COLOR_RESET}"
    print_separator

    # CPU型号（兼容不同发行版）
    local cpu_model=$(lscpu | grep -E 'Model name|型号名称' | head -1 | awk -F: '{gsub(/^[ \t]+/, "", $2); print $2}')
    # 物理核心数
    local cpu_cores=$(lscpu | grep -E 'CPU\(s\):|核心数' | head -1 | awk -F: '{gsub(/^[ \t]+/, "", $2); print $2}')
    # CPU使用率（top批量模式，避免交互）
    local cpu_usage=$(top -bn1 | grep 'Cpu(s)' | awk '{print 100-$8}' | cut -d. -f1)

    echo -e "${COLOR_KEY}型号：${COLOR_VALUE}$cpu_model${COLOR_RESET}"
    echo -e "${COLOR_KEY}物理核心数：${COLOR_VALUE}$cpu_cores${COLOR_RESET}"
    echo -e "${COLOR_KEY}当前使用率：${COLOR_VALUE}${cpu_usage}%${COLOR_RESET}"
}

# 查询内存信息（总/已用/可用）
query_mem() {
    echo -e "\n${COLOR_TITLE}🧠 内存 信息${COLOR_RESET}"
    print_separator

    # 提取free -h的内存数据（兼容不同语言）
    local mem_total=$(free -h | grep -E 'Mem|内存' | awk '{print $2}')
    local mem_used=$(free -h | grep -E 'Mem|内存' | awk '{print $3}')
    local mem_available=$(free -h | grep -E 'Mem|内存' | awk '{print $7}')
    local mem_usage=$(free | grep -E 'Mem|内存' | awk '{printf "%.0f", $3/$2*100}')

    echo -e "${COLOR_KEY}总内存：${COLOR_VALUE}$mem_total${COLOR_RESET}"
    echo -e "${COLOR_KEY}已用内存：${COLOR_VALUE}$mem_used (${mem_usage}%)${COLOR_RESET}"
    echo -e "${COLOR_KEY}可用内存：${COLOR_VALUE}$mem_available${COLOR_RESET}"
}

# 查询磁盘信息（主要分区使用率）
query_disk() {
    echo -e "\n${COLOR_TITLE}💽 磁盘 信息${COLOR_RESET}"
    print_separator

    # 过滤主要分区（排除tmpfs/loop，只显示使用率≥1%的）
    df -h | grep -vE 'tmpfs|loop|udev' | awk 'NR>1 {print $0}' | while read -r line; do
        local mount_point=$(echo "$line" | awk '{print $6}')
        local total=$(echo "$line" | awk '{print $2}')
        local used=$(echo "$line" | awk '{print $3}')
        local usage=$(echo "$line" | awk '{print $5}')

        # 使用率超过85%标红警告
        local usage_num=${usage%\%}
        if [ "$usage_num" -ge 85 ]; then
            echo -e "${COLOR_KEY}分区 $mount_point：${COLOR_WARN}已用$used/$total ($usage) [高负载]${COLOR_RESET}"
        else
            echo -e "${COLOR_KEY}分区 $mount_point：${COLOR_VALUE}已用$used/$total ($usage)${COLOR_RESET}"
        fi
    done
}

# 查询网络信息（IP/网卡/流量）
query_net() {
    echo -e "\n${COLOR_TITLE}🌐 网络 信息${COLOR_RESET}"
    print_separator

    # 过滤非回环网卡
    local net_cards=$(ip link show | grep -v LOOPBACK | grep -E 'UP|UNKNOWN' | awk -F: '{print $2}' | sed 's/ //g')
    
    for card in $net_cards; do
        # 网卡IP（优先IPv4）
        local ip_addr=$(ip addr show "$card" | grep -E 'inet ' | awk '{print $2}' | head -1)
        if [ -z "$ip_addr" ]; then
            ip_addr="未分配IPv4"
        fi

        echo -e "${COLOR_KEY}网卡 $card：${COLOR_VALUE}IP = $ip_addr${COLOR_RESET}"

        # 网卡收发流量（简化版，单位KB/MB）
        local rx_bytes=$(ip -s link show "$card" | grep -A1 'RX:' | tail -1 | awk '{print $1}')
        local tx_bytes=$(ip -s link show "$card" | grep -A1 'TX:' | tail -1 | awk '{print $1}')
        # 转换为易读单位（KB）
        local rx_kb=$((rx_bytes / 1024))
        local tx_kb=$((tx_bytes / 1024))
        echo -e "         ${COLOR_KEY}接收流量：${COLOR_VALUE}$rx_kb KB | 发送流量：$tx_kb KB${COLOR_RESET}"
    done
}

# 查询系统信息（内核/发行版/开机时间）
query_sys() {
    echo -e "\n${COLOR_TITLE}⚙️ 系统 信息${COLOR_RESET}"
    print_separator

    # 内核版本
    local kernel=$(uname -r)
    # 发行版（兼容lsb_release/os-release）
    if command -v lsb_release &>/dev/null; then
        local distro=$(lsb_release -d | awk -F: '{gsub(/^[ \t]+/, "", $2); print $2}')
    else
        local distro=$(grep -E 'PRETTY_NAME' /etc/os-release | awk -F= '{print $2}' | sed 's/"//g')
    fi
    # 开机时间（格式化）
    local uptime=$(uptime -p | sed 's/up //')
    # 当前系统时间
    local cur_time=$(date +"%Y-%m-%d %H:%M:%S")

    echo -e "${COLOR_KEY}内核版本：${COLOR_VALUE}$kernel${COLOR_RESET}"
    echo -e "${COLOR_KEY}发行版：${COLOR_VALUE}$distro${COLOR_RESET}"
    echo -e "${COLOR_KEY}开机时长：${COLOR_VALUE}$uptime${COLOR_RESET}"
    echo -e "${COLOR_KEY}当前时间：${COLOR_VALUE}$cur_time${COLOR_RESET}"
}

# 查询全部信息
query_all() {
    query_cpu
    query_mem
    query_disk
    query_net
    query_sys
    print_separator
    echo -e "\n${COLOR_TITLE}✅ 系统信息查询完成${COLOR_RESET}"
}


# 步骤1：转换长选项为短选项（getopts原生不支持长选项）
convert_long_opts() {
    local args=()
    while [ $# -gt 0 ]; do
        case "$1" in
            --type)  args+=("-t"); shift ;;
            --help)  args+=("-h"); shift ;;
            --*)     print_error "不支持的长选项：$1" ;;
            *)       args+=("$1"); shift ;;
        esac
    done
    set -- "${args[@]}" # 替换原参数
}

# 步骤2：getopts解析短选项
parse_params() {
    local query_type="$DEFAULT_TYPE"
    local opt

    # getopts格式：t:h → t需要参数，h无参数
    while getopts "t:h" opt; do
        case "$opt" in
            t)
                # 校验查询类型是否支持
                if [[ ! " ${SUPPORTED_TYPES[@]} " =~ " $OPTARG " ]]; then
                    print_error "不支持的查询类型：$OPTARG\n支持类型：${SUPPORTED_TYPES[*]}"
                fi
                query_type="$OPTARG"
                ;;
            h)
                show_help
                exit 0
                ;;
            \?)
                print_error "无效选项：-$OPTARG" 2
                ;;
            :)
                print_error "选项 -$OPTARG 需要传入查询类型（如：-t cpu）" 2
                ;;
        esac
    done

    # 根据类型执行查询
    case "$query_type" in
        cpu)   query_cpu ;;
        mem)   query_mem ;;
        disk)  query_disk ;;
        net)   query_net ;;
        sys)   query_sys ;;
        all)   query_all ;;
    esac
}

#  【帮助函数】- 用法说明
show_help() {
    echo -e "\n${COLOR_TITLE}🖥️ 系统信息查询工具 🖥️${COLOR_RESET}"
    echo "========================================"
    echo "用法：$(basename $0) [选项]..."
    echo ""
    echo "【核心选项】（短/长选项兼容）:"
    echo "  -t | --type <类型>    指定查询类型（默认：$DEFAULT_TYPE）"
    echo "                        支持类型：${SUPPORTED_TYPES[*]}"
    echo "  -h | --help           显示本帮助信息"
    echo ""
    echo "【类型说明】:"
    echo "  cpu   - CPU型号/核心数/使用率"
    echo "  mem   - 内存总大小/已用/可用"
    echo "  disk  - 磁盘分区/使用率（高负载标红）"
    echo "  net   - 网卡IP/收发流量"
    echo "  sys   - 内核/发行版/开机时间"
    echo "  all   - 查询所有系统信息"
    echo ""
    echo "【使用示例】:"
    echo "  $(basename $0) -t cpu          # 查询CPU信息"
    echo "  $(basename $0) --type mem      # 查询内存信息"
    echo "  $(basename $0) -t all          # 查询全部信息"
}

# 高级补全函数
_sysinfo_completion() {
    COMPREPLY=()
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local prev="${COMP_WORDS[COMP_CWORD-1]}"

    # 定义补全候选集
    local short_opts="-t -h"
    local long_opts="--type --help"
    local all_opts="$short_opts $long_opts"
    local query_types="${SUPPORTED_TYPES[*]}"

    # 补全逻辑分层
    case "$prev" in
        # 逻辑1：-t/--type 后 → 补全查询类型
        -t|--type)
            COMPREPLY=( $(compgen -W "$query_types" -- "$cur") )
            ;;
        # 逻辑2：其他位置 → 补全短/长选项
        *)
            if [[ "$cur" == --* ]]; then
                # 以--开头 → 补全长选项
                COMPREPLY=( $(compgen -W "$long_opts" -- "$cur") )
            else
                # 否则 → 补全短选项
                COMPREPLY=( $(compgen -W "$short_opts" -- "$cur") )
            fi
            ;;
    esac

    return 0
}

# ============================ 【主逻辑 + 补全注册】 ============================
main() {
    # 第一步：转换长选项为短选项
    convert_long_opts "$@"
    # 第二步：解析参数并执行查询
    parse_params "$@"
}

# 脚本被source → 仅注册补全（不执行主逻辑）
if [[ ${BASH_SOURCE[0]} != "$0" ]]; then
    SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}" .sh)"
    SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
    
    # 注册补全函数（支持脚本名/./脚本.sh调用）
    complete -F _sysinfo_completion "$SCRIPT_NAME"
    complete -F _sysinfo_completion "$SCRIPT_PATH"

    # 补全启用提示
    echo -e "${COLOR_TITLE}✨ 系统信息查询工具补全已启用！${COLOR_RESET}"
    echo -e "${COLOR_KEY}👉 补全示例：${COLOR_RESET}"
    echo "   1. $(basename $0) -[Tab]        # 补全短选项（-t/-h）"
    echo "   2. $(basename $0) --[Tab]       # 补全长选项（--type/--help）"
    echo "   3. $(basename $0) -t [Tab]      # 补全查询类型（cpu/mem/disk等）"
    return
fi

# 脚本直接执行 → 运行主逻辑
main "$@"
```



#### ②、分层逻辑适配复杂场景

这个补全函数比基础案例更实用，核心是“根据上下文补全”，完全贴合运维实际操作：

- 输入`./SysInfo.sh -`按Tab：补全短选项`-t`、`-h`；
- 输入`./SysInfo.sh --`按Tab：补全长选项`--type`、`--help`；
- 输入`./SysInfo.sh -t `（空格后）按Tab：补全查询类型`cpu`/`mem`/`disk`等。



#### ③、永久生效配置

临时`source`加载的补全，只在当前终端会话生效。要让所有会话都能用，把`source`指令加入Shell配置文件:



```bash
# Bash环境（大部分运维场景）
echo "source /path/to/SysInfo.sh" >> ~/.bashrc

# Zsh环境（如果用zsh）
echo "source /path/to/SysInfo.sh" >> ~/.zshrc

# 让配置立刻生效
source ~/.bashrc  # 或 source ~/.zshrc
```


#### ④、执行效果演示

![系统信息脚本示例图](complete4.png)




## 三、最后

很多运维同学觉得“补全是锦上添花”，其实不然——尤其是在团队协作或高频使用场景下，它是“降本增效”的关键：

- **减少记忆成本**：不用再反复记脚本参数、翻帮助文档；
- **避免输入错误**：比如把`restart`输成`restar`，补全直接规避；
- **提升协作效率**：团队共用的脚本加了补全，新人不用专门学习，上手即会。



**记住**：一个优秀的工具不仅要功能强大，更要易于使用。而智能补全，正是连接强大功能与友好体验的桥梁。



最后留个互动：你平时写脚本有没有遇到参数记不住、输错的问题？评论区聊聊你最想给哪个脚本加补全！