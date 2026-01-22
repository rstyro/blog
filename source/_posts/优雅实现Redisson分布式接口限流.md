---
title: 优雅实现Redisson分布式接口限流
tags: [Spring Boot]
categories: Java
date: 2026-01-22 14:48:58
updated: 2026-01-22 14:48:58
---



## 前言

之前已经讲过2篇接口防刷的文章：《别再让接口被刷爆了！资深架构师的防刷实战笔记，附完整代码1》、《别再让接口被刷爆了！资深架构师的防刷实战笔记，附完整代码2》，都是我们自己实现lua脚本的，包含算法

- 固定窗口计数器算法
- 令牌桶限流
- 漏桶限流
- 滑动时间窗口限流



今天再加一篇吧，我们不用自己实现lua脚本了，直接用现成的限流类就行。

<!--more-->





## 一、先搞懂：为什么需要接口限流？

- 想象一下：你开了一家奶茶店，最多同时接待10个顾客点单，要是突然冲进来50个人，柜台会被围满，员工忙不过来，最后谁都喝不上奶茶，甚至可能把点单系统挤崩溃。

- 接口就像奶茶店的柜台，每一次请求都是一个顾客。当高并发请求（比如秒杀、爬虫攻击、突发流量）涌来时，接口处理能力会达到瓶颈，轻则响应变慢，重则服务宕机。

- 接口限流就是给奶茶店装“人数控制器”——规定单位时间内最多接待多少顾客（请求），超出部分要么排队等，要么直接告知“暂时无法服务”，从而保护接口稳定运行。
- 接口限流的核心目标是**保护服务稳定性**：通过设定 “单位时间内允许处理的最大请求数”，对超出阈值的请求进行排队或拒绝，确保服务始终在安全负载范围内运行。

- 而分布式系统中，接口通常部署在多台服务器上，单服务器本地限流（如单台限制 100QPS）会导致总限流阈值失控（N 台服务器则实际阈值为 N*100QPS）。Redisson RRateLimiter 基于 Redis 实现全局限流状态共享，是分布式场景下的最优选择之一。




## 二、Redisson RRateLimiter：分布式限流方案

### 1. 核心原理：令牌桶算法

RRateLimiter底层用的是“令牌桶算法”，逻辑特别好懂：

- 系统按固定速率（比如每秒10个）往“令牌桶”里放令牌，桶有最大容量（满了就不再加）；
- 每个请求过来时，都要先从桶里拿一个令牌；
- 拿到令牌就能继续处理请求，拿不到（桶空了）就触发限流（排队/拒绝）。

优势在于：既能限制平均速率，又能应对短时间突发流量（只要桶里有存量令牌），适合大多数接口场景。




### 2. 为什么选RRateLimiter？

相比自己基于Redis手动实现限流（比如用Redis计数器+过期时间），RRateLimiter有3个核心优势：

- **开箱即用**：封装好了令牌桶逻辑，不用自己处理并发竞争、令牌生成等细节；
- **分布式安全**：基于Redis的原子操作，多台服务器共享限流状态，不会出现“限流不准”；
- **灵活可控**：支持阻塞等待令牌、非阻塞获取、自定义限流速率，适配不同业务场景。





## 三、实战：用RRateLimiter实现接口限流

下面以Spring Boot 2.x项目为例，一步步演示如何集成RRateLimiter，全程贴可运行代码，新手也能跟着做。



### 1. 环境准备

#### 第一步：引入依赖

在pom.xml中添加Redisson和Redis依赖

```xml

<!-- Redis自动配置（Spring Boot自带，若已引入可忽略） -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-data-redis</artifactId>
</dependency>

<!-- Redisson依赖 -->
<dependency>
    <groupId>org.redisson</groupId>
    <artifactId>redisson</artifactId>
    <!-- 可以用最新版 -->
    <version>3.22.0</version>
</dependency>
```



#### 第二步：配置Redisson客户端

首先在`application.yml`中配置 Redis 基础信息（以单机版为例，集群 / 哨兵模式可参考注释扩展）：

```yaml

# 这里就正常配置redis就行，单机，哨兵模式还是集群都行
spring:
  redis:
    password: abcsee2see
    database: 0
    port: 6379
    host: 127.0.0.1
    lettuce:
      pool:
        max-idle: 10
        min-idle: 0
        max-active: 10
        max-wait: -1ms
    timeout: 10000ms

```



然后编写 Redisson 配置类，手动注入`RedissonClient`（相比自动配置更灵活）：


```java
import org.redisson.Redisson;
import org.redisson.api.RedissonClient;
import org.redisson.config.Config;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.util.StringUtils;

/**
 * redisson 配置，下面是单节点配置：
 * 官方wiki地址：https://github.com/redisson/redisson/wiki/2.-%E9%85%8D%E7%BD%AE%E6%96%B9%E6%B3%95#26-%E5%8D%95redis%E8%8A%82%E7%82%B9%E6%A8%A1%E5%BC%8F
 *
 */
@Configuration
public class RedissonConfig {

    @Value("${spring.redis.host}")
    private String host;

    @Value("${spring.redis.port}")
    private String port;

    @Value("${spring.redis.password}")
    private String password;

    @Bean
    public RedissonClient redissonClient(){
        Config config = new Config();
        //单节点
        config.useSingleServer().setAddress("redis://" + host + ":" + port);
        if(StringUtils.isEmpty(password)){
            config.useSingleServer().setPassword(null);
        }else{
            config.useSingleServer().setPassword(password);
        }
        // 集群模式示例（按需启用）
        // config.useClusterServers()
        //        .setScanInterval(2000)
        //        .addNodeAddress("redis://127.0.0.1:7000", "redis://127.0.0.1:7001");
        
        // 哨兵模式示例（按需启用）
        // config.useSentinelServers()
        //        .setMasterName("mymaster")
        //        .addSentinelAddress("redis://127.0.0.1:26379", 		"redis://127.0.0.1:26380");
        return Redisson.create(config);
    }
}

```

这样我们就可以在其他地方使用RedissonClient了



### 2. 接口中使用RRateLimiter

以“用户下单接口”为例，限制每秒最多处理10个请求（10 QPS），分两种常见场景演示。

#### 场景1：非阻塞获取令牌（拿不到就直接拒绝）

适合秒杀、高频查询等无需排队的场景，超出限流阈值直接返回友好提示：

```java


import org.redisson.api.RRateLimiter;
import org.redisson.api.RedissonClient;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RestController;

import javax.annotation.Resource;

@RestController
public class OrderController {

    @Resource
    private RedissonClient redissonClient;

    // 下单接口：限制10 QPS（每秒最多10个请求）
    @PostMapping("/order/submit")
    public String submitOrder() {
        // 1. 获取限流实例（key为"order_submit_limit"，不同接口用不同key区分）
        RRateLimiter rateLimiter = redissonClient.getRateLimiter("order_submit_limit");
        
        // 2. 配置限流规则：每秒生成10个令牌，桶最大容量10（突发流量最多处理10个）
        rateLimiter.trySetRate(RateType.OVERALL, 10, 1, RateIntervalUnit.SECONDS);
        
        // 3. 尝试获取1个令牌（非阻塞，立即返回结果）
        boolean acquired = rateLimiter.tryAcquire(1);
        if (!acquired) {
            // 拿不到令牌，返回限流提示
            return "请求过频繁，请稍后再试！";
        }
        
        // 4. 拿到令牌，执行下单逻辑
        try {
            // 模拟下单操作（数据库插入、库存扣减等）
            Thread.sleep(50); // 模拟处理耗时
            return "下单成功！";
        } catch (InterruptedException e) {
            e.printStackTrace();
            return "下单失败！";
        }
    }
}

```

#### 场景2：阻塞等待令牌（拿不到就等，直到超时）

适合允许短暂排队的场景，比如普通接口查询，最多等1秒，还拿不到令牌再拒绝。

```java


// 新增查询接口：允许排队1秒，限流10 QPS
@PostMapping("/order/query")
public String queryOrder() {
    RRateLimiter rateLimiter = redissonClient.getRateLimiter("order_query_limit");
    rateLimiter.trySetRate(RateType.OVERALL, 10, 1, RateIntervalUnit.SECONDS);
    
    // 尝试获取1个令牌，最多等待1秒（1000毫秒）
    boolean acquired = rateLimiter.tryAcquire(1, 1000, java.util.concurrent.TimeUnit.MILLISECONDS);
    if (!acquired) {
        return "查询过频繁，请稍后再试！";
    }
    
    // 执行查询逻辑
    return "订单状态：已支付";
}

```

### 3. 核心API说明

- **getRateLimiter(String key)**：获取限流实例，key是唯一标识，不同接口/场景用不同key，避免限流规则冲突。
- **trySetRate(RateType type, long rate, long interval, RateIntervalUnit unit)**：配置限流规则，参数拆解：
    - RateType.OVERALL：全局限流（所有服务器共享同一规则）；RateType.PER_CLIENT：单客户端限流（按IP/用户区分，适合个性化限流）；
    - rate：单位时间内生成的令牌数（比如10就是每秒10个）；
    - interval：时间间隔（比如1就是1秒）；
    - unit：时间单位（秒/分/时，常用SECONDS）。
- **tryAcquire(int permits)**：非阻塞获取permits个令牌，立即返回true（拿到）/false（没拿到）。
- **tryAcquire(int permits, long waitTime, TimeUnit unit)**：阻塞等待waitTime时间，期间拿到令牌返回true，超时返回false。
- **acquire(int permits)**：无限阻塞等待，直到拿到令牌（慎用，避免请求堆积导致服务雪崩）。




## 四、高级进阶使用

上面我们可以看到我们是直接在每个接口的代码里面进行获取RRateLimiter，然后配置的，如果几十个接口，业务里面都要写重复逻辑不太合理，所以我们可以把这块逻辑通过AOP切片抽取出来。

### 1、自定义一个防刷注解

注解就像给接口贴上一个标签，声明它需要被保护

```java
/**
 * redisson限流注解
 */
@Target(ElementType.METHOD)
@Retention(RetentionPolicy.RUNTIME)
@Documented
public @interface RedissonRateLimit {

    /**
     * 限流key，支持SpEL表达式
     */
    String key() default "";

    /**
     * 令牌生成速率 (每秒生成的令牌数)
     */
    long rate() default 10;

    /**
     * 每次请求消耗的令牌数
     */
    int tokens() default 1;

    /**
     * 限流时的提示信息
     */
    String message() default "请求过于频繁，请稍后再试";
}

```

### 2、编写AOP切面

AOP（面向切面编程）允许我们在不侵入原有业务代码的情况下，在方法执行前后“织入”新的逻辑，限流逻辑的核心。


```java
@Aspect
@Component
@Slf4j
public class RedissonRateLimitAspect {

    @Autowired
    private RedissonClient redissonClient;

    /**
     * 切片-方法级别
     */
    @Around("@annotation(rateLimit)")
    public Object around(ProceedingJoinPoint joinPoint, RedissonRateLimit rateLimit) throws Throwable {
        String key = buildRateLimitKey(joinPoint, rateLimit);
        RRateLimiter rRateLimiter = redissonClient.getRateLimiter(key);
        // 初始化限流器
        rRateLimiter.trySetRate(RateType.OVERALL, rateLimit.rate(), 1, RateIntervalUnit.SECONDS);
        if (!rRateLimiter.tryAcquire(rateLimit.tokens())) {
            log.warn("接口限流触发 - key: {}, 方法: {}", key, joinPoint.getSignature().getName());
            return R.fail(rateLimit.message());
        }
        return joinPoint.proceed();
    }

    /**
     * 构建限流key
     */
    private String buildRateLimitKey(ProceedingJoinPoint joinPoint, RedissonRateLimit rateLimit) {
        String key = rateLimit.key();
        // 如果key为空，使用默认格式
        if (key.isEmpty()) {
            MethodSignature signature = (MethodSignature) joinPoint.getSignature();
            Method method = signature.getMethod();
            String className = method.getDeclaringClass().getSimpleName();
            String methodName = method.getName();
            return String.format("rate_limit:%s:%s", className, methodName);
        }
        // 如果key包含SpEL表达式，进行解析
        if (key.contains("#")) {
            return AopUtil.parseSpel(key, joinPoint);
        }
        return key;
    }
}
```

### 3、在Controller使用示例


```java
@RestController
@RequestMapping("/redissonRate")
public class RedissonRateController {

    @GetMapping("/queryQuotaInfo")
    @RedissonRateLimit(key = "'queryQuotaInfo:' + #storageType",rate = 1)
    public R queryQuotaInfo(@RequestParam(value = "storageType") String storageType) {
        return R.ok("storageType:"+storageType);
    }
}
```

我们只需要在需要限流的接口方法上使用：`@RedissonRateLimit` 即可。

然后我们简单的测试一下，结果如下：

![测试报告](all.png)

![接口请求成功示例](suc.png)

![接口请求失败示例](err.png)


然后我们可以看看redis中的数据结构：

![redis的数据结构](redis.png)

> 我们可以看到保存在redis的速率为1秒产品一个token令牌
> 



## 五、常见问题与注意事项



##### 1. 限流规则重复配置怎么办？

`trySetRate`是 “仅首次生效” 的设计：若 key 对应的限流实例已配置规则，后续调用不会修改。如需动态调整规则，需先调用`rateLimiter.delete()`删除旧实例，再重新配置。



##### 2. Redis宕机了会怎样？

RRateLimiter 强依赖 Redis，Redis 宕机会抛出连接异常。生产环境需添加降级逻辑：


```java
// 优化后的获取令牌逻辑（增加降级）
boolean acquired = false;
try {
    acquired = rateLimiter.tryAcquire(redissonRateLimit.tokens());
} catch (Exception e) {
    log.error("【限流异常】Redis连接失败，触发降级", e);
    // 降级策略：临时允许请求通过（或返回兜底提示）
    acquired = true;
}
```



##### 3. 如何实现“按用户/IP限流”？

用`RateType.PER_CLIENT`+自定义key即可。比如按用户ID限流：key设为"user_order_limit_" + userId，再将`RateType`设为`PER_CLIENT`，就能实现“每个用户每秒最多2个下单请求”。

```java


// 按用户ID限流：每个用户每秒最多2个下单请求
@PostMapping("/order/submit/{userId}")
public String submitOrderByUser(@PathVariable String userId) {
    RRateLimiter rateLimiter = redissonClient.getRateLimiter("user_order_limit_" + userId);
    // RateType.PER_CLIENT：按客户端（此处绑定用户ID）区分限流
    rateLimiter.trySetRate(RateType.PER_CLIENT, 2, 1, RateIntervalUnit.SECONDS);
    
    boolean acquired = rateLimiter.tryAcquire(1);
    if (!acquired) {
        return "您下单太频繁，请稍后再试！";
    }
    return "下单成功！";
}

```



##### 4. 集群环境下限流准吗？

准！因为RRateLimiter的令牌生成和获取都基于Redis的原子操作（Lua脚本），多台服务器操作同一Redis实例，不会出现“超发令牌”或“限流失效”。若Redis是集群模式，Redisson会自动适配，无需额外修改代码。





## 六、总结



Redisson RRateLimiter把复杂的分布式限流逻辑封装得极简，核心就是“拿令牌-执行业务-没令牌限流”三步。无论是普通接口的QPS控制，还是用户级、IP级的个性化限流，都能轻松应对。



关键是抓住“Redis全局共享状态”这个核心，再根据业务场景选择“阻塞/非阻塞”获取令牌的方式，就能既保护接口稳定，又不影响用户体验。赶紧在项目中试试吧！






#### 资源获取：

本文完整代码已上传至 GitHub，欢迎 Star ⭐ 和 Fork

- Gitee地址：https://gitee.com/rstyro/spring-boot/tree/master/SpringBoot-limit
- Github地址：https://github.com/rstyro/Springboot/tree/master/SpringBoot-limit



**欢迎分享你的经验**：
在实际工作中，你有哪些独到的见解或踩坑经验？欢迎在评论区交流讨论，让我们一起进步