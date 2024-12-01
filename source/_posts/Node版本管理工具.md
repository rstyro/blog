---
title: Node版本管理工具nvm
date: 2022-12-09 20:32:07
updated: 2022-12-09 20:32:07
tags: [node.js]
categories: 前端
---

### 一、Node.js版本管理工具
- 在开发项目中，多个项目使用的node.js版本可能不一样，
- 切换版本很麻烦，所以诞生了版本管理工具
  - nvm	
  - nvs  是跨平台的，基于 Node 编写的
- 常见的有两个工具可以使用哈，两者的用法差不多

<!--more-->

#### 1、nvm
- 我一般用这个
- 下载安装包地址：[https://github.com/coreybutler/nvm-windows/releases](https://github.com/coreybutler/nvm-windows/releases)
- 可以选择最新的版本下载安装(window选择nvm-setup.exe)


**详细用法：**
```bash
# 查看命令使用
nvm -h


# 1. 查看node的可用版本
nvm list available

# 2. 查看已安装的node版本
nvm list

# 3. 根据node的版本号安装node、(16.17.0是版本号)
nvm install 16.16.0  

# 4. 卸载已安装的node版本号
nvm uninstall 16.16.0

# 5. 切换node版本
nvm use 16.17.0

```

**常见问题:**
- 切换版本报错，（解决办法：使用管理员的命令行窗口）

#### 2、nvs
- 下载nvs地址：[https://github.com/jasongin/nvs/releases](https://github.com/jasongin/nvs/releases)
- 直接下载可运行安装的就行

**用法：**
```bash
# 获取命令的详细帮助
nvs help <command>	

# 初始化并使用 NVS
nvs install	

# 从 profile 和 environment 中移除 NVS
nvs uninstall	

# 展示 NVS 版本
nvs --version	

# 下载某个版本的 Node.js
nvs add [version]	

# 移除某个版本的 Node.js
nvs rm <version>	

# 迁移全局的node_modules
nvs migrate <fromver> [tover]	

# 更新当前环境的 Node.js 至最新版本
nvs upgrade [fromver]	

#选择使用某个版本的 Node.js
nvs use [version]	

# 使用 cwd 自动切换
nvs auto [on/off]	

# 使用 Node.js 的某个版本的去执行 js 应用
nvs run <ver> <js> [args...]	

# 使用 Node.js 的某个版本的去执行 可执行文件
nvs exec <ver> <exe> [args...]	

#显示 Node.js 的某个版本的二进制文件的路径
nvs which [version]	

# 展示本地下载的 Node.js 版本列表
nvs ls [filter]	

# 列出可下载的 Node.js 版本
nvs ls-remote [filter]	

# 列出可下载的 Node.js 版本
nvs lsr [filter]	

# 设置一个软连接指向一个版本，作为默认使用的版本
nvs link [version]	

# 删除指向默认版本的链接
nvs unlink [version]	

# 给某个版本设置一个别名
nvs alias [name] [value]	

#设置下载node的仓库
nvs remote [name] [value]	
```

- ok...
