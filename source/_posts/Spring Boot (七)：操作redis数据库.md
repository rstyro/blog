---
title: Spring Boot (七)：操作redis数据库
date: 2017-07-31 11:20:44
tags: [Spring Boot, Redis]
categories: Java
---
# springboot 使用redis 缓存

## 1、引入依赖
```
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-data-redis</artifactId>
</dependency>
```

## 2、添加 redis 的配置文件
##### 在application.properties
```
# Redis数据库索引（默认为0）
spring.redis.database=0
# Redis服务器地址
spring.redis.host=localhost
# Redis服务器连接端口
spring.redis.port=6379
# Redis服务器连接密码（默认为空）
spring.redis.password=
# 连接池最大连接数（使用负值表示没有限制）
spring.redis.pool.max-active=8
# 连接池最大阻塞等待时间（使用负值表示没有限制）
spring.redis.pool.max-wait=-1
# 连接池中的最大空闲连接
spring.redis.pool.max-idle=8
# 连接池中的最小空闲连接
spring.redis.pool.min-idle=0
# 连接超时时间（毫秒）
spring.redis.timeout=0
```
## 3、添加配置类
#### (1)、自定义一个配置类
> @Value 是从配置文件引入值

```
package top.lrshuai.config;
 
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.redis.connection.RedisConnectionFactory;
import org.springframework.data.redis.connection.jedis.JedisConnectionFactory;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.data.redis.serializer.*;
 
import redis.clients.jedis.JedisPoolConfig;
 
/**
 * 
 * @author tyro
 * @time 2017-07-31
 *
 */
@Configuration
public class RedisConfig {
     
    @Value("${spring.redis.database}")
    private int database;
     
    @Value("${spring.redis.host}")
    private String host;
     
    @Value("${spring.redis.port}")
    private int port;
     
    @Value("${spring.redis.timeout}")
    private int timeout;
     
    @Value("${spring.redis.pool.max-idle}")
    private int maxidle;
     
    @Value("${spring.redis.pool.min-idle}")
    private int minidle;
     
    @Value("${spring.redis.pool.max-active}")
    private int maxActive;
     
    @Value("${spring.redis.pool.max-wait}")
    private long maxWait;
     
    @Bean
    JedisConnectionFactory jedisConnectionFactory() {
        JedisPoolConfig config = new JedisPoolConfig(); 
//      最大空闲连接数, 默认8个
        config.setMaxIdle(maxidle);
//      最小空闲连接数, 默认0
        config.setMinIdle(minidle);
//      最大连接数, 默认8个
        config.setMaxTotal(maxActive);
//      获取连接时的最大等待毫秒数(如果设置为阻塞时BlockWhenExhausted),如果超时就抛异常, 小于零:阻塞不确定的时间,  默认-1
        config.setMaxWaitMillis(maxWait);
         
        JedisConnectionFactory factory = new JedisConnectionFactory();
        factory.setDatabase(database);
        factory.setHostName(host);
        factory.setPort(port);
        factory.setTimeout(timeout);
        factory.setPoolConfig(config);
        return factory;
    }
 
    @SuppressWarnings({ "unchecked", "rawtypes" })
    @Bean
    public RedisTemplate<String, ?> redisTemplate(RedisConnectionFactory factory) {
        RedisTemplate<String, ?> template = new RedisTemplate();
        template.setConnectionFactory(factory);
        template.setKeySerializer(new StringRedisSerializer());
        template.setValueSerializer(new RedisObjectSerializer());
        return template;
    }
 
 
}
```

##### JedisPoolConfig 的参数详情如下：
```
JedisPoolConfig config = new JedisPoolConfig();
  
//连接耗尽时是否阻塞, false报异常,ture阻塞直到超时, 默认true
config.setBlockWhenExhausted(true);
  
//设置的逐出策略类名, 默认DefaultEvictionPolicy(当连接超过最大空闲时间,或连接数超过最大空闲连接数)
config.setEvictionPolicyClassName("org.apache.commons.pool2.impl.DefaultEvictionPolicy");
  
//是否启用pool的jmx管理功能, 默认true
config.setJmxEnabled(true);
  
//MBean ObjectName = new ObjectName("org.apache.commons.pool2:type=GenericObjectPool,name=" + "pool" + i); 默 认为"pool", JMX不熟,具体不知道是干啥的...默认就好.
config.setJmxNamePrefix("pool");
  
//是否启用后进先出, 默认true
config.setLifo(true);
  
//最大空闲连接数, 默认8个
config.setMaxIdle(8);
  
//最大连接数, 默认8个
config.setMaxTotal(8);
  
//获取连接时的最大等待毫秒数(如果设置为阻塞时BlockWhenExhausted),如果超时就抛异常, 小于零:阻塞不确定的时间,  默认-1
config.setMaxWaitMillis(-1);
  
//逐出连接的最小空闲时间 默认1800000毫秒(30分钟)
config.setMinEvictableIdleTimeMillis(1800000);
  
//最小空闲连接数, 默认0
config.setMinIdle(0);
  
//每次逐出检查时 逐出的最大数目 如果为负数就是 : 1/abs(n), 默认3
config.setNumTestsPerEvictionRun(3);
  
//对象空闲多久后逐出, 当空闲时间>该值 且 空闲连接>最大空闲数 时直接逐出,不再根据MinEvictableIdleTimeMillis判断  (默认逐出策略)   
config.setSoftMinEvictableIdleTimeMillis(1800000);
  
//在获取连接的时候检查有效性, 默认false
config.setTestOnBorrow(false);
  
//在空闲时检查有效性, 默认false
config.setTestWhileIdle(false);
  
//逐出扫描的时间间隔(毫秒) 如果为负数,则不运行逐出线程, 默认-1
config.setTimeBetweenEvictionRunsMillis(-1);
```
#### (2)、为了能让redis 存储对象，我们要实现对象的序列化接口
```
package top.lrshuai.config;
 
import org.springframework.core.convert.converter.Converter;
import org.springframework.core.serializer.support.DeserializingConverter;
import org.springframework.core.serializer.support.SerializingConverter;
import org.springframework.data.redis.serializer.RedisSerializer;
import org.springframework.data.redis.serializer.SerializationException;
 
public class RedisObjectSerializer implements RedisSerializer<Object> {
 
  private Converter<Object, byte[]> serializer = new SerializingConverter();
  private Converter<byte[], Object> deserializer = new DeserializingConverter();
 
  static final byte[] EMPTY_ARRAY = new byte[0];
 
  public Object deserialize(byte[] bytes) {
    if (isEmpty(bytes)) {
      return null;
    }
 
    try {
      return deserializer.convert(bytes);
    } catch (Exception ex) {
      throw new SerializationException("Cannot deserialize", ex);
    }
  }
 
  public byte[] serialize(Object object) {
    if (object == null) {
      return EMPTY_ARRAY;
    }
 
    try {
      return serializer.convert(object);
    } catch (Exception ex) {
      return EMPTY_ARRAY;
    }
  }
 
  private boolean isEmpty(byte[] data) {
    return (data == null || data.length == 0);
  }
}
```

## 四、代码示例
#####  测试类如下：
```
package top.lrshuai;
 
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
 
import org.junit.Assert;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.test.context.junit4.SpringRunner;
 
import top.lrshuai.entity.User;
 
 
@RunWith(SpringRunner.class)
@SpringBootTest
public class SpringbootRedisApplicationTests {
 
    @Autowired
    private StringRedisTemplate stringRedisTemplate;
 
    @Autowired
    private RedisTemplate<String, User> redisTemplate;
     
    @Autowired
    private RedisTemplate<String, List<User>> rt;
     
     
    @Autowired
    private RedisTemplate<String, List<Map<String,Object>>> rm;
 
    @Test
    public void test() throws Exception {
 
        // 保存字符串
        stringRedisTemplate.opsForValue().set("url", "www.lrshuai.top");
        Assert.assertEquals("www.lrshuai.top", stringRedisTemplate.opsForValue().get("url"));
 
        // 保存对象
        User user = new User("C++", 40);
        redisTemplate.opsForValue().set(user.getUsername(), user);
 
        user = new User("Java", 30);
        redisTemplate.opsForValue().set(user.getUsername(), user);
 
        user = new User("Python", 20);
        redisTemplate.opsForValue().set(user.getUsername(), user);
 
        Assert.assertEquals(20, redisTemplate.opsForValue().get("Python").getAge());
        Assert.assertEquals(30, redisTemplate.opsForValue().get("Java").getAge());
        Assert.assertEquals(40, redisTemplate.opsForValue().get("C++").getAge());
 
    }
     
    @Test
    public void test1() throws Exception{
        List<User> us = new ArrayList<>();
        User u1 = new User("rs1", 21);
        User u2 = new User("rs2", 22);
        User u3 = new User("rs3", 23);
        us.add(u1);
        us.add(u2);
        us.add(u3);
        rt.opsForValue().set("key_ul", us);
        System.out.println("放入缓存》。。。。。。。。。。。。。。。。。。。");
        System.out.println("=============================");
        List<User> redisList = rt.opsForValue().get("key_ul");
        System.out.println("redisList="+redisList);
    }
     
    @Test
    public void test2() throws Exception{
        List<Map<String,Object>> ms = new ArrayList<>();
        Map<String,Object> map = new HashMap<>();
        map.put("name", "rs");
        map.put("age", 20);
         
        Map<String,Object> map1 = new HashMap<>();
        map1.put("name", "rs1");
        map1.put("age", 21);
         
        Map<String,Object> map2 = new HashMap<>();
        map2.put("name", "rs2");
        map2.put("age", 22);
         
        ms.add(map);
        ms.add(map1);
        ms.add(map2);
        rm.opsForValue().set("key_ml", ms);
        System.out.println("放入缓存》。。。。。。。。。。。。。。。。。。。");
        System.out.println("=============================");
        List<Map<String,Object>> mls = rm.opsForValue().get("key_ml");
        System.out.println("mls="+mls);
    }
 
}
```
##### 输出
![](/Spring Boot (七)：操作redis数据库/1501492308653006620.png)

> Github: [代码示例 : https://github.com/rstyro/spring-boot](https://github.com/rstyro/spring-boot)
