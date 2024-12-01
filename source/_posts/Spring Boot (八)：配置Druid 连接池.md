---
title: Spring Boot (八)：配置Druid 连接池
date: 2017-08-12 11:56:54
updated: 2017-08-12 11:56:54
tags: [Spring Boot]
categories: Java
---
# springboot 配置 Druid连接池

## 一、添加依赖
```
<!-- 驱动 -->
<dependency>
    <groupId>mysql</groupId>
    <artifactId>mysql-connector-java</artifactId>
    <scope>runtime</scope>
</dependency>
 
<!-- 连接池 -->
<dependency>
    <groupId>com.alibaba</groupId>
    <artifactId>druid</artifactId>
    <version>1.1.0</version>
</dependency>
```

<!--more-->

## 二、配置application.properties
```
spring.datasource.type = com.alibaba.druid.pool.DruidDataSource
spring.datasource.driverClassName = com.mysql.jdbc.Driver
spring.datasource.url = jdbc:mysql://localhost:3306/admin?useUnicode=true&characterEncoding=utf-8&useSSL=false
spring.datasource.username = username
spring.datasource.password = password
 
# 下面为连接池的补充设置，应用到上面所有数据源中
# 初始化大小，最小，最大
spring.druid.datasource.initialSize=5
spring.druid.datasource.minIdle=5
spring.druid.datasource.maxActive=20
# 配置获取连接等待超时的时间
spring.druid.datasource.maxWait=60000
# 配置间隔多久才进行一次检测，检测需要关闭的空闲连接，单位是毫秒
spring.druid.datasource.timeBetweenEvictionRunsMillis=60000
# 配置一个连接在池中最小生存的时间，单位是毫秒
spring.druid.datasource.minEvictableIdleTimeMillis=300000
# Oracle请使用select 1 from dual
spring.druid.datasource.validationQuery=SELECT 'x'
spring.druid.datasource.testWhileIdle=true
spring.druid.datasource.testOnBorrow=false
spring.druid.datasource.testOnReturn=false
# 打开PSCache，并且指定每个连接上PSCache的大小
spring.druid.datasource.poolPreparedStatements=false
spring.druid.datasource.maxPoolPreparedStatementPerConnectionSize=20
# 配置监控统计拦截的filters，去掉后监控界面sql无法统计，'wall'用于防火墙
spring.druid.datasource.filters=stat,wall,slf4j
# 通过connectProperties属性来打开mergeSql功能；慢SQL记录
spring.druid.datasource.connectionProperties=druid.stat.mergeSql=true;druid.stat.slowSqlMillis=5000
```

## 三、新建Druid 配置类
#### 在Spring Boot1.4.0中驱动配置信息没有问题，但是连接池的配置信息不再支持这里的配置项，即无法通过配置项直接支持相应的连接池；这里列出的这些配置项可以通过定制化DataSource来实现。目前Spring Boot中默认支持的连接池有dbcp,dbcp2, tomcat, hikari三种连接池。 由于Druid暂时不在Spring Bootz中的直接支持，故需要进行配置信息的定制：
```java
package com.greatdrive.admin.config;
 
 
import java.sql.SQLException;
 
import javax.sql.DataSource;
 
import org.apache.log4j.Logger;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.boot.web.servlet.FilterRegistrationBean;
import org.springframework.boot.web.servlet.ServletRegistrationBean;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Primary;
 
import com.alibaba.druid.pool.DruidDataSource;
import com.alibaba.druid.support.http.StatViewServlet;
import com.alibaba.druid.support.http.WebStatFilter;
 
@ConfigurationProperties(prefix = "spring.druid.datasource")
@Configuration
public class DruidDBConfig {  
    private Logger logger = Logger.getLogger(this.getClass());
       
    @Value("${spring.datasource.url}")  
    private String dbUrl;  
       
    @Value("${spring.datasource.username}")  
    private String username;  
       
    @Value("${spring.datasource.password}")  
    private String password;  
       
    @Value("${spring.datasource.driverClassName}")  
    private String driverClassName;  
       
    @Value("${spring.datasource.initialSize}")  
    private int initialSize;  
       
    @Value("${spring.datasource.minIdle}")  
    private int minIdle;  
       
    @Value("${spring.datasource.maxActive}")  
    private int maxActive;  
       
    @Value("${spring.datasource.maxWait}")  
    private long maxWait;  
       
    @Value("${spring.datasource.timeBetweenEvictionRunsMillis}")  
    private int timeBetweenEvictionRunsMillis;  
       
    @Value("${spring.datasource.minEvictableIdleTimeMillis}")  
    private int minEvictableIdleTimeMillis;  
       
    @Value("${spring.datasource.validationQuery}")  
    private String validationQuery;  
       
    @Value("${spring.datasource.testWhileIdle}")  
    private boolean testWhileIdle;  
       
    @Value("${spring.datasource.testOnBorrow}")  
    private boolean testOnBorrow;  
       
    @Value("${spring.datasource.testOnReturn}")  
    private boolean testOnReturn;  
       
    @Value("${spring.datasource.poolPreparedStatements}")  
    private boolean poolPreparedStatements;  
       
    @Value("${spring.datasource.maxPoolPreparedStatementPerConnectionSize}")  
    private int maxPoolPreparedStatementPerConnectionSize;  
       
    @Value("${spring.datasource.filters}")  
    private String filters;  
       
    @Value("{spring.datasource.connectionProperties}")  
    private String connectionProperties;  
       
    @Bean     //声明其为Bean实例  
    @Primary  //在同样的DataSource中，首先使用被标注的DataSource  
    public DataSource dataSource(){  
        DruidDataSource datasource = new DruidDataSource();  
           
        datasource.setUrl(this.dbUrl);  
        datasource.setUsername(username);  
        datasource.setPassword(password);  
        datasource.setDriverClassName(driverClassName);  
           
        //configuration  
        datasource.setInitialSize(initialSize);  
        datasource.setMinIdle(minIdle);  
        datasource.setMaxActive(maxActive);  
        datasource.setMaxWait(maxWait);  
        datasource.setTimeBetweenEvictionRunsMillis(timeBetweenEvictionRunsMillis);  
        datasource.setMinEvictableIdleTimeMillis(minEvictableIdleTimeMillis);  
        datasource.setValidationQuery(validationQuery);  
        datasource.setTestWhileIdle(testWhileIdle);  
        datasource.setTestOnBorrow(testOnBorrow);  
        datasource.setTestOnReturn(testOnReturn);  
        datasource.setPoolPreparedStatements(poolPreparedStatements);  
        datasource.setMaxPoolPreparedStatementPerConnectionSize(maxPoolPreparedStatementPerConnectionSize);  
        try {  
            datasource.setFilters(filters);  
        } catch (SQLException e) {  
            logger.error("druid configuration initialization filter", e);  
        }  
        datasource.setConnectionProperties(connectionProperties);  
           
        return datasource;  
    }  
     
    @Bean
    public ServletRegistrationBean druidServlet() {
        ServletRegistrationBean reg = new ServletRegistrationBean();
        reg.setServlet(new StatViewServlet());
        reg.addUrlMappings("/druid/*");
        reg.addInitParameter("allow", "127.0.0.1,192.168.1.83"); //白名单
        reg.addInitParameter("deny",""); //黑名单
        reg.addInitParameter("loginUsername", "admin");//查看监控的用户名
        reg.addInitParameter("loginPassword", "nimda");//密码
        return reg;
    }
 
    @Bean public FilterRegistrationBean filterRegistrationBean() {
        FilterRegistrationBean filterRegistrationBean = new FilterRegistrationBean();
        filterRegistrationBean.setFilter(new WebStatFilter());
        filterRegistrationBean.addUrlPatterns("/*");
        filterRegistrationBean.addInitParameter("exclusions", "*.js,*.gif,*.jpg,*.png,*.css,*.ico,/druid/*");
        return filterRegistrationBean;
    }
}
```

