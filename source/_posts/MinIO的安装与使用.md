---
title: MinIO的安装与使用
date: 2022-08-10 14:12:58
updated: 2022-08-10 14:12:58
tags: [MinIO]
categories: 开发工具
---

### 一、MinIO是什么
- MinIO 是一款高性能、分布式的对象存储系统. 它是一款软件产品, 可以100%的运行在标准硬件。即X86等低成本机器也能够很好的运行MinIO。
- MinIO与传统的存储和其他的对象存储不同的是：它一开始就针对性能要求更高的私有云标准进行软件架构设计。因为MinIO一开始就只为对象存储而设计。所以他采用了更易用的方式进行设计，它能实现对象存储所需要的全部功能，在性能上也更加强劲，它不会为了更多的业务功能而妥协，失去MinIO的易用性、高效性。 这样的结果所带来的好处是：它能够更简单的实现局有弹性伸缩能力的原生对象存储服务。
- MinIO在传统对象存储用例（例如辅助存储，灾难恢复和归档）方面表现出色。同时，它在机器学习、大数据、私有云、混合云等方面的存储技术上也独树一帜。当然，也不排除数据分析、高性能应用负载、原生云的支持。
- MinIO主要采用Golang语言实现，，客户端与存储服务器之间采用http/https通信协议。
- 它与 Amazon S3 云存储服务 API 兼容

<!--more-->

### 二、MinIO的相关信息
- 中文官网: [http://www.minio.org.cn/](http://www.minio.org.cn/)
- 中文文档: [http://docs.minio.org.cn/docs/](http://docs.minio.org.cn/docs/)
- 中文下载地址：[http://www.minio.org.cn/download.shtml#/linux](http://www.minio.org.cn/download.shtml#/linux)
- 英文官网: [https://min.io/](https://min.io/)
- 英文文档: [https://docs.min.io/](https://docs.min.io/)
- 英文下载地址：[https://min.io/download#/linux](https://min.io/download#/linux)
- Github地址：[https://github.com/minio/minio](https://github.com/minio/minio)

### 三、安装MinIO
- 安装MinIO的方式有很多种哈
- 例：Kubernetes、Docker、Linux、Windows、等等

#### 1、Windows安装MinIO
- 可以使用*管理员终端*，一定要是管理员终端哈。
- 普通终端可能会没有 `Invoke-WebRequest` 这个命令，会报错：`'Invoke-WebRequest' 不是内部或外部命令，也不是可运行的程序`

```shell
# 下载minio.exe ,保存到 D:\package\minio.exe
PS> Invoke-WebRequest -Uri "https://dl.min.io/server/minio/release/windows-amd64/minio.exe" -OutFile "D:\package\minio.exe"

# 设置环境变量 MINIO_ROOT_USER 等于 root
PS> setx MINIO_ROOT_USER root
# 设置环境变量 MINIO_ROOT_PASSWORD 等于 root123456
PS> setx MINIO_ROOT_PASSWORD root123456

# 启动 minio ,数据位置在 D:\minio_data ，API端口 9000  ，控制台访问端口 9001
PS>  D:\package\minio.exe server D:\minio_data --address :9000 --console-address ":9001"
```

- 上面是使用命令下载与设置环境变量，当然也是可以手动下载和手动设置环境变量的哈
- 这里注意一点就是  设置密码 的环境变量需要大于等于8位，否则会报错。
- 我设置之后的环境变量如下：


![env.png](env.png)

- 启动之后如下图显示就成功了：


![控制台](console.png)


#### 2、Linux 安装MinIO
- 后期补充



### 四、控制台介绍
- 访问：[http://127.0.0.1:9001/login](http://127.0.0.1:9001/login)
- 然后账号密码是上面设置的 MINIO_ROOT_USER 与 MINIO_ROOT_PASSWORD 环境变量
- 我这边设置的，账号是：root 	密码是：root123456
- 登录之后就可以创建一个桶（buckets）,控制台界面如下：


![桶](bucket.png)



### 五、代码的调用
- 安装成功并启动之后，就可以使用API了
- 但是API的调用需要一对密钥串，可以在控制台生成
- 点击：`Identity`  --> `Service Accounts` -->  `Create service account` 
- 如上步骤创建之后，保存密钥后面代码用到


![密钥](key.png)


#### 1、导入POM依赖
- 导入依赖

```
<dependency>
    <groupId>io.minio</groupId>
    <artifactId>minio</artifactId>
    <version>8.4.3</version>
</dependency>
<dependency>
    <groupId>com.squareup.okhttp3</groupId>
    <artifactId>okhttp</artifactId>
    <version>4.9.3</version>
</dependency>
```
- 因为MinIO用到 okhttp ，所以要导一下okhttp依赖


#### 2、简单的示例代码
- 常用的API就是 上传与下载

```java
import cn.hutool.core.io.file.FileWriter;
import io.minio.*;

import java.io.File;
import java.io.FileInputStream;
import java.io.InputStream;

public class MinIoDemo {

    public static void main(String[] args) throws Exception {

        String url = "http://192.168.1.120:9000";
        String accessKey = "nfsFUl88jCwtAX3F";
        String secretKey = "RV8WQmgbY3LhQzNoDq6UWrmUmeQezu3m";
        // 桶名
        String bucketName = "test";

        // 创建MinIO 客户端
        MinioClient minioClient =
                MinioClient.builder()
                        .endpoint(url)
                        .credentials(accessKey, secretKey)
                        .build();

        // 校验桶
        boolean found = minioClient.bucketExists(BucketExistsArgs.builder().bucket(bucketName).build());
        if (!found) {
            // 创建桶
            minioClient.makeBucket(MakeBucketArgs.builder().bucket(bucketName).build());
        } else {
            System.out.println("桶名="+bucketName+" 已存在");
        }
        // 你要上传的文件名
        String saveFilename = "test.json";
        // 本地上传
        minioClient.uploadObject(
                UploadObjectArgs.builder()
                        .bucket(bucketName)
                        .object(saveFilename)
                        .filename("D:\\a.json")
                        .build());

        // IO流上传
        ObjectWriteResponse objectWriteResponse = minioClient.putObject(PutObjectArgs.builder().bucket(bucketName)
                .object(saveFilename)
                .stream(new FileInputStream(new File("D:/a.json")), -1, 5242880).build());


        // 下载到本地
        minioClient.downloadObject(DownloadObjectArgs.builder().bucket(bucketName).object(saveFilename).filename("D:/test/abc1.json").build());

        // 下载得到IO流
        InputStream inputStream = minioClient.getObject(GetObjectArgs.builder().bucket(bucketName).object(saveFilename).build());
        // hutools 工具类的文件写入
        FileWriter fileWriter = new FileWriter("D://test2.json");
        fileWriter.writeFromStream(inputStream, true);
    }
}
```

- MinioClient 下面还有很多方法哈，可以自己去研究下。
