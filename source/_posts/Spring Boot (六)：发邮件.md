---
title: Spring Boot (六)：发邮件
date: 2017-07-30 11:02:11
updated: 2017-07-30 11:02:11
tags: [Spring Boot, Java]
categories: Java
---
# Springboot  使用 JavaMailSender 发邮件
#### 发邮件功能，使用还是很普遍的，比如注册，找回密码，留言，推送......................我们来看看springboot 是怎么发邮件的。

## 1、添加依赖
```
<dependency> 
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-mail</artifactId>
</dependency>
```
## 2、配置邮件信息 application.properties
```
spring.mail.host=smtp.qq.com
spring.mail.username=1006059906@qq.com           //用户名
spring.mail.password=xxxxooooo                    //密码,QQ的授权码
//下面是安全认证，不加会报503错误
spring.mail.properties.mail.smtp.auth=true         
spring.mail.properties.mail.smtp.starttls.enable=true
spring.mail.properties.mail.smtp.starttls.required=true
spring.mail.default-encoding=UTF-8
```
> 这个如果在windows 一般都没什么问题，但在第三方运营商可能会有一个问题，就是 25 端口 被禁用。导致邮件发不了。
> 解决方案：换端口，具体可看 文章地址：/atc/show/11

## 3、代码示例
#### 实现类如下：
```java
package top.lrshuai.service.impl;
 
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.FileSystemResource;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Component;
 
import top.lrshuai.service.MailService;
 
import javax.mail.MessagingException;
import javax.mail.internet.MimeMessage;
import java.io.File;
 
@Component
public class MailServiceImpl implements MailService{
 
    private final Logger logger = LoggerFactory.getLogger(this.getClass());
 
    @Autowired
    private JavaMailSender mailSender;
 
    @Value("${fromMail}")
    private String from;
 
    /**
     * 发送文本邮件
     * @param to
     * @param subject
     * @param content
     */
    @Override
    public void sendSimpleMail(String to, String subject, String content) {
        SimpleMailMessage message = new SimpleMailMessage();
        message.setFrom(from);
        message.setTo(to);
        message.setSubject(subject);
        message.setText(content);
        try {
            mailSender.send(message);
            logger.info("简单邮件已经发送。");
        } catch (Exception e) {
            logger.error("发送简单邮件时发生异常！", e);
        }
 
    }
 
    /**
     * 发送html邮件
     * @param to
     * @param subject
     * @param content
     */
    @Override
    public void sendHtmlMail(String to, String subject, String content) {
        MimeMessage message = mailSender.createMimeMessage();
 
        try {
            //true表示需要创建一个multipart message
            MimeMessageHelper helper = new MimeMessageHelper(message, true);
            helper.setFrom(from);
            helper.setTo(to);
            helper.setSubject(subject);
            helper.setText(content, true);
 
            mailSender.send(message);
            logger.info("html邮件发送成功");
        } catch (MessagingException e) {
            logger.error("发送html邮件时发生异常！", e);
        }
    }
 
 
    /**
     * 发送带附件的邮件
     * @param to
     * @param subject
     * @param content
     * @param filePath
     */
    public void sendAttachmentsMail(String to, String subject, String content, String filePath){
        MimeMessage message = mailSender.createMimeMessage();
 
        try {
            MimeMessageHelper helper = new MimeMessageHelper(message, true);
            helper.setFrom(from);
            helper.setTo(to);
            helper.setSubject(subject);
            helper.setText(content, true);
 
            FileSystemResource file = new FileSystemResource(new File(filePath));
            String fileName = filePath.substring(filePath.lastIndexOf(File.separator));
            helper.addAttachment(fileName, file);
            mailSender.send(message);
            logger.info("带附件的邮件已经发送。");
        } catch (MessagingException e) {
            logger.error("发送带附件的邮件时发生异常！", e);
        }
    }
 
 
    /**
     * 发送正文中有静态资源（图片）的邮件
     * @param to
     * @param subject
     * @param content
     * @param rscPath
     * @param rscId
     */
    public void sendInlineResourceMail(String to, String subject, String content, String rscPath, String rscId){
        MimeMessage message = mailSender.createMimeMessage();
 
        try {
            MimeMessageHelper helper = new MimeMessageHelper(message, true);
            helper.setFrom(from);
            helper.setTo(to);
            helper.setSubject(subject);
            helper.setText(content, true);
            System.out.println("content="+content);
            System.out.println("rscId="+rscId);
            System.out.println("rscPath="+rscPath);
            FileSystemResource res = new FileSystemResource(new File(rscPath));
            helper.addInline(rscId, res);
            mailSender.send(message);
            logger.info("嵌入静态资源的邮件已经发送。");
        } catch (MessagingException e) {
            logger.error("发送嵌入静态资源的邮件时发生异常！", e);
        }
    }
}
```

#### 测试类
```java
package top.lrshuai.test;

import org.junit.Test;
import org.junit.runner.RunWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.junit4.SpringRunner;
import org.thymeleaf.TemplateEngine;
import org.thymeleaf.context.Context;

import top.lrshuai.service.MailService;

/**
 * 
 * @author tyro
 *
 */
@RunWith(SpringRunner.class)
@SpringBootTest
public class MailServiceTest {

    @Autowired
    private MailService mailService;

    @Autowired
    private TemplateEngine templateEngine;

    @Test
    public void testSimpleMail() throws Exception {
        mailService.sendSimpleMail("1071426959@qq.com","test simple mail"," hello this is simple mail");
    }

    @Test
    public void testHtmlMail() throws Exception {
        String content="<html>\n" +
                "<body>\n" +
                "    <h3>hello world ! 这是一封html邮件!</h3>\n" +
                "</body>\n" +
                "</html>";
        mailService.sendHtmlMail("1071426959@qq.com","test simple mail",content);
    }

    @Test
    public void sendAttachmentsMail() {
        String filePath="E:\\lrs\\github\\SSM\\README.txt";
        mailService.sendAttachmentsMail("1071426959@qq.com", "主题：带附件的邮件", "有附件，请查收！", filePath);
    }


    @Test
    public void sendInlineResourceMail() {
        String rscId ="id001";
        String content="<html><body>这是有图片的邮件：<img src=\"cid:" + rscId + "\" ></body></html>";
        String imgPath = "E:\\lrs\\pic\\logo.jpg";

        mailService.sendInlineResourceMail("1071426959@qq.com", "主题：这是有图片的邮件", content, imgPath, rscId);
    }


    @Test
    public void sendTemplateMail() {
        //创建邮件正文
        Context context = new Context();
        context.setVariable("id", "168");
        String emailContent = templateEngine.process("emailTemplate", context);

        mailService.sendHtmlMail("1071426959@qq.com","主题：这是模板邮件",emailContent);
    }
}

```

> Github 地址： https://github.com/rstyro/spring-boot
