---
title: Spring Boot (十)：打包部署
date: 2017-09-20 16:03:10
updated: 2017-09-20 16:03:10
tags: [Spring Boot, Java]
categories: Java
---
# springboot 打包与部署

## 一、jar 包
> 进入命令行模式 ，不管linux 还是windows 都是一样的

#### 1、编译
##### 进入项目目录，使用如下命令： 
```
//命令打包（-Dmaven.test.skip=true 跳过测试）
mvn clean package -Dmaven.test.skip=true
```

#### 2.运行
##### 当前目录的target 就有一个.jar 文件
```
#启动命令
nohub java -jar xxxx.jar >/dev/null 2>&1 &
```

## 二、war 包
### 1、修改package
#### (a)、修改包类型
```
<!-- <packaging>jar</packaging> -->
<packaging>war</packaging>
```

#### (b)、移除内置的tomcat插件
```
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-web</artifactId>
    <!-- 移除tomcat插件 -->
    <exclusions>
        <exclusion>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-tomcat</artifactId>
        </exclusion>
    </exclusions>
</dependency>

<!-- 移除之后会报错，加入下面的依赖 -->
<dependency>
    <groupId>javax.servlet</groupId>
    <artifactId>javax.servlet-api</artifactId>
    <scope>provided</scope>
</dependency>
```
### 2、修改启动类
#### 继承SpringBootServletInitializer 类，重写configure（）方法
```java
package top.lrshuai.blog;

import org.mybatis.spring.annotation.MapperScan;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.builder.SpringApplicationBuilder;
import org.springframework.boot.context.embedded.ConfigurableEmbeddedServletContainer;
import org.springframework.boot.context.embedded.EmbeddedServletContainerCustomizer;
import org.springframework.boot.web.servlet.ErrorPage;
import org.springframework.boot.web.support.SpringBootServletInitializer;
import org.springframework.http.HttpStatus;

@SpringBootApplication
@MapperScan("top.lrshuai.blog.dao")
public class Application extends SpringBootServletInitializer{

	public static void main(String[] args) {
		SpringApplication.run(Application.class, args);
	}
	
	@Override
	protected SpringApplicationBuilder configure(SpringApplicationBuilder builder) {
		// TODO Auto-generated method stub
//		return super.configure(builder);
		return builder.sources(this.getClass());
	}
}
```
### 3、编译
#### (a)、和编译jar一样，`mvn clean package -Dmaven.test.skip=true`
#### (b)、(还有一种，`mvn clean install -Dmaven.test.skip=true`) 
> 如果是eclipse 则不用mvn


### 4、部署
#### 放入tomcat 的webapps 目录下，启动tomcat,搞定

## 三、可能出现的问题
### (a)、就是静态文件资源 访问404
### 解决方案：
#### 所有链接都写相对路径，可能以前你这样写`<link href="/css/blog.css" rel="stylesheet" >` 就可以了，打包jar 我记得好像是没问题的，但是war就出问题了
#### 正解应该是 `<link href="../static/css/blog.css" rel="stylesheet" th:href="@{/css/blog.css}">`

### (b)、另一种是js 的路径，比如发ajax请求。路径也会有问题
### 我的方案：
##### 1、页面头部添加这行`<meta name="_ctx" th:content="@{/}" />`
##### 2、js 获取它的路径，
```
<script type="text/javascript">
var _ctx = $("meta[name='_ctx']").attr("content");
_ctx = _ctx.substr(0, _ctx.length - 1);
</script>
```
##### 3、然后在每个ajax 请求的前面加入`_ctx` 。比如：` url = "/article/add"` 就改为` url = ctx+"/article/add"`

