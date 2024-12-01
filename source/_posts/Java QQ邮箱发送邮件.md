---
title: Java QQ邮箱发送邮件
date: 2017-05-05 21:26:36
updated: 2017-05-05 21:26:36
tags: [干货, Java]
categories: Java
---
## 一、首先qq邮箱要开启POP3 /SMTP 服务
### 这个去QQ邮箱设置那里进行设置

<!--more-->

![](1494827219033085905.png)
## 二、获取授权码
### 看上图中的生成授权码，点击然后按它提示获取并保存
## 三、添加依赖
```
<!-- javamail -->
<dependency>
    <groupId>javax.mail</groupId>
    <artifactId>mail</artifactId>
    <version>1.4.7</version>
</dependency>
```
## 四、代码示例
```java
/**
  * 发送验证码
  * @param message 邮件的内容
  * @param title 邮件的标题
  * @param toAddress 接收人的邮箱地址
  */
 public void sendEmail(String message,String title,String toAddress){
	 Properties props = new Properties();
	 // 开启debug调试
	 props.setProperty("mail.debug", "false");
	 // 发送服务器需要身份验证
	 props.setProperty("mail.smtp.auth", "true");
	 // 设置邮件服务器主机名
	 props.setProperty("mail.host", "smtp.qq.com");
	 // 发送邮件协议名称
	 props.setProperty("mail.transport.protocol", "smtp");
	 MailSSLSocketFactory sf;
	 Transport transport =null;
	 try {
		 sf = new MailSSLSocketFactory();
		 sf.setTrustAllHosts(true);
		 props.put("mail.smtp.ssl.enable", "true");
		 props.put("mail.smtp.ssl.socketFactory", sf);
		 Session session = Session.getInstance(props);
		 Message msg = new MimeMessage(session);
		 msg.setSubject(title);
		 StringBuilder builder = new StringBuilder();
		 builder.append(message);
		 builder.append("\n\n 时间: " + DateUtil.getTime());
//              msg.setText(builder.toString());
		 msg.setFrom(new InternetAddress("你的邮箱地址"));
		 msg.setContent(builder.toString(), "text/html;charset=utf-8"); // 设置邮件格式  
		 transport = session.getTransport();
		 transport.connect("smtp.qq.com", "你的邮箱地址", "你的授权码");
		 transport.sendMessage(msg, new Address[] { new InternetAddress(toAddress)});//这里可以发送给多个人
	 } catch (GeneralSecurityException e) {
		 log.info("ssl 验证错误");
		 e.printStackTrace();
	 }catch (Exception e) {
		 log.info("程序异常", e);
	 }finally{
		 if(transport != null){
			 try {
				 transport.close();
			 } catch (MessagingException e) {
				 log.info("transport 关闭异常", e);
				 e.printStackTrace();
			 }
		 }
	 }
	 log.info("邮件发送成功!");
 }
```
