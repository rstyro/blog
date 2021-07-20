---
title: Java使用xjar加密jar包
date: 2021-07-20 11:27:29
updated: 2021-07-20 11:27:29
tags: [加密,xjar]
categories: Java
---

### 一、环境准备
+ Java环境
+ Go环境

### 二、快速开始
+ JDK 1.7 +

#### 1、引入依赖
```
<project>
    <!-- 设置 jitpack.io 仓库 -->
    <repositories>
        <repository>
            <id>jitpack.io</id>
            <url>https://jitpack.io</url>
        </repository>
    </repositories>
    <!-- 添加 XJar 依赖 -->
    <dependencies>
        <dependency>
            <groupId>com.github.core-lib</groupId>
            <artifactId>xjar</artifactId>
            <version>4.0.2</version>
            <scope>test</scope>
        </dependency>
    </dependencies>
</project>
```
+ 必须添加 `https://jitpack.io` Maven仓库.
+ 如果使用 JUnit 测试类来运行加密可以将 XJar 依赖的 scope 设置为 test.


**注意：**
+ 由于使用了阿里云Maven镜像可能导致无法从 jitpack.io 下载 XJar 依赖的问题
+ 在镜像配置的 mirrorOf 元素中加入 ,!jitpack.io 结尾.
+ ***参考：***
```
<mirror>
    <id>alimaven</id>
    <mirrorOf>central,!jitpack.io</mirrorOf>
    <name>aliyun maven</name>
    <url>http://maven.aliyun.com/nexus/content/repositories/central/</url>
</mirror>
```

#### 2、加密Jar包
+ 引入上面得依赖之后，给你的项目打包：`mvn clean package -Dmaven.test.skip=true`
+ 然后得到未加密的Jar包，之后使用xjar加密原包如下：

```
@SpringBootTest
class EncryptJarTest {

    // Jar包加密
    public static void main(String[] args) throws Exception {
        String projectPath = System.getProperty("user.dir");
        String srcjar = projectPath+"/target/myJarName.jar";
        String encryptJar = projectPath+"/target/myJarName-encrypt.jar";
        XCryptos.encryption()
        		//jar包生成的路径
        		.from(srcjar)
        		//密码
        		.use("yourPassword")
        		//加密后生成的路径
        		.to(encryptJar);
        // 设置哪些文件需要加密、哪些不加密
        // .include("/io/xjar/**/*.class")
        // .include("/mapper/**/*Mapper.xml")
        // .exclude("/static/**/*")
        // .exclude("/conf/*")
    }

}
```

+ 运行上面的加密代码之后会多生成两个文件：
+ ①、`myJarName-encrypt.jar`这个就是加密后的jar包
+ ②、`xjar.go`这个是Go启动器源码文件，通过不同平台编译这个可得对应平台得可执行程序



<table>
<thead>
    <tr>
        <th style="width:130px;">方法名称</th><th>参数列表</th><th style="width:120px;">是否必选</th><th>方法说明</th>
    </tr>
</thead>
<tbody>
    <tr>
        <td>from</td><td>(String jar)</td><td rowspan="2">二选一</td><td>指定待加密JAR包路径</td>
    </tr>
    <tr>
        <td>from</td><td>(File jar)</td><td>指定待加密JAR包文件</td>
    </tr>
    <tr>
        <td>use</td><td>(String password)</td><td rowspan="2">二选一</td><td>指定加密密码</td>
    </tr>
    <tr>
        <td>use</td><td>(String algorithm, int keysize, int ivsize, String password)</td><td>指定加密算法及加密密码</td>
    </tr>
    <tr>
        <td>include</td><td>(String ant)</td><td>可多次调用</td><td>指定要加密的资源相对于classpath的ANT路径表达式</td>
    </tr>
    <tr>
        <td>include</td><td>(Pattern regex)</td><td>可多次调用</td><td>指定要加密的资源相对于classpath的正则路径表达式</td>
    </tr>
    <tr>
        <td>exclude</td><td>(String ant)</td><td>可多次调用</td><td>指定不加密的资源相对于classpath的ANT路径表达式</td>
    </tr>
    <tr>
        <td>exclude</td><td>(Pattern regex)</td><td>可多次调用</td><td>指定不加密的资源相对于classpath的正则路径表达式</td>
    </tr>
    <tr>
        <td>to</td><td>(String xJar)</td><td rowspan="2">二选一</td><td>指定加密后JAR包输出路径, 并执行加密.</td>
    </tr>
    <tr>
        <td>to</td><td>(File xJar)</td><td>指定加密后JAR包输出文件, 并执行加密.</td>
    </tr>
</tbody>
</table>


+ 指定加密算法的时候密钥长度以及向量长度必须在算法可支持范围内, 具体加密算法的密钥及向量长度请自行百度或谷歌.
+ `include` 和 `exclude` 同时使用时即加密在include的范围内且排除了exclude的资源.


#### 3、编译生成可执行程序与运行加密Jar包
+ 如上，得到xjar.go 源文件，编译可得对应平台可执行程序
```
go build xjar.go
```
+ 将 xjar.go 在不同的平台进行编译即可得到不同平台的启动器可执行文件, 其中Windows下文件名为 `xjar.exe` 而Linux下为 `xjar`.
+ 用于编译的机器需要安装 Go 环境, 用于运行的机器则可不必安装 Go 环境, 具体安装教程请自行搜索.
+ 由于启动器自带JAR包防篡改校验, 故启动器无法通用, 即便密码相同也不行.

**启动加密包：**

```bash
/path/to/xjar /path/to/java [OPTIONS] -jar myJarName-encrypt.jar 


# 例如
nohup /path/to/xjar java -jar /opt/myJarName-encrypt.jar >out.log 2>&1 &
```

+ 在 Java 启动命令前加上编译好的Go启动器可执行文件名(xjar)即可启动运行加密后的JAR包.



### 三、插件集成
+ 上面是pom文件依赖集成，还有一种是通过集成` xjar-maven-plugin` 
+ 免去每次加密都要执行一次上述的代码
+ 过程略，详情步骤可参考：
+ **Github:**[https://github.com/core-lib/xjar](https://github.com/core-lib/xjar)
+ **Gitee:** [https://gitee.com/core-lib/xjar](https://gitee.com/core-lib/xjar)

