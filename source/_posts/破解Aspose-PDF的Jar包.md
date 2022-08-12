---
title: 破解Aspose-PDF的Jar包
date: 2022-08-12 10:39:47
updated: 2022-08-12 10:39:47
tags: [Java,Aspose]
categories: Java
---

### 一、Aspose.PDF简介
- Aspose.PDF是一个Java组件，旨在允许开发人员以编程方式动态创建PDF文档，无论是简单还是复杂。Aspose.PDF for Java允许开发人员将表格，图形，图像，超链接，自定义字体等插入到PDF文档中。此外，还可以压缩PDF文档。Aspose.PDF for Java 提供了出色的安全功能来开发安全的 PDF 文档。Aspose.PDF java最显着的特点是它支持通过API和XML模板创建PDF文档。

> 来自官网的一个介绍，简单的说就是，让开发人员更方便的操作 PDF。
> 

### 二、破解流程
- 下载Jar包
- 反编译修改要替换的class文件
- 重新打包

### 三、开始破解
- 下载Jar包，目前最新的版本是：`22.7.1`   2022年8月5号发布的。
- 下载地址：[https://repository.aspose.com/pdf/22-7-1/](https://repository.aspose.com/pdf/22-7-1/)
- 虽然官方写有Maven地址，但是我下载Jar包没下载下来，也设置了仓库地址：

```xml
<repository>
    <id>AsposeJavaAPI</id>
    <name>Aspose Java API</name>
    <url>https://repository.aspose.com/repo/</url>
</repository>
```
- 但是就是没下载下来，估计是网络问题，所以我选择手动下载，如下图：

![](download.png)

- 然后POM 使用 systemPath引入，因为最终你还是需要systemPath引入

```
<dependency>
            <groupId>com.aspose</groupId>
            <artifactId>aspose-pdf</artifactId>
            <version>22.7.1</version>
            <scope>system</scope>
           <systemPath>${project.basedir}/src/main/resources/lib/aspose-pdf-22.7.1.jar</systemPath>
</dependency>



<!-- Java字节码的类库,破解需要-->
<dependency>
    <groupId>org.javassist</groupId>
    <artifactId>javassist</artifactId>
    <version>3.29.0-GA</version>
</dependency>
```

- 包引入之后，就可以执行代码破解了，代码如下：

```java
import javassist.*;
import java.io.*;
import java.util.ArrayList;
import java.util.Enumeration;
import java.util.List;
import java.util.jar.JarEntry;
import java.util.jar.JarFile;
import java.util.jar.JarOutputStream;

public class PDFJarCrack {
    public static void main(String[] args) throws Exception {
        String property = System.getProperty("user.dir");
//        String jarPath =property+ "/src/main/resources/lib/aspose-pdf-22.4.jar";
		// 这个是jar包的存放路径
        String jarPath =property+ "/src/main/resources/lib/aspose-pdf-22.7.1.jar";
        // 破解方法
        crack(jarPath);
    }

    private static void crack(String jarName) {
        try {
            ClassPool.getDefault().insertClassPath(jarName);
            CtClass ctClass = ClassPool.getDefault().getCtClass("com.aspose.pdf.ADocument");
            CtMethod[] declaredMethods = ctClass.getDeclaredMethods();
            int num = 0;
            for (int i = 0; i < declaredMethods.length; i++) {
                if (num == 2) {
                    break;
                }
                CtMethod method = declaredMethods[i];
                CtClass[] ps = method.getParameterTypes();
                if (ps.length == 2
                        && method.getName().equals("lI")
                        && ps[0].getName().equals("com.aspose.pdf.ADocument")
                        && ps[1].getName().equals("int")) {
                    // 最多只能转换4页 处理
                    System.out.println(method.getReturnType());
                    System.out.println(ps[1].getName());
                    method.setBody("{return false;}");
                    num = 1;
                }
                if (ps.length == 0 && method.getName().equals("lt")) {
                    // 水印处理
                    method.setBody("{return true;}");
                    num = 2;
                }
            }
            File file = new File(jarName);
            ctClass.writeFile(file.getParent());
            disposeJar(jarName, file.getParent() + "/com/aspose/pdf/ADocument.class");
        } catch (NotFoundException e) {
            e.printStackTrace();
        } catch (CannotCompileException e) {
            e.printStackTrace();
        } catch (IOException e) {
            e.printStackTrace();
        }

    }

    private static void disposeJar(String jarName, String replaceFile) {
        List<String> deletes = new ArrayList<>();
        deletes.add("META-INF/37E3C32D.SF");
        deletes.add("META-INF/37E3C32D.RSA");
        File oriFile = new File(jarName);
        if (!oriFile.exists()) {
            System.out.println("######Not Find File:" + jarName);
            return;
        }
        //将文件名命名成备份文件
        String bakJarName = jarName.substring(0, jarName.length() - 3) + "cracked.jar";
        //   File bakFile=new File(bakJarName);
        try {
            //创建文件（根据备份文件并删除部分）
            JarFile jarFile = new JarFile(jarName);
            JarOutputStream jos = new JarOutputStream(new FileOutputStream(bakJarName));
            Enumeration entries = jarFile.entries();
            while (entries.hasMoreElements()) {
                JarEntry entry = (JarEntry) entries.nextElement();
                if (!deletes.contains(entry.getName())) {
                    if (entry.getName().equals("com/aspose/pdf/ADocument.class")) {
                        System.out.println("Replace:-------" + entry.getName());
                        JarEntry jarEntry = new JarEntry(entry.getName());
                        jos.putNextEntry(jarEntry);
                        FileInputStream fin = new FileInputStream(replaceFile);
                        byte[] bytes = readStream(fin);
                        jos.write(bytes, 0, bytes.length);
                    } else {
                        jos.putNextEntry(entry);
                        byte[] bytes = readStream(jarFile.getInputStream(entry));
                        jos.write(bytes, 0, bytes.length);
                    }
                } else {
                    System.out.println("Delete:-------" + entry.getName());
                }
            }
            jos.flush();
            jos.close();
            jarFile.close();
        } catch (FileNotFoundException e) {
            e.printStackTrace();
        } catch (IOException e) {
            e.printStackTrace();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private static byte[] readStream(InputStream inStream) throws Exception {
        ByteArrayOutputStream outSteam = new ByteArrayOutputStream();
        byte[] buffer = new byte[1024];
        int len = -1;
        while ((len = inStream.read(buffer)) != -1) {
            outSteam.write(buffer, 0, len);
        }
        outSteam.close();
        inStream.close();
        return outSteam.toByteArray();
    }
}
```

- 代码执行结束后，没报错的话，会在jar包的同级目录下生成一个带有`cracked` 的jar
- 用这个包替换原来的 jar包即可。
- POM引入：我的jar是放在 `resources/lib` 下面的。

```
<dependency>
            <groupId>com.aspose</groupId>
            <artifactId>aspose-pdf</artifactId>
            <version>22.7.1</version>
            <scope>system</scope>
            <systemPath>${project.basedir}/src/main/resources/lib/aspose-pdf-22.7.1.cracked.jar</systemPath>
        </dependency>
```

- 破解成功，然后就可以使用它的API了
- 文档地址：[https://docs.aspose.com/pdf/java/](https://docs.aspose.com/pdf/java/)
- 它的文档也算是挺详细的了，慢慢研究吧。