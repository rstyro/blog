---
title: Spring+mybatis 配置多个数据源
date: 2017-05-01 21:19:07
tags: [Spring, Java]
categories: Java
---
# 这个是spring+springmvc+mybatis框架的方法
## 一、编辑配置文件：spring-mybatis.xml
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
    http://www.springframework.org/schema/task http://www.springframework.org/schema/task/spring-task.xsd
    http://www.springframework.org/schema/context  
    http://www.springframework.org/schema/context/spring-context.xsd">
 
      
    <context:annotation-config/>
    <context:component-scan base-package="com.lrs.test"/>
     
    <context:property-placeholder location="classpath:config-*.properties" />
     
    <!-- 定时任务配置 -->
        <task:annotation-driven scheduler="qbScheduler" mode="proxy" />
        <task:scheduler id="qbScheduler" pool-size="10" />
     
    <!--统一的dataSource-->
    <bean id="dynamicDataSource" class="com.lrs.test.source.DynamicDataSource" >
        <property name="targetDataSources">
            <map key-type="java.lang.String">
                <!--通过不同的key决定用哪个dataSource-->
                <entry value-ref="dataSourceA" key="dataSourceA"></entry>
                <entry value-ref="dataSourceB" key="dataSourceB"></entry>
            </map>
        </property>
        <!--设置默认的dataSource-->
        <property name="defaultTargetDataSource" ref="dataSourceA">
        </property>
    </bean>
     
     
    <!-- 数据源A -->
    <bean id="dataSourceA" class="com.alibaba.druid.pool.DruidDataSource" init-method="init" destroy-method="close">  
        <!-- 基本属性 url、user、password --> 
        <property name="url" value="${jdbc.url.A}" /> 
        <property name="username" value="${jdbc.username}" /> 
        <property name="password" value="${jdbc.password}" /> 
        <!-- 配置初始化大小、最小、最大 --> 
        <property name="initialSize" value="1" /> 
        <property name="minIdle" value="1" />  
        <property name="maxActive" value="20" /> 
        <!-- 配置获取连接等待超时的时间 --> 
        <property name="maxWait" value="60000" /> 
        <!-- 配置间隔多久才进行一次检测，检测需要关闭的空闲连接，单位是毫秒 --> 
        <property name="timeBetweenEvictionRunsMillis" value="60000" /> 
        <!-- 配置一个连接在池中最小生存的时间，单位是毫秒 --> 
        <property name="minEvictableIdleTimeMillis" value="300000" /> 
        <property name="validationQuery" value="SELECT 'x'" /> 
        <property name="testWhileIdle" value="true" /> 
        <property name="testOnBorrow" value="false" /> 
        <property name="testOnReturn" value="false" /> 
        <!-- 打开PSCache，并且指定每个连接上PSCache的大小 --> 
        <property name="poolPreparedStatements" value="true" /> 
        <property name="maxPoolPreparedStatementPerConnectionSize" value="20" /> 
        <!-- 配置监控统计拦截的filters，去掉后监控界面sql无法统计 --> 
        <property name="filters" value="stat" />  
    </bean>
     
     
    <!-- 数据源B -->
    <bean id="dataSourceB" class="com.alibaba.druid.pool.DruidDataSource" init-method="init" destroy-method="close">  
        <!-- 基本属性 url、user、password --> 
        <property name="url" value="${jdbc.url.B}" /> 
        <property name="username" value="${jdbc.username}" /> 
        <property name="password" value="${jdbc.password}" /> 
        <!-- 配置初始化大小、最小、最大 --> 
        <property name="initialSize" value="1" /> 
        <property name="minIdle" value="1" />  
        <property name="maxActive" value="20" /> 
        <!-- 配置获取连接等待超时的时间 --> 
        <property name="maxWait" value="60000" /> 
        <!-- 配置间隔多久才进行一次检测，检测需要关闭的空闲连接，单位是毫秒 --> 
        <property name="timeBetweenEvictionRunsMillis" value="60000" /> 
        <!-- 配置一个连接在池中最小生存的时间，单位是毫秒 --> 
        <property name="minEvictableIdleTimeMillis" value="300000" /> 
        <property name="validationQuery" value="SELECT 'x'" /> 
        <property name="testWhileIdle" value="true" /> 
        <property name="testOnBorrow" value="false" /> 
        <property name="testOnReturn" value="false" /> 
        <!-- 打开PSCache，并且指定每个连接上PSCache的大小 --> 
        <property name="poolPreparedStatements" value="true" /> 
        <property name="maxPoolPreparedStatementPerConnectionSize" value="20" /> 
        <!-- 配置监控统计拦截的filters，去掉后监控界面sql无法统计 --> 
        <property name="filters" value="stat" />  
    </bean>
     
    <!-- DAO接口所在包名，Spring会自动查找其下的类 -->
        <bean class="org.mybatis.spring.mapper.MapperScannerConfigurer">
            <property name="basePackage" value="com.lrs.test.dao" />
            <property name="sqlSessionFactoryBeanName" value="sqlSessionFactory"></property>
        </bean>
     
    <!-- sqlSessionFactory -->
    <bean id="sqlSessionFactory" class="org.mybatis.spring.SqlSessionFactoryBean">
        <!-- 数据库连接池 -->
        <property name="dataSource" ref="dynamicDataSource" />
        <!-- 加载mybatis的全局配置文件 -->
        <property name="configLocation" value="classpath:mybatis/mybatis-config.xml" />
        <!-- mapper扫描 -->
        <property name="mapperLocations" value="classpath:mapper/*.xml"></property>
    </bean>
     
    <!-- 通过Spring进行事务的管理，我们需要增加Spring注解的事务管理机制 -->
    <bean id="transactionManager" class="org.springframework.jdbc.datasource.DataSourceTransactionManager">
         <property name="dataSource" ref="dynamicDataSource" />
    </bean>     
     
    <!-- 通知 -->
    <tx:advice id="txAdvice" transaction-manager="transactionManager">
        <tx:attributes>
            <!-- 传播行为 -->
            <tx:method name="save*" propagation="REQUIRED" />
            <tx:method name="delete*" propagation="REQUIRED" />
            <tx:method name="insert*" propagation="REQUIRED" />
            <tx:method name="update*" propagation="REQUIRED" />
            <tx:method name="find*" propagation="SUPPORTS" read-only="true" />
            <tx:method name="get*" propagation="SUPPORTS" read-only="true" />
            <tx:method name="select*" propagation="SUPPORTS" read-only="true" />
        </tx:attributes>
    </tx:advice>
     
    <!-- 配置事务切面
     --> 
    <aop:config proxy-target-class="true">
        <aop:pointcut id="serviceOperation" expression="execution(* com.lrs.test.service..*.*(..))" />
        <aop:advisor advice-ref="txAdvice" pointcut-ref="serviceOperation" />
    </aop:config>
     
</beans>
```

## 二、解决线程安全问题
### 利用ThreadLocal,设置当前线程使用的是哪个dataSource
```
public class CustomerContextHolder {
     
        public static final String DATA_SOURCE_A = "dataSourceA";  
        public static final String DATA_SOURCE_B = "dataSourceB";  
         
        private static final ThreadLocal<String> contextHolder = new ThreadLocal<String>();  
         
        public static void setCustomerType(String customerType) {
            contextHolder.set(customerType);
        }
        public static String getCustomerType() {
            String dataSource = contextHolder.get();
            if (StringUtils.isEmpty(dataSource)) {
                return DATA_SOURCE_A;
            }else {
                return dataSource;
            }
        }
        public static void clearCustomerType() {
            contextHolder.remove();
        }
             
}
```
## 三、自定义一个动态数据源
#### 创建DynamicDataSource类继承AbstractRoutingDataSource
#### 并实现determineCurrentLookupKey方法
```
public class DynamicDataSource extends AbstractRoutingDataSource {
 
    @Override
    protected Object determineCurrentLookupKey() {
        return CustomerContextHolder.getCustomerType();
    }
 
}
```
## 四、service 层实现数据切换
```
CustomerContextHolder.setCustomerType(CustomerContextHolder.DATA_SOURCE_B);
```