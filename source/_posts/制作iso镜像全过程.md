---
title: 制作iso镜像全过程
date: 2021-02-04 11:39:08
updated: 2021-02-04 11:39:08
tags: [Linux,系统装机]
categories: 网络运维
---
### 一、windows制作iso镜像
+ 使用UltraISO软碟通制作iso镜像
+ 下载地址：[https://cn.ultraiso.net/xiazai.html](https://cn.ultraiso.net/xiazai.html)
+ 下载安装后打开

<!--more-->

#### 制作iso
+ 在软碟通左下角本地目录选择你要制作镜像的文件
+ 然后在右边会显示你要的文件，全选右键添加
+ 然后上边就会显示你已添加的文件
+ 然后点击“文件”按钮，选择另存为即可保存为iso文件
+ 操作流程图如下：

![](1.png)
![](2.png)
![](3.png)
![](4.png)

**到此制作结束**

### 二、Linux（centos）制作iso镜像
+ Linux制作iso有多种方法，本篇介绍：`mkisofs` 命令
+ 使用`mkisofs`命令需要安装：`yum -y install genisoimage`即可
+ 制作iso命令格式：`mkisofs -r -o 生成的iso名称.iso 文件或目录`
+ 示例iso命令：`mkisofs -r -o isoname.iso /data`
+ 就会在当前目录下生成 `isoname.iso` 镜像文件

![](centos.png)

#### 1、mkisofs常用参数


|参数 <div style="width:380px;"></div>|说明|
|:--:|--|
|`a`或`--all`| mkisofs通常不处理备份文件。使用此参数可以把备份文件加到映像文件中。|
|`-A`<应用程序ID>或`-appid`<应用程序ID>| 指定光盘的应用程序ID。|
|`-abstract`<摘要文件> |指定摘要文件的文件名。|
|`-b`<开机映像文件>或`-eltorito-boot`<开机映像文件> |指定在制作可开机光盘时所需的开机映像文件。|
|`-biblio`<ISBN文件>| 指定ISBN文件的文件名，ISBN文件位于光盘根目录下，记录光盘的ISBN。|
|`-c`<开机文件名称> |制作可开机光盘时，mkisofs会将开机映像文件中的全-eltorito-catalog<开机文件名称>全部内容作成一个文件。|
|`-C`<盘区编号，盘区编号> |将许多节区合成一个映像文件时，必须使用此参数。|
|`-copyright`<版权信息文件> |指定版权信息文件的文件名。|
|`-d`或`-omit-period` |省略文件后的句号。|
|`-D`或`-disable-deep-relocation` |ISO 9660最多只能处理8层的目录，超过8层的部分，RRIP会自动将它们设置成ISO 9660兼容的格式。使用-D参数可关闭此功能。|
|`-f` 或 `-follow-links`| 忽略符号连接。|
|`-h` |显示帮助。|
|`-hide`<目录或文件名> |使指定的目录或文件在ISO 9660或Rock RidgeExtensions的系统中隐藏。|
|`-hide-joliet` <目录或文件名>| 使指定的目录或文件在Joliet系统中隐藏。|
|`-J` 或 `-joliet` |使用Joliet格式的目录与文件名称。|
|`-l` 或 `-full-iso9660-filenames`| 使用ISO 9660 32字符长度的文件名。|
|`-L` 或 `-allow-leading-dots` |允许文件名的第一个字符为句号。|
|`-log-file`<记录文件> |在执行过程中若有错误信息，预设会显示在屏幕上。|
|`-m`<目录或文件名>或 `-exclude`<目录或文件名> |指定的目录或文件名将不会房入映像文件中。|
|`-M`<映像文件>或`-prev-session`<映像文件> |与指定的映像文件合并。|
|`-N` 或`-omit-version-number`| 省略ISO 9660文件中的版本信息。|
|`-o`<映像文件>或`-output`<映像文件>| 指定映像文件的名称。|
|`-p`<数据处理人>或`-preparer`<数据处理人>| 记录光盘的数据处理人。|
|`-print-size` |显示预估的文件系统大小。|
|`-quiet` |执行时不显示任何信息。|
|`-r` 或 `-rational-rock` | 使用Rock Ridge Extensions，并开放全部文件的读取权限。|
|`-R` 或 `-rock` | 使用Rock Ridge Extensions。|
|`-sysid`<系统ID> |指定光盘的系统ID。|
|`-T` 或 `-translation-table` | 建立文件名的转换表，适用于不支持Rock Ridge Extensions的系统上。|
|`-v` 或 `-verbose` |执行时显示详细的信息。|
|`-V`<光盘ID>或 `-volid`<光盘ID> |指定光盘的卷册集ID。|
|`-volset-size`<光盘总数>| 指定卷册集所包含的光盘张数。|
|`-volset-seqno`<卷册序号> |指定光盘片在卷册集中的编号。|
|`-x`<目录> |指定的目录将不会放入映像文件中。|
|`-z`| 建立通透性压缩文件的SUSP记录，此记录目前只在Alpha机器上的Linux有效。|


### 三、离线安装mkisofs
+ 首先需要一台可以联网的查看 mkisofs的依赖
+ 执行命令：`yum deplist genisoimage` 查看mkisofs依赖
+ 得到依赖，然后去[镜像仓库](http://mirrors.aliyun.com/centos/7/os/x86_64/Packages/)下载对应的rpm依赖
+ 阿里镜像仓库：[http://mirrors.aliyun.com/centos/7/os/x86_64/Packages/](http://mirrors.aliyun.com/centos/7/os/x86_64/Packages/)
+ 强制离线安装rpm

**依赖如下：**
```
bash-4.2. 46-34.el7. x8664.rpm 
bzip2-libs-1.0.6-13.el7.x86 64.rpm
chkconfig-l.7.6-1.el7. x86_ 64.rpm
coreutils-8.22-24.el7.x86 64.rpm 
file-libs-5.11-37.el7.x86 64.rpm
genisoimage-1.1.11-25.el7.x86 64.rpm
glibc-2. 17-317. el7.x86_ 64.rpm
Libusal-1.l. 11-25. el7.x86_ 64.rpm
zlib-l.2.7-18.el7.x86 64.rpm
```
**上传到服务器，进入包路径安装**
```
// 运行此命令会根据依赖按照顺序安装rpm
// --nodeps rpm在安装包时，不检查依赖关系，例如安装B，B依赖C导致无法安装，使用--nodeps就可以安装成功 
rpm -Uvh *.rpm --nodeps --force
```

![](deplist.png)


![](deplist-install.png)
