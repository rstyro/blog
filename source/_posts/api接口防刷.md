---
title: Api接口防刷
date: 2019-04-15 14:48:01
updated: 2019-04-15 14:48:01
tags: [Spring Boot, Java]
categories: Java
---


## 一、前言

**什么是API接口防刷？**

API接口防刷是一套重要的技术措施，其核心目标是保护后端服务免受恶意或过度的请求，确保系统的稳定性和数据的安全性。

<!--more-->

#### 1、为什么你的接口会被“刷”？

在深入技术之前，我们必须理解“刷”的本质。它本质上是一种对服务器资源的恶意或过度争夺。

- **恶意攻击**：竞争对手或黑客通过脚本、僵尸网络，高频访问你的登录接口、短信接口、下单接口，目的是拖垮你的服务，造成经济损失。
- **“黄牛”行为**：在秒杀、抢票、限量优惠券等场景下，“黄牛”利用程序高频请求，抢占正常用户资源，再进行倒卖，严重破坏业务公平性。
- **代码BUG或爬虫**：客户端循环调用BUG，或被恶意爬虫疯狂抓取数据，消耗大量服务器带宽和计算资源。



**其核心危害不言而喻：**

- **服务器资源耗尽**：CPU、内存、数据库连接池被占满，正常业务无法进行。
- **高昂的成本**：如果使用云服务，莫名的流量会带来高昂的账单。特别是短信、邮件等需要付费的第三方服务接口。
- **数据失真与业务不公**：抢购活动形同虚设，真实用户怨声载道，品牌形象受损。
- **安全风险**：可能成为DDoS攻击的入口，导致整个应用瘫痪。




## 二、快速开始



### 1、防刷的第一道防线：IP级限流

想象一下，一个水龙头如果开得太大，水会溅得到处都是。我们首先给它加一个“限流阀”。基于IP的限流就是这个最简单的“阀”。

**思路**：在单位时间内，同一个IP地址访问特定接口的次数不能超过我们设定的阈值。



**技术实现：Spring Boot + AOP + Redis**

> 我们选择Redis是因为它读写速度快，且天然支持过期时间，非常适合做计数器。


#### ①、添加依赖

在你的`pom.xml`中引入必要的依赖。

```xml
<!-- aop -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-aop</artifactId>
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



#### ②、自定义一个防刷注解

注解就像给接口贴上一个标签，声明它需要被保护

```java
@Inherited
@Target({ElementType.METHOD,ElementType.TYPE})
@Retention(RetentionPolicy.RUNTIME)
public @interface RequestLimit {
    /**
     * 资源key，用于区分不同的接口，默认为方法名
     */
    String key() default "";

    /**
     * 在 second 秒内，最大只能请求 maxCount 次
     */
    int second() default 1;
    /**
     * 在时间窗口内允许访问的次数
     */
    int maxCount() default 1;
}

```



#### ③、编写AOP切面

AOP（面向切面编程）允许我们在不侵入原有业务代码的情况下，在方法执行前后“织入”新的逻辑，防刷逻辑的核心。

```java
@Aspect
@Component
@Slf4j
public class RateLimitAspect {

    @Autowired
    private RedisTemplate<String, Object> redisTemplate;


    /**
     * 环绕通知，切入所有被@RateLimit注解标记的方法
     * “@annotation(requestLimit)” 只匹配方法上的
     * “@within(requestLimit)” 匹配类上的
     */
    @Around("(@annotation(requestLimit) || @within(requestLimit))")
    public Object around(ProceedingJoinPoint joinPoint, RequestLimit requestLimit) throws Throwable {

        // 获取HttpServletRequest对象，从而拿到客户端IP
        ServletRequestAttributes attributes = (ServletRequestAttributes) RequestContextHolder.getRequestAttributes();
        if (attributes == null) {
            // 非Web请求，直接放行
            return joinPoint.proceed();
        }
        HttpServletRequest request = attributes.getRequest();
        // 获取客户端真实IP的方法
        String ip = IpUtil.getClientIpAddress(request);

        // 优先从方法上获取注解
        MethodSignature signature = (MethodSignature) joinPoint.getSignature();
        Method method = signature.getMethod();
        requestLimit = getTagAnnotation(method, RequestLimit.class);


        // 构建Redis的key，格式为：rate_limit:接口key:IP
        String methodName = method.getName();
        String key = requestLimit.key().isEmpty() ? methodName : requestLimit.key();
        String redisKey = "rate_limit:" + key + ":" + ip;

        // 操作Redis，进行计数和判断
        ValueOperations<String, Object> valueOps = redisTemplate.opsForValue();
        Integer currentCount = (Integer) valueOps.get(redisKey);

        if (currentCount == null) {
            // 第一次访问，设置key，初始值为1，并设置过期时间
            valueOps.set(redisKey, 1, requestLimit.second(), TimeUnit.SECONDS);
        } else if (currentCount < requestLimit.maxCount()) {
            // 计数未达到阈值，计数器+1 (注意：这里Redis的过期时间保持不变)
            valueOps.increment(redisKey);
        } else {
            // 计数已达到或超过阈值，抛出异常或返回错误信息
            log.warn("IP【{}】访问接口【{}】过于频繁，已被限流", ip, methodName);
            return R.fail(ApiResultEnum.REQUEST_LIMIT);
        }

        // 执行目标方法（即正常的业务逻辑）
        return joinPoint.proceed();
    }

    /**
     * 获取目标注解
     * 如果方法上有注解就返回方法上的注解配置，否则类上的
     * @param method
     * @param annotationClass
     * @param <A>
     * @return
     */
    public <A extends Annotation> A getTagAnnotation(Method method, Class<A> annotationClass) {
        // 获取方法中是否包含注解
        Annotation methodAnnotate = method.getAnnotation(annotationClass);
        //获取 类中是否包含注解，也就是controller 是否有注解
        Annotation classAnnotate = method.getDeclaringClass().getAnnotation(annotationClass);
        return (A) (methodAnnotate!= null?methodAnnotate:classAnnotate);
    }
}

```



#### ④、在Controller使用示例


```java
@RestController
@RequestMapping("/index")
@RequestLimit(maxCount = 5,second = 10)
public class IndexController {

    /**
     * @RequestLimit 修饰在方法上，优先使用其参数
     * @return
     */
    @GetMapping("/test1")
    @RequestLimit
    public R test(){
        //TODO ...
        return R.ok();
    }

    /**
     * @RequestLimit 修饰在类上，用的是类的参数
     * @return
     */
    @GetMapping("/test2")
    public R test2(){
        //TODO ...
        return R.ok();
    }
}

```

在Controller上有一个默认的`@RequestLimit(maxCount = 5,second = 10)`限流，如果这个类下的其他接口有使用`@RequestLimit`则覆盖默认注解，否则都走类上注解。



我们测试请求接口

![请求接口测试限流](api1.png)


然后控制台打印

![控制台打印](log1.png)



#### ⑤、这个方案的优缺点

- **优点**：实现简单，能有效阻止“无脑刷”。
- **缺点**：
    1. **误杀问题**：在局域网或公司出口IP相同的情况下，所有用户会共享一个IP限额，导致误伤正常用户。
    2. **易绕过**：对于专业的攻击者，他们可以通过代理IP池轻松绕过IP限制。



### 2、用户级限流



为了解决IP限流的缺陷，我们引入更精细的维度——用户。这要求用户必须处于登录状态。

**思路**：在单位时间内，同一个用户ID（或Token）访问特定接口的次数不能超过阈值。

我们只需对上面的AOP切面进行小幅改造：



```java
/**
 * 环绕通知，切入所有被@RateLimit注解标记的方法
 * “@annotation(requestLimit)” 只匹配方法上的
 * “@within(requestLimit)” 匹配类上的
 */
@Around("(@annotation(requestLimit) || @within(requestLimit))")
public Object around(ProceedingJoinPoint joinPoint, RequestLimit requestLimit) throws Throwable {

 	// 前面省略....
    HttpServletRequest request = attributes.getRequest();
    

   // 关键修改：从请求头中获取用户Token，并解析出用户ID
    String token = request.getHeader("Authorization");
    // 你需要实现这个方法，如果是jwt直接解析得到uid
 	String userId = parseUserIdFromToken(token); 
    
    if (userId == null) {
        // 如果用户未登录，可以降级为使用IP限流，或者直接拒绝
        // throw new RuntimeException("用户未登录");
        // 降级方案：未登录用户使用IP
        userId = IpUtil.getClientIpAddress(request); 
    }

    // 构建Redis的key，格式为：rate_limit:接口key:userId
    String methodName = method.getName();
    String key = requestLimit.key().isEmpty() ? methodName : requestLimit.key();
    String redisKey = "rate_limit:" + key + ":" + userId;

    // 操作Redis，进行计数和判断
    // ...省略后续相同的Redis计数逻辑

    // 执行目标方法（即正常的业务逻辑）
    return joinPoint.proceed();
}
```



#### ①、这个方案的优缺点

- **优点**：精准到人，避免了IP限流的误杀问题，防护效果更好。
- **缺点**：
    - 要求用户必须登录，对匿名接口不友好。
    - 如果攻击者盗取大量账号，依然可以发起攻击。





### 3、令牌桶限流

使用Redis + Lua实现分布式令牌桶



**令牌桶算法的核心原理**：

- 以固定速率向桶中添加令牌
- 每个请求需要获取一个令牌才能被处理
- 如果桶中没有令牌，则拒绝请求
- 允许突发流量（桶中有积累的令牌时）





**为什么选择 Redis + Lua？**

- **原子性**：Lua脚本在Redis中原子执行，避免并发问题
- **高性能**：减少网络往返，所有逻辑在Redis服务器端完成
- **分布式**：Redis作为集中式存储，适合集群环境
- **灵活性**：可自定义各种参数和逻辑



#### ①、自定义防刷注解

```java
/**
 * 令牌桶限流注解
 */
@Target(ElementType.METHOD)
@Retention(RetentionPolicy.RUNTIME)
@Documented
public @interface TokenBucketRateLimit {

    /**
     * 限流key，支持SpEL表达式
     */
    String key() default "";

    /**
     * 令牌生成速率 (每秒生成的令牌数)
     */
    double rate() default 10.0;

    /**
     * 桶容量
     */
    int capacity() default 20;

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



#### ②、Lua脚本



- 在resource下面新建一个`tokenRate.lua` 文件，编辑如下：

```lua
-- 令牌桶限流 Lua 脚本
-- KEYS[1]: 限流的key
-- ARGV[1]: 令牌生成速率 (每秒生成的令牌数)
-- ARGV[2]: 桶的容量 (最大令牌数)
-- ARGV[3]: 当前时间戳 (秒)
-- ARGV[4]: 本次请求的令牌数 (默认为1)

local key = KEYS[1]
local rate = tonumber(ARGV[1])
local capacity = tonumber(ARGV[2])
local now = tonumber(ARGV[3])
local requested = tonumber(ARGV[4])

-- 计算填满桶需要的时间，用于设置key的过期时间
local fill_time = capacity / rate
local ttl = math.floor(fill_time * 2)  -- 过期时间为填满时间的2倍

-- 从Redis获取上次的令牌数和刷新时间
local last_tokens = tonumber(redis.call("get", key))
if last_tokens == nil then
    last_tokens = capacity  -- 第一次访问，令牌数为桶容量
end

local last_refreshed = tonumber(redis.call("get", key .. ":ts"))
if last_refreshed == nil then
    last_refreshed = now  -- 第一次访问，刷新时间为当前时间
end

-- 计算时间差和应该补充的令牌数
local delta = math.max(0, now - last_refreshed)
local filled_tokens = math.min(capacity, last_tokens + (delta * rate))

-- 判断是否允许本次请求
local allowed = filled_tokens >= requested
local new_tokens = filled_tokens
local allowed_num = 0

if allowed then
    new_tokens = filled_tokens - requested
    allowed_num = 1
    -- 更新令牌数和时间戳
    redis.call("setex", key, ttl, new_tokens)
    redis.call("setex", key .. ":ts", ttl, now)
else
    -- 即使不允许，也更新状态（为了计算下一次的令牌数）
    redis.call("setex", key, ttl, new_tokens)
    redis.call("setex", key .. ":ts", ttl, last_refreshed)
end

-- 返回结果：是否允许(1/0)，剩余令牌数，桶容量
return {allowed_num, new_tokens, capacity}
```

#### ③、Lua脚本配置

```java
@Configuration
public class RedisConfig{

    /**
     * lua脚本
     */
    @Value("classpath:tokenRate.lua")
    private org.springframework.core.io.Resource luaFile;

    /**
     * 令牌桶限流 Lua 脚本
     */
    @Bean
    public RedisScript<List> tokenBucketScript() {
        DefaultRedisScript<List> redisScript = new DefaultRedisScript<>();
        redisScript.setLocation(luaFile);
        redisScript.setResultType(List.class);
        return redisScript;
    }

}
```

#### ④、令牌桶限流服务类

```java
@Service
@Slf4j
public class TokenBucketRateLimiter {

    @Autowired
    private RedisTemplate<String, Object> redisTemplate;

    @Autowired
    private RedisScript<List> tokenBucketScript;

    /**
     * 尝试获取令牌
     *
     * @param key          限流key
     * @param rate         令牌生成速率 (个/秒)
     * @param capacity     桶容量
     * @param tokenRequest 请求的令牌数
     * @return 是否允许访问
     */
    public boolean tryAcquire(String key, double rate, int capacity, int tokenRequest) {
        // 转换为秒
        long now = System.currentTimeMillis() / 1000;

        List<String> keys = Arrays.asList(key);

        List<Long> result = (List<Long>) redisTemplate.execute(tokenBucketScript, keys, rate, capacity, now, tokenRequest);

        if (ObjectUtils.isEmpty(result)) {
            log.warn("令牌桶限流脚本执行异常, key: {}", key);
            return false;
        }
        boolean allowed = result.get(0) == 1;

        return allowed;
    }
}
```

#### ⑤、令牌桶切片核心逻辑



```java
@Aspect
@Component
@Slf4j
public class TokenBucketRateLimitAspect {

    @Autowired
    private TokenBucketRateLimiter rateLimiter;

    private final ExpressionParser parser = new SpelExpressionParser();

    /**
     * 切片-方法级别
     */
    @Around("@annotation(rateLimit)")
    public Object around(ProceedingJoinPoint joinPoint, TokenBucketRateLimit rateLimit) throws Throwable {
        String key = buildRateLimitKey(joinPoint, rateLimit);
		// 核心判断
        boolean allowed = rateLimiter.tryAcquire(key,rateLimit.rate(),rateLimit.capacity(),rateLimit.tokens());
        if (!allowed) {
            log.warn("接口限流触发 - key: {}, 方法: {}", key, joinPoint.getSignature().getName());
            // 这里可以返回统一的错误结果
            return R.fail(rateLimit.message());
        }
        return joinPoint.proceed();
    }

    /**
     * 构建限流key
     */
    private String buildRateLimitKey(ProceedingJoinPoint joinPoint, TokenBucketRateLimit rateLimit) {
        String key = rateLimit.key();

        // 如果key为空，使用默认格式
        if (key.isEmpty()) {
            MethodSignature signature = (MethodSignature) joinPoint.getSignature();
            Method method = signature.getMethod();
            String className = method.getDeclaringClass().getSimpleName();
            String methodName = method.getName();

            // 尝试获取用户信息，实现更细粒度的限流
            String userKey = getUserKey();
            return String.format("rate_limit:%s:%s:%s", className, methodName, userKey);
        }

        // 如果key包含SpEL表达式，进行解析
        if (key.contains("#")) {
            return parseSpel(key, joinPoint);
        }

        return key;
    }

    /**
     * 获取用户标识（用户ID或IP）
     */
    private String getUserKey() {
        try {
            ServletRequestAttributes attributes = (ServletRequestAttributes)
                    RequestContextHolder.getRequestAttributes();
            if (attributes != null) {
                HttpServletRequest request = attributes.getRequest();
                // 优先使用登录用户ID
                String userId = (String) request.getAttribute("userId");
                if (userId != null) {
                    return "user:" + userId;
                }
                // 降级为使用IP
                return "ip:" + IpUtil.getClientIpAddress(request);
            }
        } catch (Exception e) {
            log.debug("获取用户标识失败", e);
        }
        return "anonymous";
    }


}
```



#### ⑥、controller示例

```java
@RestController
@RequestMapping("/tokenRate")
public class TokenRateController {

    /**
     * 测试发送短信
     */
    @GetMapping("/sendSms")
    @TokenBucketRateLimit(rate = 0.1, capacity = 2, message = "短信发送过于频繁")
    public R sendSms(){
        //TODO ...
        return R.ok();
    }

    /**
     * “@TokenBucketRateLimit(rate = 5.0, capacity = 20)”  每秒5次，突发20次
     */
    @TokenBucketRateLimit(key = "'search:' + #keyword", rate = 5.0, capacity = 10)
    @GetMapping("/search")
    public R search(@RequestParam String keyword) {
        // 搜索逻辑 - 这里key会根据keyword动态变化
        return R.ok("搜索结果:"+keyword);
    }
}
```



接口测试如下：



![请求发送短信接口示例图](api2.png)

后台日志打印如下：

![日志打印](log2.png)


## 三、总结



本文介绍了三种常见的API接口防刷方案：IP级限流、用户级限流和令牌桶限流。它们各有优缺点，适用于不同的场景。

- **IP级限流**：实现简单，但容易误伤和绕过。
- **用户级限流**：更精准，但需要用户登录，且可能被批量账号攻击。
- **令牌桶限流**：能够应对突发流量，且更平滑，但实现相对复杂。



- `IP级限流`和`用户级限流`，其实原理一样都是使用`固定窗口计数器算法`,固定窗口计数器算法存在`临界问题`（突刺现象），例如在窗口切换瞬间可能允许双倍请求通过。
- `令牌桶限流`  ：系统是以恒定速率生成令牌，请求需获取令牌才能被处理，流量比较平滑，因为有桶容量允许短暂的突发流量。



除了本文提到的固定窗口计数器和令牌桶算法，还有其他限流算法如滑动窗口计数器、漏桶算法等,感兴趣的同学可以去了解学习。每种算法都有其适用场景，需要根据实际需求选择。



#### 资源获取：

本文完整代码已上传至 GitHub，欢迎 Star ⭐ 和 Fork

- Gitee地址：[https://gitee.com/rstyro/spring-boot/tree/master/SpringBoot-limit](https://gitee.com/rstyro/spring-boot/tree/master/SpringBoot-limit)
- Github地址：[https://github.com/rstyro/Springboot/tree/master/SpringBoot-limit](https://github.com/rstyro/Springboot/tree/master/SpringBoot-limit)



**欢迎分享你的经验**：
在实际工作中，你有哪些独到的见解或踩坑经验？欢迎在评论区交流讨论，让我们一起进步



