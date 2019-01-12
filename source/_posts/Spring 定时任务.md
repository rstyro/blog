---
title: Spring 定时任务
date: 2017-07-06 16:31:30
tags: [Spring Boot, Spring]
categories: Java
---
# Spring 或springboot 定时任务

## 1、demo 代码示例
```
package top.lrshuai.task;
 
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
 
@Component
public class TimeTask{
    @Scheduled(cron = "0 0 0 ? * MON")  
    public void timeTask() {  
        System.out.println("定时任务");  
    }  
}
```
> cron：指定cron表达式。我上面写的是每周一0点执行

## 2、配置问题

### (1)、spring 配置
> 配置文件的代码片段,主要是添加最下面两行

```
<beans xmlns="http://www.springframework.org/schema/beans" 
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xmlns:context="http://www.springframework.org/schema/context" 
  xmlns:p="http://www.springframework.org/schema/p"
  xmlns:aop="http://www.springframework.org/schema/aop" 
  xmlns:tx="http://www.springframework.org/schema/tx"
  xmlns:task="http://www.springframework.org/schema/task" 
  xsi:schemaLocation="http://www.springframework.org/schema/beans   
    http://www.springframework.org/schema/beans/spring-beans.xsd 
    http://www.springframework.org/schema/tx 
    http://www.springframework.org/schema/tx/spring-tx.xsd
    http://www.springframework.org/schema/aop 
    http://www.springframework.org/schema/aop/spring-aop.xsd 
    http://www.springframework.org/schema/task http://www.springframework.org/schema/task/spring-task-3.0.xsd
    http://www.springframework.org/schema/context  
    http://www.springframework.org/schema/context/spring-context.xsd">
 
 
    <context:annotation-config/>
    <context:component-scan base-package="top.rstyro"/>
 
    <!-- 定时任务配置 -->
    <task:annotation-driven scheduler="qbScheduler" mode="proxy" />
    <task:scheduler id="qbScheduler" pool-size="10" />
```
### (2)、springboot
#### 这个比较简单，在Spring Boot的主类中加入`@ EnableScheduling`注解，启用定时任务的配置
```
@SpringBootApplication
@MapperScan("top.lrshuai.blog.dao")
@EnableScheduling
public class Application {

	public static void main(String[] args) {
		SpringApplication.run(Application.class, args);
	}
}
```

## 3、参数解析
#### 关于cronExpression的介绍:　

> 字段 允许值 允许的特殊字符
> 秒 0-59 , - /
> 分 0-59 , - /
> 小时 0-23 , - /
> 日期 1-31 , - ? / L W C
> 月份 1-12 或者 JAN-DEC , - /
> 星期 1-7 或者 SUN-SAT , - ? / L C #
> 年（可选） 留空, 1970-2099 , - * /

#### 表达式意义
|表达式|含义|
|---|---|
|`0 0 12 * * ?`| 每天中午12点触发 |
|`0 15 10 ? * *`| 每天上午10:15触发 |
|`0 15 10 * * ?`| 每天上午10:15触发 |
|`0 15 10 * * ? *`| 每天上午10:15触发 |
|`0 15 10 * * ? 2005`| 2005年的每天上午10:15触发| 
|`0 * 14 * * ?` |在每天下午2点到下午2:59期间的每1分钟触发 |
|`0 0/5 14 * * ?`| 在每天下午2点到下午2:55期间的每5分钟触发 |
|`0 0/5 14,18 * * ?`| 在每天下午2点到2:55期间和下午6点到6:55期间的每5分钟触发 |
|`0 0-5 14 * * ?` |在每天下午2点到下午2:05期间的每1分钟触发 |
|`0 10,44 14 ? 3 WED`| 每年三月的星期三的下午2:10和2:44触发 |
|`0 15 10 ? * MON-FRI`| 周一至周五的上午10:15触发 |
|`0 15 10 15 * ?` |每月15日上午10:15触发 |
|`0 15 10 L * ?` |每月最后一日的上午10:15触发 |
|`0 15 10 ? * 6L`| 每月的最后一个星期五上午10:15触发 |
|`0 15 10 ? * 6L 2002-2005`|2002年至2005年的每月的最后一个星期五上午10:15触发 |
|`0 15 10 ? * 6#3`| 每月的第三个星期五上午10:15触发 |
|`0 6 * * * `| 每天早上6点 |
|`0 */2 * * * `| 每两个小时 |
|`0 0/5 * * * ?`|每5分钟|
|`0 23-7/2，8 * * *` | 晚上11点到早上8点之间每两个小时，早上八点|  
|`0 11 4 * 1-3` |每个月的4号和每个礼拜的礼拜一到礼拜三的早上11点|
|`0 4 1 1 *`| 1月1日早上4点 |

