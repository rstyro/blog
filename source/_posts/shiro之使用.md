---
title: shiro之使用
date: 2020-04-18 18:26:45
tags: [shiro]
categories: Java
---

## 一、shiro概述
+ shiro 是一个功能强大且易于使用的Java安全框架.
+ shiro官网：[http://shiro.apache.org/](http://shiro.apache.org/)
+ Github地址：[https://github.com/apache/shiro](https://github.com/apache/shiro)
+ shiro官方架构图

![](shiro.png)

## 二、主要名词解析
+ Subject
subject记录了当前操作用户，将用户的概念理解为当前操作的主体
+ SecurityManager
SecurityManager即安全管理器，对全部的subject进行安全管理，它是shiro的核心，负责对所有的subject进行安全管理。
+ Authenticator
Authenticator即认证器，对用户身份进行认证，Authenticator是一个接口，shiro提供ModularRealmAuthenticator实现类，也可以自定义认证器。
+ Authorizer
用户通过认证器认证通过，在访问功能时需要通过授权器判断用户是否有此功能的操作权限。
+ Realm
securityManager进行安全认证需要通过Realm获取用户权限数据
+ SessionManager
shiro框架定义了一套会话管理，它不依赖web容器的session
+ SessionDAO
是对session会话操作的一套接口
+ CacheManager
将用户权限数据存储在缓存，这样可以提高性能
+ Cryptography
shiro提供了一套加密/解密的组件，方便开发。比如提供常用的散列、加/解密等功能。

## 三、十分钟快速入门
+ 简单的运行一个dmeo

### 一、导入maven依赖

```
<dependency>
	<groupId>org.apache.shiro</groupId>
	<artifactId>shiro-core</artifactId>
	<version>1.7.1</version>
</dependency>
```

### 二、通过.ini 文件初始化一个Realm
+ 配置文件：名称随意，以 `.ini` 结尾，放在 `resources` 目录下
```
[users]
rstyro=123456
lrshuai=abc
```

### 三、运行代码
```
package top.rstyro.shiro;

import org.apache.shiro.SecurityUtils;
import org.apache.shiro.authc.AuthenticationException;
import org.apache.shiro.authc.IncorrectCredentialsException;
import org.apache.shiro.authc.UnknownAccountException;
import org.apache.shiro.authc.UsernamePasswordToken;
import org.apache.shiro.mgt.DefaultSecurityManager;
import org.apache.shiro.realm.text.IniRealm;
import org.apache.shiro.subject.Subject;

public class QuickstartShiro {
    public static void main(String[] args) {
        // 创建默认的安全管理器
        DefaultSecurityManager securityManager = new DefaultSecurityManager();
        // 通过.ini文件创建给安全管理器设置默认的Realm
        securityManager.setRealm(new IniRealm("classpath:shiro-config.ini"));
        // 全局安全工具类，设置安全管理器进行认证
        SecurityUtils.setSecurityManager(securityManager);
        // 创建令牌
        UsernamePasswordToken token = new UsernamePasswordToken("rstyro", "123456");
        // 得到当前的 subject，也就是当前的用户
        Subject subject = SecurityUtils.getSubject();
        try{
            // 打印是否授权
            System.out.println(subject.isAuthenticated());
            // 用户登陆认证
            subject.login(token);
            // true 登陆之后就是授权
            System.out.println(subject.isAuthenticated());
        }catch (UnknownAccountException e){
            System.out.println("用户不存在");
        }catch (IncorrectCredentialsException e){
            System.out.println("密码错误");
        }catch (AuthenticationException e){
            System.out.println("认证失败");
            e.printStackTrace();
        }

    }
}
```
+ 运行发现执行`subject.login(token)` 之后，认证成功了。
+ 所以我们在`subject.login(token)`通过debug进入到里面的实现
+ 调用到`DelegatingSubject.login()`-> `DefaultSecurityManager.login()`...->`AuthenticatingRealm.doGetAuthenticationInfo()`->`SimpleAccountRealm.doGetAuthenticationInfo()`
+ 也就是最终调用的认证就是`doGetAuthenticationInfo()`方法。

















