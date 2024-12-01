---
title: MBR与GPT浅析
date: 2018-07-11 17:07:59
updated: 2018-07-11 17:07:59
tags: [磁盘, 系统装机]
categories: 网络运维
---

## 一、概述
先了解下含义

### 1、BIOS
BIOS是一组固化到主板中一个ROM芯片上的程序，它可以从CMOS中读写系统设置的具体信息，它可以对主板上的键盘、鼠标、外部接口、频率、电源、磁盘驱动器等方面进行参数控制和调整。我们常用的调整硬盘或U盘的启动顺序，电源管理的设置或者一些超频设置。都是在BIOS中完成的。

### 2、UEFI
UEFI：全称“统一的可扩展固件接口”(Unified Extensible Firmware Interface)， 是一种详细描述类型接口的标准。
这种接口用于操作系统自动从预启动的操作环境，加载到一种操作系统上。可以说UEFI是BIOS的升级版，从上世纪九十年代就开始开发。
UEFI运行于32或64位模式，它突破了传统16位代码的寻址能力，达到处理器的最大寻址，克服了BIOS代码运行缓慢的弊端

<!--more-->

### 3、MBR
MBR：Master Boot Record，主分区引导记录，是IBM公司早年间提出的。
它是存在于磁盘驱动器开始部分的一个特殊的启动扇区。这个扇区包含了已安装的操作系统系统信息，并用一小段代码来启动系统。
如果你安装了Windows，其启动信息就放在这一段代码中——如果MBR的信息损坏或误删就不能正常启动Windows，
这时候你就需要找一个引导修复软件工具来修复它就可以了。Linux系统中MBR通常会是GRUB加载器。
当一台电脑启动时，它会先启动主板自带的BIOS系统，bios加载MBR，MBR再启动Windows，这就是MBR的启动过程。
MBR作为传统legacy的bios启动方式。

**缺点：**
+ 最大可存储空间为2T（由于硬盘制造商采用1:1000进行单位换算，所以可能会有2.2T）
+ 硬盘分区表DPT（Disk Partition Table）只有64字节，每个分区项占用16个字节，最多支持四个主分区
+ 扩展分区一个硬盘只能有一个

### 4、GPT
GPT分区：全称为Globally Unique Identifier Partition Table，也叫做GUID分区表，它是UEFI 规范的一部分。
由于硬盘容量的急速增长，MBR的2.2T容量难以满足要求，而UEFI BIOS的推广也为GPT的实现打下了坚实的技术基础，GPT应运而生。

**与MBR的区别**
+ 最大支持18EB（`1EB=1024PB=1,048,576TB`）的硬盘,理论上无效大吧
+ 是基于UEFI使用的磁盘分区架构，所以GPT仅可用UEFI引导系统。无法使用BIOS引导
+ UEFI + GPT 开机启动更快，开机时跳过外设检测。
+ UEFI + GPT 支持`Secure Boot`。通过保护预启动或预引导进程，抵御bootkit攻击，从而提高安全性。
+ 所有在开机时比Windows内核更早加载，实现内核劫持的技术，都可以称之为Bootkit。

## 二、Linux与磁盘相关的命令

Linux磁盘常用的相关命令

```js

//用于列出所有可用块设备的信息，查看系统的分区和挂载情况
lsblk
lsblk -f

// 查看磁盘分区
fdisk -l

// 格式化(fdisk -l 查看设备，lsblk)
mkfs.ext3 /dev/sdb

sudo mkfs -t ntfs /dev/sdb1
或
sudo mkfs.ntfs /dev/sdb1
或者
sudo mkntfs /dev/sdb1


// 查看设备ID
lS -l /dev/disk/by-id/


// 查看磁盘分区
parted -l

// 挂载
mount /dev/sdd /data/mount
// 指定文件格式挂载
mount -t ext4 /dev/sdd /data/mount

//解除挂载
umount /data/mount


// parted分区

//将分区设置成gpt格式
parted  /dev/sdc mklabel gpt

// 创建一个20G的分区
parted /dev/sdc mkpart primary 0 20000

//将剩余的空间全部创建成一个扩展分区 
parted /dev/sdc mkpart extended 1 100%


// /dev/sdd 分区分成1个分区
parted /dev/sdd mklabel gpt
parted /dev/sdd mkpart primary 0 100%
```


**iscsi命令相关**

```
// 服务发现
iscsiadm -m discovery -t st -p 192.168.1.160

// 登陆
iscsiadm -m node -T iqn.test-iSCSI-0 -l
iscsiadm -m node -T iqn.test-iSCSI-0 -p 192.168.1.160 -l
iscsiadm -m node -T iqn.test-iSCSI-0 -p 192.168.1.160:3260 -l

// 注销
iscsiadm -m node -T iqn.test-iSCSI-0 -p 192.168.1.160:3260 –u
// 退出所有登陆的目标器
iscsiadm -m node -U all


// 连接死掉（断网或者target端断掉）时，使用如下指令：
iscsiadm -m node -o delete –T  iqn.test-iSCSI-0 -p 192.168.1.160

// 查看目标记录列表
iscsiadm -m node

//命令刷新（rescan）已连接的iSCSI session以识别新的SAN资源
iscsiadm -m session -R

```
