---
title: KVM安装与使用
date: 2021-04-01 19:44:44
updated: 2021-04-01 19:44:44
tags: [Linux]
categories: 网络运维
---

### 一、KVM简介
KVM（名称来自英语：Kernel-basedVirtual Machine的缩写，即基于内核的虚拟机），是一种用于Linux内核中的虚拟化基础设施，可以将Linux内核转化为一个hypervisor。KVM在2007年2月被导入Linux 2.6.20核心中，以可加载核心模块的方式被移植到FreeBSD及illumos上。


### 二、搭建KVM平台
+ 我的环境是Centos7.9最小化安装版本

<!--more-->


#### 1、查看硬件是否支持虚拟化
```
egrep ‘(vmx|svm)’ /proc/cpuinfo
```

![](vmx.png)

+ 要有 vmx 或 svm 的标识才行。vmx标识intel，svm代表AMD。

#### 2、安装KVM环境
```bash

#  确保加载kvm模块，如果输出包含kvm_intel或kvm_amd即可
lsmod |grep kvm

# 如果没有启动就运行以下命令
modprobe kvm
modprobe kvm-intel
```

![](kvm.png)

##### 安装依赖

```bash
# 安装依赖包解析
# libvirt     		--虚拟机管理工具
# qemu-kvm 			--KVM 模块
# qemu-img  		--qemu 组件,创建磁盘、 启动虚拟机等
# qemu-kvm-tools 	--KVM 调试工具,可不安装
# bridge-utils 		--网络支持工具
# virt-install		--构建虚拟机的命令行工具
# virt-manager		--图形界面管理虚拟机
# virt-viewer		--最小化的虚拟机图形界面展示工具，连接到已配置好的虚拟机
# libvirt-client	--该软件包提供了用于访问libvirt服务器的客户端API和库。 libvirt-client软件包包括virsh命令行工具

yum install -y libvirt virt-install qemu-kvm qemu-img bridge-utils


# 如果是最小化安装，需要安装图形界面
yum groupinstall "GNOME Desktop"
# 或者装KDE桌面环境
yum groupinstall "KDE Plasma Workspaces"
# 或者装这个也可以
yum groupinstall "X Window System"


# 前提：上面的桌面环境装了，就安装管理虚拟机图形化界面
yum install virt-manager

# 启动服务
systemctl start libvirtd.service
# 开机自启动
systemctl enable libvirtd.service
```

**可以尝试安装命令**
```
virt-install --help
```

##### 可能报错
因为我是最小化安装Centos7.9，所以好多依赖都没有

**如果报错一：**

```
Traceback (most recent call last):
  File "/usr/share/virt-manager/virt-install", line 29, in <module>
    import virtinst
  File "/usr/share/virt-manager/virtinst/__init__.py", line 41, in <module>
    from virtinst.uri import URI
  File "/usr/share/virt-manager/virtinst/uri.py", line 24, in <module>
    from .cli import parse_optstr_tuples
  File "/usr/share/virt-manager/virtinst/cli.py", line 40, in <module>
    from .clock import Clock
  File "/usr/share/virt-manager/virtinst/clock.py", line 20, in <module>
    from .xmlbuilder import XMLBuilder, XMLChildProperty, XMLProperty
  File "/usr/share/virt-manager/virtinst/xmlbuilder.py", line 28, in <module>
    import libxml2
ImportError: No module named libxml2
```

**解决方案：**

```bash
yum install -y libxml2-pyton
```

**如果报错二：**
```
Traceback (most recent call last):
  File "/usr/share/virt-manager/virt-install", line 29, in <module>
    import virtinst
  File "/usr/share/virt-manager/virtinst/__init__.py", line 90, in <module>
    from virtinst.distroinstaller import DistroInstaller
  File "/usr/share/virt-manager/virtinst/distroinstaller.py", line 23, in <module>
    from . import urlfetcher
  File "/usr/share/virt-manager/virtinst/urlfetcher.py", line 33, in <module>
    import requests
  File "/usr/lib/python2.7/site-packages/requests/__init__.py", line 58, in <module>
    from . import utils
  File "/usr/lib/python2.7/site-packages/requests/utils.py", line 26, in <module>
    from .compat import parse_http_list as _parse_list_header
  File "/usr/lib/python2.7/site-packages/requests/compat.py", line 7, in <module>
    import chardet
ImportError: No module named chardet
```

**解决方案：**

+ 直接pip安装第三方依赖：chardet即可
```bash
#  安装Fedora社区打造EPEL源，官方的没有找到python-pip
yum -y install epel-release
yum -y install python-pip
pip install chardet
```


#### 3、配置网络
选择桥接模式
```
cd /etc/sysconfig/network-scripts
cp ifcfg-ens33 ifcfg-br0
```
+ 修改 ifcfg-br0
```
需改：
TYPE=Bridge       
BOOTPROTO=static
NAME=br0
DEVICE=br0
ONBOOT=yes
删UUID一行

添加：
IPADDR=192.168.60.168
NETMASK=255.255.255.0
GATEWAY=192.168.60.1
DNS1=8.8.8.8
DNS2=114.114.114.114

```

+ 修改 ifcfg-ens33
```
需改：
BOOTPROTO=static
ONBOOT=yes
添加：
BRIDGE=br0
```

+ 重启 network
```
systemctl restart network 
```

+ 其实不配置桥接也可以，这样的话就是用默认`virbr0`网卡,网段是192.168.122.1/24的
+ 配置桥接是为了可以和宿主机的局域网可以相互访问

### 三、使用KVM
使用`virsh` 命令来管理KVM虚拟机，可以通过：`virsh -h`显示详细的帮助文档。

#### 1、可视化安装KVM虚拟机

+ 如果安装了可视化依赖，可执行：`virt-manager` 调出可视化管理界面
+ 如果是使用的是xshell软件，需要安装 XManager
+ 可视化界面很简单，过程如下：

![调出菜单](view-1.png)
![选择镜像选项](view-2.png)
![选择存储池](view-3.png)
![选择真正镜像路径](view-4.png)
![设置内存与cpu](view-5.png)
![设置磁盘](view-6.png)
![设置kvm名称](view-7.png)
![启动引导kvm](view-8.png)

+ 网卡选择上面设置的br0桥接模式。
+ 如果选择的是默认的 virbr0 这个则是 NAT模式另起一个局域网，网段为：192.168.122.0/24
+ 可视化界面的话，相对来说比较简单就不详细结束了。
+ 下面来说说命令版本的吧

#### 2、命令安装KVM虚拟机
+ 命令安装需要用到：`virt-install` 命令。
+ virt-install是一个使用libvirt库创建虚拟机或容器的命令行工具，参数比较多
+ virt-install的命令选项可通过：`virt-install -h`显示详细信息
+ 如下解析常用的参数

**基本参数**
+ `--name`
虚拟机名称
+ `--memory`
配置虚拟机内存容量，单位MB
+ `--vcpus`
虚拟机cpu数量。更进一步可以通过该参数设置cpu热拔插和其他更复杂的拓扑结构。
+ `--metadata`
可选，可配置虚拟机的一些属性
+ `--os-type`
操作系统类型，如linux、unix或windows等

**安装方式**
+ `--cdrom`
指定使用cdrom光驱启动，指定镜像路径
+ `--location`
本地iso路径安装方式，使用该参数指定安装，默认是看不到guest安装过程中的输出文本的，需要另外配置参数`--extra-args 'console=ttyS0'`
+ `--import`
使用已有的磁盘镜像，直接跳过安装过程，使用第一个`--disk` 参数指定的磁盘做启动设备

**存储参数**
+ `--disk`
指定虚拟硬盘文件路径，有多种介质可选。比如指定本地文件可以使用path选项，如果指定文件不存在还需要设置size参数。

**网络配置**
+ `--network`
指定虚拟机连接的网络配置,如：`--network bridge=br0` 选择我们配置的桥接网卡br0
默认的话是 `--network default` 使用的是 virbr0 

**图形化配置**
+ `--graphics`
可以不使用图形化配置：`--graphics none`,可以通过`virt-manager` 进入。
也可以`--graphics vnc,listen=0.0.0.0,port=5924` 或`--graphics vnc,port=6031,keymap=en_us` 配置vnc

**其他**
+ `--noautoconsole`
不自动连接虚拟机控制台
+ `--autostart`
主机开机自启动

##### 2.1、virt-install安装Centos7
+ 例子如下：
```bash
virt-install \
--name centos7 \
--memory 2048 \
--vcpus 2 \
--network bridge=br0 \
--graphics vnc \
--disk path=/kvm/img/centos7.img,size=10 \
--os-variant auto \
--location /kvm/iso/CentOS7-mini.iso \
--extra-args 'console=ttyS0' \
--noautoconsole
```

### 四、KVM相关命令
主要命令：
+ vrish
+ virt-install
+ 参数贼多，vrish还分好几大模块的命令，如：磁盘存储、快照、网络、guest虚拟机管理...等等


#### 1、常用virsh命令
```bash
# 查看运行的虚拟机
virsh list

# 查看所有的虚拟机（关闭和运行的虚拟机）
virsh list –all

# 连接虚拟机，ctrl+] 退出虚拟机
virsh console 域名 （虚拟机的名称）

# 关闭虚拟机
virsh shutdown 域名

# 挂起虚拟机
virsh suspend 域名

# 恢复被挂起的虚拟机
virsh resume 域名

# 子机随宿主主机（母机）启动而启动
virsh autostart 域名

# 取消自动启动
virsh auotstart –disable +域名

# 强制关闭虚拟机（相当于拔电源）
virsh destroy 域名 

# 解除标记 
virsh undefine 域名 

# 启动虚拟机并进入该虚拟机
virsh start 域名 –console

# 查看虚拟机配置文件
virsh dumpxml 域名

# 重命名
virsh domrename 域名 域名1

# 重启
virsh reboot 域名

# 查看虚拟机信息
virsh dominfo 域名

# 查看虚拟机磁盘
virsh domblklist 域名

# 查看虚拟网卡
virsh domiflist 域名

# 更改虚拟机配置,libvirt使用xml文件来定义虚拟机配置
virsh edit 域名

# 查看vnc端口号
virsh vncdisplayer --domain 域名 

# 创建虚拟机快照，不指定名称系统会默认命名为一个ID信息，可以通过快照信息查看。
virsh snapshot-create centos7

# 或者指定快照名称：
virsh snapshot-create-as centos7 first_snap

# 查看虚拟机快照信息
virsh snapshot-list centos7

# 查看当前快照信息
virsh snapshot-current centos7

# 恢复指定的快照
virsh snapshot-revert centos7  first_snap

# 删除指定的快照
virsh snapshot-delete centos7 first_snap

# 太多了，写累了
pool-autostart      自动启动某个池pool-build 建立池
pool-create-as      从一组变量中创建一个池
pool-create         从一个 XML 文件中创建一个池
pool-define-as      在一组变量中定义池
pool-define         在一个XML文件中定义（但不启动）一个池或修改
pool-delete         删除池
pool-destroy        销毁（删除）池
pool-dumpxml        将池信息保存到XML文档中
pool-edit           为存储池编辑 XML 配置
pool-info           查看存储池信息
pool-list           列出池
pool-name           将池 UUID 转换为池名称
pool-refresh        刷新池
pool-start          启动一个（以前定义的）非活跃的池
pool-undefine       取消定义一个不活跃的池
pool-uuid           把一个池名称转换为池 UUID

# 网络相关
net-autostart   自动启动网络
net-create      从XML文件创建网络
net-define      定义一个非活动的持久虚拟网络或从XML文件修改一个现有的持久虚拟网络
net-destroy     停止网络
net-dhcp-leases 打印给定网络的租赁信息
net-dumpxml     XML文件中的网络信息
net-edit        编辑网络的XML配置文件
net-info        网络信息网表列表网络
net-list        网络列表
net-event       Network Events
net-name        将网络UUID转换为网络名称
net-start       启动一个（先前定义的）非活动网络
net-undefine    取消定义持久性网络
net-update      更新现有网络配置的部分
net-uuid        将网络名称转换为网络UUID

# vol相关
vol-clone           克隆卷。
vol-create-as       从一组变量中创建卷
vol-create          从一个 XML 文件创建一个卷
vol-create-from     生成卷，使用另一个卷作为输入。
vol-delete          删除卷
vol-download        将卷内容下载到文件中
vol-dumpxml         保存卷信息到XML文档中
vol-info            查看存储卷信息
vol-key             根据卷名或路径返回卷的key
vol-list            列出卷
vol-name            根据给定卷key或者路径返回卷名
vol-path            根据卷名或key返回卷路径
vol-pool            为给定密钥或者路径返回存储池
vol-resize          重新定义卷大小
vol-upload          将文件内容上传到卷中
vol-wipe            擦除卷

```


#### 2、创建一个ISCSI存储池
+ 预先创建好一个xml配置文件,假设文件名为 `/kvm/pool/pool_iscsi`,
+ 内容如下：(host为需要远程的物理机ip地址,device为iqn序列号)
```xml
<pool type='iscsi'>
  <name>my_iscsi_pool</name>
  <source>
	<host name='192.168.1.71' port='3260'/>
	<device path='iqn.2021-02.me.mibine:server.target1'/>
  </source>
  <target>
	<path>/dev/disk/by-path</path>
  </target>
</pool>
```
+ 在预配置好xml之后，执行如下命令:定义存储池
```shell
virsh pool-define /kvm/pool/pool_iscsi
```
+ 启动存储池
```shell
# (my_iscsi_pool为xml里面的name)(此时默认的状态是已经启动，但是并没有设置开机自启动)
virsh pool-start my_iscsi_pool 

# 设置开机自启动
virsh pool-autostart my_iscsi_pool

# 查看pool里面的卷
virsh vol-list --pool my_iscsi_pool
```
+ 编辑存储池
```shell
virsh pool-edit my_iscsi_pool
```
+ 删除存储池
```shell
# 这里需要先将存储池状态改为inactive
virsh pool-destroy my_iscsi_pool
virsh pool-delete my_iscsi_pool

# 取消定义
virsh pool-undefine my_iscsi_pool
```

##### 安装通过ISCSI挂载的镜像
+ 首先保证iscsi的镜像是有引导的完整镜像
+ 然后通过`--import` 参数使用第一个`--disk`作为启动设备
```shell
virt-install \
--name autorecove88 \
--memory 2048 \
--vcpus 2 \
--network bridge=br0 \
--graphics vnc \
--disk path=/dev/disk/by-path/ip-192.168.2.73:3260-iscsi-iqn.2000-03.com.dcstechnology-ods.ODS-yanfa-Quorum.kvm72-0-lun-0 \
--os-variant auto \
--noautoconsole \
--import
```

![](install-iscsi.png)

#### 3、创建基于文件夹的存储池
+ 创建存储池所在目录
```shell
mkdir /home/data/kvm/pool
```
+ 定义存储池于该目录
```shell
virsh pool-define-as pool_name --type dir --target /home/data/kvm/pool
```
+ 创建已经创建的存储池
```bash
# 创建已经创建的存储池
virsh pool-build pool_name

# 查看存储池
virsh pool-list --all

# 查看池信息
virsh pool-info pool_name

# 设置开机自启动并激活存储池
virsh pool-autostart pool_name

# 启动
virsh pool-start pool_name

# 在这个存储池上，创建一个虚拟机存储卷
virsh vol-create-as --pool pool_name test.qcow2 20G --format qcow2


# 查看pool里面的卷
virsh vol-list --pool pool_name 

# 删除某个存储池下的某个卷
virsh vol-delete --pool pool_name --vol test.qcow2 
```

#### 4、磁盘管理
```bash
# 创建磁盘
qemu-img create -f qcow2 /data/centos7.qcow2 10G

# 查看磁盘信息
qemu-img info /data/centos7.qcow2

# 调整磁盘容量，只能加不能减
qemu-img resize /data/centos7.qcow2 1T

# 将一块raw格式的虚拟磁盘文件转换成qcow2格式
# -f 指定需要转换文件的文件格式，-O 指定要转换的目标格式
qemu-img convert -f raw -O qcow2 centos7.raw centos7.qcow2  

# 检查文件是否损坏
qemu-img check centos7.qcow2

# 临时添加磁盘
virsh attach-disk centos7 /data/centos7-add.qcow2 vdb --subdriver qcow2

# 永久添加磁盘
virsh attach-disk centos7 /data/centos7-add.qcow2 vdb --subdriver qcow2
virsh attach-disk centos7 /data/centos7-add.qcow2 vdb --subdriver qcow2 --config

# 临时剥离磁盘
virsh detach-disk centos7 vdb

# 永久剥离磁盘
virsh detach-disk centos7 vdb
virsh detach-disk centos7 vdb --config
```

### 五、工具篇

#### 1、bash-completion
可以使命令参数自动补全的工具，按 `Tab` 键自动补全参数命令
```
# 安装命令自动补全
yum -y install bash-completion
# 重启生效
reboot
```

#### 2、libguestfs-tools
libguestfs 是一组 Linux 下的 C 语言的 API ，用来访问虚拟机的磁盘映像文件。
该工具包内包含的工具有
+ virt-cat、
+ virt-df、
+ virt-ls、
+ virt-copy-in、
+ virt-copy-out、
+ virt-edit、
+ guestmount、
+ guestunmount、
+ guestfish
+ virt-list-filesystems、
+ virt-list-partitions
+ virt-customize
+ ...等等


+ 安装使用如下：

```bash
# libguestfs-winsupport 使其支持windows系统镜像
yum install -y libguestfs-tools libguestfs-winsupport

# 类似 linux 的df 命令，domainName 虚拟机名称
virt-df -h domainName 
virt-df centos7.qcow2

# 类似cat 命令，查看文件
virt-cat -d domainName /etc/hosts

# 类似 vi 命令，需要关闭虚拟机
virt-edit -d domainName /etc/hosts

# 类似 ls 命令，显示目录的文件
virt-ls -d domainName /etc/sysconfig/

# 复制虚拟机文件（ifcfg-eth0）到宿主机本地磁盘(/root下)，类似 cp 命令
virt-copy-out -d domainName /etc/sysconfig/network-scripts/ifcfg-eth0 /root/

# 复制宿主机文件(/root/test.sh) 到 虚拟机（/root下）到，类似 cp 命令，需要关闭虚拟机
virt-copy-in -d domainName /root/test.sh /root/

# 查看虚拟机的分区信息
virt-filesystems -d domainName

# virt-tar 上传本地的压缩文件到虚拟机并解压
virt-tar [--options] -u domname /local/tarball /disk/directory
virt-tar [--options] disk.img [disk.img ...] -u tarball directory


# 上传本地压缩文件到虚拟机并解压
virt-tar-in -d domainName /local/tarball  /disk/directory

# 打包镜像中文件并且拷贝出来，-z 使用 gzip 进行压缩
virt-tar -zx domainName /root/casashell casashell.tar.gz

# 压缩文件拷贝出虚拟机并解压
virt-tar-out -d domainName /local/dir /disk/path/to/tar-file

# 挂载虚拟机到宿主机目录
# -a 指定虚拟磁盘，-d 指定虚拟实例名，即在虚拟机管理器中显示的名称
# -m 指定被挂载的分区，--rw 表示以读写的形式挂载到宿主机中，–ro 以只读的形式挂载
guestmount -d domainName -m /dev/sda --rw /mnt/directory

# 取消挂载
guestunmount /mnt/directory
umount /mnt/directory

# 交互式shell
guestfish -a centos7.qcow2 --rw
```

#### 3、vnc 连接
+ 修改配置文件`vim /etc/libvirt/qemu.conf`,把`vnc_listen`注释打开为：`vnc_listen = "0.0.0.0"`
+ 下载 noVNC，或者 `git clone https://github.com/novnc/noVNC.git`
+ 命令显示vnc的监听信息：`virsh vncdisplay --domain youDomainName`,
+ 如果显示的是`127.0.0.1:0` vnc就是5900端口，`127.0.0.1:1` vnc就是5901端口，以此类推...
+ 执行noVNC下的：`./utils/launch.sh --vnc localhost:5900`。启动noVNC 前端页面，默认是6080端口
+ 执行过程中，noVNC 会去 GitHub 下载 websockify，如果觉得下载太慢.
+ 可先将 websockify 下载下来后，解压到vnc的 utils 文件夹下并命名为：`websockify`
+ websockify下载地址： `https://github.com/novnc/websockify/releases`
+ 启动成功之后，即可访问：`http://host:6080/vnc.html?host=host&port=6080`,把host修改为你的ip即可。
+ 防火墙记得开放6080端口。


![](novnc.png)
