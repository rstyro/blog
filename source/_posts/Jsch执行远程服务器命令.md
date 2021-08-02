---
title: Jsch执行远程服务器命令
date: 2021-08-01 18:46:03
updated: 2021-08-01 18:46:03
tags: [Jsch,Shell]
categories: Java
---

### 一、Java-SSH连接执行远程服务命令
### 一、前言
+ 刚好，项目需要调用远程服务器的命令，所以研究一波
+ 目前，Java执行远程命令的第三方包常用的有：jsch、ganymed-ssh2、
+ 本文的例子是 jsch

### 二、导入依赖
+ 导入jsch的依赖，最近的更新时间是2018年：`0.1.55` 版本
+ 可能是因为Java 执行第三方的需求比较少吧，所以市面上可使用的Jar很少

```
<dependency>
    <groupId>com.jcraft</groupId>
    <artifactId>jsch</artifactId>
    <version>0.1.55</version>
</dependency>
```

+ 访问官方文档例子：[http://www.jcraft.com/jsch/examples/](http://www.jcraft.com/jsch/examples/)
+ 

### 三、快速开始
+ 简单例子来一波

#### 1、shell登录
+ 可直接通过Java控制台与远程服务器shell命令交互
+ 简单代码如下：

```
public class Demo {
    public static void main(String[] args) throws JSchException {
        //远程服务用户名
        String username = "root";
        // 远程服务ip
        String host = "192.168.2.25";
        // 远程服务密码
        String password = "root";
        // 连接超时 10秒
        int timeout = 10000;
        int port = 22;
        JSch jSch = new JSch();
        Session session = jSch.getSession(username, host, port);
        // 设置密码
        session.setPassword(password);

        Properties config = new Properties();
        // 设置第一次登录的时候提示，可选值：(ask | yes | no)
        config.put("StrictHostKeyChecking", "no");
        // 为Session对象设置properties
        session.setConfig(config);
        // 设置连接超时
        session.setTimeout(timeout);
        // 通过Session建立连接
        session.connect();
        // 打开shell通道
        Channel shell = session.openChannel("shell");
        // 控制台接收输入
        shell.setInputStream(System.in);
        // 控制台接收输出
        shell.setOutputStream(System.out);
        // 超时时间，0 表示无限制
        shell.connect(3*1000);
    }
}
```
+ 执行，不出问题即可看到控制台已连接到服务端了，执行linux命令了

![](shell.png)

+ 如上是控制台交互的，如果要直接执行命令，java接收呢？如下

#### 2、执行远程Linux命令
+ 和上面一样，也是创建一个session，然后通过session,打开一个命令通道即可。
+ 例子如下：

```
public class Demo {
    public static void main(String[] args) throws JSchException {
        String username = "root";
        String host = "192.168.2.25";
        String password = "root";
        int timeout = 10000;
        int port = 22;
        JSch jSch = new JSch();
        Session session = jSch.getSession(username, host, port);
        session.setPassword(password);
        Properties config = new Properties();
        config.put("StrictHostKeyChecking", "no");
        session.setConfig(config);
        session.setTimeout(timeout);
        session.connect();
        // 打印root目录下的信息
        String cmd = "ls -l /root";
        List<String> result = exec(session, cmd);
        if(!ObjectUtils.isEmpty(result)){
            result.forEach(i->{
                System.out.println(i);
            });
        }
    }


    /**
     * 执行命令
     * @param command 命令
     * @return list
     * @throws JSchException err
     */
    public static  List<String> exec(Session session,String command) throws JSchException {
        List<String> resultLines = new ArrayList<>();
        ChannelExec channel = null;
        try{
            channel = (ChannelExec) session.openChannel("exec");
            channel.setCommand(command);
            channel.setInputStream(null);
            channel.setErrStream(System.err);
            channel.connect(10000);
            InputStream input = channel.getInputStream();
            try {
                BufferedReader inputReader = new BufferedReader(new InputStreamReader(input));
                String inputLine = null;
                while((inputLine = inputReader.readLine()) != null) {
                    resultLines.add(inputLine);
                }
            } finally {
                if (input != null) {
                    try {
                        input.close();
                    } catch (Exception e) {
                        // todo...
                        e.printStackTrace();
                    }
                }
            }
        } catch (IOException e) {
        } finally {
            if (channel != null) {
                try {
                    channel.disconnect();
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }
        }
        return resultLines;
    }
}
```

+ session的获取和第一个一样，也就是说，后期可以做封装方便调用 
+ 使用：`session.openChannel("exec")` 打开一个命令通道，然后接收命令返回即可
+ 结果如下图：

![](exec.png)

#### 3、文件上传下载
+ 除了调用命令，文件的上传下载也是常用的功能
+ jsch 里面的ChannelSftp实现了SFTP核心类，它包含了所有SFTP的方法，如：
+ `put()：`      文件上传
+ `get()：`      文件下载
+ `cd()：`     进入指定目录
+ `ls()：`       得到指定目录下的文件列表
+ `rename()：`   重命名指定文件或目录
+ `rm()：`       删除指定文件
+ `mkdir()：`    创建目录
+ `rmdir()：`    删除目录
等等（这里省略了方法的参数，put和get都有多个重载方法，具体请看源代码：`com.jcraft.jsch.ChannelSftp`

**Jsch支持三种文件传输模式：**

```java
// 完全覆盖模式，这是JSch的默认文件传输模式，即如果目标文件已经存在，传输的文件将完全覆盖目标文件，产生新的文件
 public static final int OVERWRITE=0;
 
 // 恢复模式，如果文件已经传输一部分，这时由于网络或其他任何原因导致文件传输中断，如果下一次传输相同的文件，则会从上一次中断的地方续传。
 public static final int RESUME=1;
 
 // 追加模式，如果目标文件已存在，传输的文件将在目标文件后追加。
 public static final int APPEND=2;
```

##### ①、文件上传
+ 使用的是`put()` 方法，所有重载方法，最终都会调用的方法如下：

```
public void put(String src, String dst,SftpProgressMonitor monitor, int mode) throws SftpException{
	// ...
}
```

+ 参数解释：
+ 第一个参数：src，将本地文件名为src的文件上传到目标服务器
+ 第二个参数：dst,目标文件名为dst，若dst为目录，则目标文件名将与src文件名相同
+ 第三个参数：monitor，monitor对象来监控文件传输的进度。
+ 第四个参数：mode,文件的传输方式，采用默认的传输模式：`OVERWRITE`

*还是之前的Demo,如下：*

```java
public class Demo {
    public static void main(String[] args) throws JSchException {
        String username = "root";
        String host = "192.168.2.25";
        String password = "root";
        int timeout = 10000;
        int port = 22;
        JSch jSch = new JSch();
        Session session = jSch.getSession(username, host, port);
        // 设置密码
        session.setPassword(password);

        Properties config = new Properties();
        config.put("StrictHostKeyChecking", "no");
        // 为Session对象设置properties
        session.setConfig(config);
        // 设置连接超时
        session.setTimeout(timeout);
        // 通过Session建立连接
        session.connect();
        // 本地文件
        String src="C:\\MyHome\\md\\jvm.txt";
        // 上传到远程的路径
        String target="/root/jvm.txt";
        // 上传本地文件到服务器
        uploadFile(session,src,target);
    }


    public static boolean uploadFile(Session session,String src,String target){
        try{
            // 打开channelSftp
            ChannelSftp channelSftp = (ChannelSftp) 			session.openChannel("sftp");
            // 远程连接
            channelSftp.connect();
            // 创建一个文件名称问uploadFile的文件
            File file = new File(src);
            // 采用默认的传输模式:OVERWRITE
            channelSftp.put(new FileInputStream(file), target,null, ChannelSftp.OVERWRITE);
            System.out.println("上传成功");
            // 切断远程连接
            channelSftp.exit();
        }catch (Exception e){
            e.printStackTrace();
            return false;
        }

        return true;
    }
}
```

+ 上面的例子是没有监控文件的上传进度，那如果要使用怎么办，如下
+ 实现`SftpProgressMonitor` 接口，重写其方法即可，代码里面有注释

```
/**
 * 自定义sftp上传监控
 */
public class MySftpProgressMonitor implements SftpProgressMonitor {

    private long transfered;

    /**
     * 当文件开始传输时，调用init方法。
     * @param op
     * @param src
     * @param dest
     * @param max
     */
    @Override
    public void init(int op, String src, String dest, long max) {
        System.out.println("这里可以做一些初始化操作");
    }

    /**
     * 当每次传输了一个数据块后，调用count方法，count方法的参数为这一次传输的数据块大小
     * @param count
     * @return
     */
    @Override
    public boolean count(long count) {
        transfered+=count;
        System.out.println("当前已传输："+transfered);
        return true;
    }

    /**
     * 当传输结束时，调用end方法
     */
    @Override
    public void end() {
        System.out.println("传输完成");
    }
}
```
+ 比较粗略，可以自己实现符合业务需求的结果如下：

![](upload.png)


##### ②、文件下载
+ 其实文件下载和文件上传类似，如下

```
public static boolean download(Session session,String src,String target){
        try{
            // 打开channelSftp
            ChannelSftp channelSftp = (ChannelSftp) session.openChannel("sftp");
            // 远程连接
            channelSftp.connect();
            // 创建一个文件名称问uploadFile的文件
            File file = new File(src);
            channelSftp.get(src,target,new MySftpProgressMonitor(),ChannelSftp.OVERWRITE);
            System.out.println("下载成功");
            // 切断远程连接
            channelSftp.exit();
        }catch (Exception e){
            e.printStackTrace();
            return false;
        }

        return true;
    }
```

+ 方法和文件上传一样，只是参数刚好交换而已

```
public static void main(String[] args) throws JSchException {
        String username = "root";
        String host = "192.168.2.25";
        String password = "root";
        int timeout = 10000;
        int port = 22;
        JSch jSch = new JSch();
        Session session = jSch.getSession(username, host, port);
        // 设置密码
        session.setPassword(password);

        Properties config = new Properties();
        config.put("StrictHostKeyChecking", "no");
        // 为Session对象设置properties
        session.setConfig(config);
        // 设置连接超时
        session.setTimeout(timeout);
        // 通过Session建立连接
        session.connect();
        // 要下载的远程服务器文件
        String src="/root/test.pdf";
        // 保存到哪里
        String target="C:\\MyHome\\test2.pdf";
        download(session,src,target);
    }
```

+ 如果是网页下载的话，直接传一个`response.getOutputStream()`过去就可以了,如下：

```
public static boolean download(Session session,String src,OutputStream out){
        try{
            // 打开channelSftp
            ChannelSftp channelSftp = (ChannelSftp) session.openChannel("sftp");
            // 远程连接
            channelSftp.connect();
            // 创建一个文件名称问uploadFile的文件
            File file = new File(src);
            channelSftp.get(src,out,new MySftpProgressMonitor(),ChannelSftp.OVERWRITE,0);
            System.out.println("下载成功");
            // 切断远程连接
            channelSftp.exit();
        }catch (Exception e){
            e.printStackTrace();
            return false;
        }

        return true;
    }
```

#### 4、跳板机
+ 可以通过Session的`setPortForwardingL()` 方法进行转发，但是我这边运行失败
+ 不知道是不是需要在linux执行才能成功，我是windows IDEA运行的，以后再研究一下。代码如下：

```java
public static void main(String[] args) throws Throwable {
        String username = "root";
        // 跳板机ip
        String host = "192.168.2.25";
        String password = "root";
        int timeout = 10000;
        int port = 22;
        JSch jSch = new JSch();
        Session session = jSch.getSession(username, host, port);
        session.setPassword(password);
        Properties config = new Properties();
        config.put("StrictHostKeyChecking", "no");
        session.setConfig(config);
        session.setTimeout(timeout);
        session.connect();//THIS WORKS

		// 跳板机访问的目标ip
        String targetHost = "192.168.2.189";
        int targetPort = 22;
        // 转发端口
        int forwardPort=18008;
        // 设置转发
        int assetPort = session.setPortForwardingL("127.0.0.1", forwardPort, targetHost, targetPort); //FAILS HERE!!
//        int assetPort = session.setPortForwardingL(host, forwardPort, targetHost, targetPort); //FAILS HERE!!
        Session targetSession = jSch.getSession(username, host, assetPort);
        targetSession.setPassword(password);
        Properties targetConfig = new Properties();
        targetConfig.put("StrictHostKeyChecking", "no");
        targetSession.setConfig(targetConfig);
        targetSession.connect();
        System.out.println("success");
        Channel shell = targetSession.openChannel("shell");
        shell.setInputStream(System.in);
        shell.setOutputStream(System.out);
        shell.connect(3*1000);

    }
```

+ 代码很简单，不知道哪里出问题了，`setPortForwardingL()` 的`bind_address`参数
+ 能设置的都设置了，还是报错。服务器的防火墙什么的都关了。都能相互ping通。



+ 参考链接：
+ [http://www.jcraft.com/jsch/examples/](http://www.jcraft.com/jsch/examples/)
+ [https://www.cnblogs.com/longyg/archive/2012/06/25/2556576.html](https://www.cnblogs.com/longyg/archive/2012/06/25/2556576.html)
