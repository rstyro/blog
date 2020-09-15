---
title: SpringBoot与RedisCacheManager整合
date: 2019-04-16 17:02:09
tags: [Spring Boot]
categories: Java
---

### SpringBoot 缓存管理器CacheManager
从3.1开始Spring定义了`org.springframework.cache.Cache`和`org.springframework.cache.CacheManager`接口来统一不同的缓存技术；并支持使用`JCache（JSR-107）` 注解简化开发.
+ Cache接口为缓存的组件规范定义，包含缓存的各种操作集合；
+ Cache接口下Spring提供了各种xxxCache的实现；如`RedisCache`，`EhCacheCache` ,`ConcurrentMapCache`等；

## 快速开始
### 1、导入Maven
```
<dependency>
	<groupId>org.springframework.boot</groupId>
	<artifactId>spring-boot-starter-cache</artifactId>
</dependency>

<!-- redis -->
<dependency>
	<groupId>org.springframework.boot</groupId>
	<artifactId>spring-boot-starter-data-redis</artifactId>
</dependency>
<dependency>
	<groupId>org.apache.commons</groupId>
	<artifactId>commons-pool2</artifactId>
</dependency>
```
因为需要用`RedisCacheManager` 所以导入Redis依赖

### 2、配置Redis并开启缓存支持
```java
import com.fasterxml.jackson.annotation.JsonAutoDetect;
import com.fasterxml.jackson.annotation.PropertyAccessor;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.cache.CacheManager;
import org.springframework.cache.annotation.CachingConfigurerSupport;
import org.springframework.cache.annotation.EnableCaching;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.redis.cache.RedisCacheConfiguration;
import org.springframework.data.redis.cache.RedisCacheManager;
import org.springframework.data.redis.connection.lettuce.LettuceConnectionFactory;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.data.redis.serializer.Jackson2JsonRedisSerializer;
import org.springframework.data.redis.serializer.RedisSerializationContext;
import org.springframework.data.redis.serializer.RedisSerializer;
import org.springframework.data.redis.serializer.StringRedisSerializer;

import javax.annotation.Resource;
import java.time.Duration;

/**
 * 
 * @author rstyro
 * @time 2018-07-31
 *
 */
@Configuration
@EnableCaching // 开启缓存支持
public class RedisConfig extends CachingConfigurerSupport {
    @Resource
    private LettuceConnectionFactory lettuceConnectionFactory;


    /**
     * 配置CacheManager
     * @return
     */
    @Bean
    public CacheManager cacheManager() {
        RedisSerializer<String> redisSerializer = new StringRedisSerializer();
        Jackson2JsonRedisSerializer jackson2JsonRedisSerializer = new Jackson2JsonRedisSerializer(Object.class);

        //解决查询缓存转换异常的问题
        ObjectMapper om = new ObjectMapper();
        om.setVisibility(PropertyAccessor.ALL, JsonAutoDetect.Visibility.ANY);
        om.enableDefaultTyping(ObjectMapper.DefaultTyping.NON_FINAL);
        jackson2JsonRedisSerializer.setObjectMapper(om);

        // 配置序列化（解决乱码的问题）
        RedisCacheConfiguration config = RedisCacheConfiguration.defaultCacheConfig()
//                .entryTtl(Duration.ZERO)
                .entryTtl(Duration.ofSeconds(20))   //设置缓存失效时间
                .serializeKeysWith(RedisSerializationContext.SerializationPair.fromSerializer(redisSerializer))
                .serializeValuesWith(RedisSerializationContext.SerializationPair.fromSerializer(jackson2JsonRedisSerializer))
                .disableCachingNullValues();

        RedisCacheManager cacheManager = RedisCacheManager.builder(lettuceConnectionFactory)
                .cacheDefaults(config)
                .build();
        return cacheManager;
    }


    /**
     * RedisTemplate配置
     */
    @Bean
    public RedisTemplate<String, Object> redisTemplate(LettuceConnectionFactory lettuceConnectionFactory) {
        // 设置序列化
        Jackson2JsonRedisSerializer<Object> jackson2JsonRedisSerializer = new Jackson2JsonRedisSerializer<Object>(
                Object.class);
        ObjectMapper om = new ObjectMapper();
        om.setVisibility(PropertyAccessor.ALL, JsonAutoDetect.Visibility.ANY);
        om.enableDefaultTyping(ObjectMapper.DefaultTyping.NON_FINAL);
        jackson2JsonRedisSerializer.setObjectMapper(om);
        // 配置redisTemplate
        RedisTemplate<String, Object> redisTemplate = new RedisTemplate<String, Object>();
        redisTemplate.setConnectionFactory(lettuceConnectionFactory);
        RedisSerializer<?> stringSerializer = new StringRedisSerializer();
        redisTemplate.setKeySerializer(stringSerializer);// key序列化
        redisTemplate.setValueSerializer(jackson2JsonRedisSerializer);// value序列化
        redisTemplate.setHashKeySerializer(stringSerializer);// Hash key序列化
        redisTemplate.setHashValueSerializer(jackson2JsonRedisSerializer);// Hash value序列化
        redisTemplate.afterPropertiesSet();
        return redisTemplate;
    }


}

```

### 3、注解解析

注解的几个属性说明：
```java
//指定缓存组件的名字
@AliasFor("cacheNames")
String[] value() default {};

//指定缓存组件的名字
@AliasFor("value")
String[] cacheNames() default {};

// 缓存数据使用的Key,
String key() default "";

// key的生成器，可以自己指定key的生成组件id; 
// key 与 keyGenerator 两个只能选一个，不能同时指定
String keyGenerator() default "";

// 指定缓存管理器，
String cacheManager() default "";

//指定获得解析器，cacheManager、cacheResolver 两者取其一
String cacheResolver() default "";

// 符合condition条件,才缓存
String condition() default "";

// 和 codition 条件相反才成立
String unless() default "";

// 是否使用异步模式
boolean sync() default false;

// 只有@CacheEvict 有这个属性
// 清空所有缓存信息
boolean allEntries() default false;

// 只有@CacheEvict 有这个属性
// 缓存的清除是否在方法之前执行
// beforeInvocation=false  默认是在方法之后执行
boolean beforeInvocation() default false;
```

+ `@Cacheable`
	先查询缓存中是否存在，存在则返回缓存内容，反正执行方法后返回并把返回结果缓存起来
+ `@CacheEvict`
	删除指定缓存
+ `@CachePut`
	更新并刷新缓存,先执行方法内容，然后更新缓存
+ `@EnableCaching`
	这个是一个复合注解，可以拥有同时配置上面3个注解的功能



### 4、使用方法
```java
@CacheConfig(cacheNames = "act")  //这个注解表示类中共同放入到act 模块中
@Service
public class ActicleService implements IActicleService {

    @Autowired
    private ActicleMapper acticleMapper;

    /**
     * @Cacheable
     * 1、先查缓存，
     * 2、若没有缓存，就执行方法
     * 3、若有缓存。则返回，不执行方法
     *
     * 所以@Cacheable 不能使用result
     *
     * @return
     * @throws Exception
     */
    @Cacheable(key = "#root.methodName")
    public List<Acticle> list() throws Exception {
        return acticleMapper.getActicleList();
    }

    /**
     * @CachePut 更新并刷新缓存
     * 1、先调用目标方法
     * 2、把结果缓存
     * @param acticle
     * @return
     * @throws Exception
     */
    @CachePut(key = "#result.id" ,unless = "#result.id == null" )
    public Acticle save(Acticle acticle) throws Exception {
        acticle.setCreateBy(1l);
        acticle.setCreateTime(LocalDateTime.now());
        acticle.setModifyBy(1l);
        acticle.setModifyTime(LocalDateTime.now());
        acticleMapper.save(acticle);
        System.out.println("acticle="+acticle);
        return acticle;
    }

    /**
     * 删除指定key 的缓存
     * beforeInvocation=false  缓存的清除是否在方法之前执行
     * 默认是在方法之后执行
     * @param id
     * @return
     * @throws Exception
     */
    @CacheEvict(key = "#id",beforeInvocation = true)
    public int del(Long id) throws Exception {
        int isDel = 0;
        isDel = acticleMapper.del(id);
        return isDel;
    }

    /**
     * 删除所有缓存
     * @return
     * @throws Exception
     */
    @CacheEvict(allEntries = true)
    public int delAll() throws Exception {
        return 1;
    }

    @CachePut(key = "#result.id" ,unless = "#result.id == null" )
    public Acticle update(Acticle acticle) throws Exception {
        acticle.setModifyBy(1l);
        acticle.setModifyTime(LocalDateTime.now());
        return acticleMapper.update(acticle);
    }

    @Cacheable(key = "#id",condition = "#id > 0")
    public Acticle queryById(Long id) throws Exception {
        return acticleMapper.queryById(id);
    }

    /**
     * @Caching复杂组合缓存注解
     *
     * @param title
     * @return
     * @throws Exception
     */
    @Caching(cacheable = { @Cacheable(key = "#title")},
            put = {@CachePut(key = "#result.id"),
//            @CachePut(key = "T(String).valueOf(#page).concat('-').concat(#pageSize)")
            @CachePut(key = "T(String).valueOf('tag').concat('-').concat(#result.tagId)")
    })
    public Acticle queryByTitle(String title) throws Exception {
        return acticleMapper.queryByTitle(title);
    }

    @Cacheable(key = "T(String).valueOf('tag').concat('-').concat(#tagId)")
    public Acticle queryByTag(Long tagId) throws Exception {
        return null;
    }
}
```

## 缓存工作原理
当我们引入缓存的时候，SpringBoot的缓存自动配置`CacheAutoConfiguration`就会生效
+ 在`CacheAutoConfiguration` 中的`CacheConfigurationImportSelector`会导入很多缓存组件配置类
+ 通过debug看源码,知道imports 的内容如下
> 
```java
static class CacheConfigurationImportSelector implements ImportSelector {
	CacheConfigurationImportSelector() {
	}

	public String[] selectImports(AnnotationMetadata importingClassMetadata) {
		CacheType[] types = CacheType.values();
		String[] imports = new String[types.length];

		for(int i = 0; i < types.length; ++i) {
			imports[i] = CacheConfigurations.getConfigurationClass(types[i]);
		}

		return imports;
	}
}

/**
imports 如下

0 = "org.springframework.boot.autoconfigure.cache.GenericCacheConfiguration"
1 = "org.springframework.boot.autoconfigure.cache.JCacheCacheConfiguration"
2 = "org.springframework.boot.autoconfigure.cache.EhCacheCacheConfiguration"
3 = "org.springframework.boot.autoconfigure.cache.HazelcastCacheConfiguration"
4 = "org.springframework.boot.autoconfigure.cache.InfinispanCacheConfiguration"
5 = "org.springframework.boot.autoconfigure.cache.CouchbaseCacheConfiguration"
6 = "org.springframework.boot.autoconfigure.cache.RedisCacheConfiguration"
7 = "org.springframework.boot.autoconfigure.cache.CaffeineCacheConfiguration"
8 = "org.springframework.boot.autoconfigure.cache.SimpleCacheConfiguration"		
9 = "org.springframework.boot.autoconfigure.cache.NoOpCacheConfiguration"
*/

```
+ 如果没有引`Redis`， 则`SimpleCacheConfiguration`这个就是默认的配置类
+ 在`SimpleCacheConfiguration`注入了一个`ConcurrentMapCacheManager`
+ `ConcurrentMapCacheManager` 实现了`CacheManager` 接口
+ `ConcurrentMapCacheManager` 通过 `ConcurrentHashMap` 把数据缓存起来
+ 在 `CacheManager` 有一个`Cache getCache(String var1)` 方法换取缓存
+ 流程大概就这里，感兴趣的同学可以打断点阅读源码

### 本章代码示例地址
+ Github: [[https://github.com/rstyro/Springboot/tree/master/SpringBoot-RedisCacheManager](https://github.com/rstyro/Springboot/tree/master/SpringBoot-RedisCacheManager)
]([https://github.com/rstyro/Springboot/tree/master/SpringBoot-RedisCacheManager](https://github.com/rstyro/Springboot/tree/master/SpringBoot-RedisCacheManager)
)
+ Gitee : [[https://gitee.com/rstyro/spring-boot/tree/master/SpringBoot-RedisCacheManager](https://gitee.com/rstyro/spring-boot/tree/master/SpringBoot-RedisCacheManager)
]([https://gitee.com/rstyro/spring-boot/tree/master/SpringBoot-RedisCacheManager](https://gitee.com/rstyro/spring-boot/tree/master/SpringBoot-RedisCacheManager)
)