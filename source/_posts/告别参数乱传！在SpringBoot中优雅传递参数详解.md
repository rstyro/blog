---
title: 告别参数乱传！在SpringBoot中优雅传递参数详解
tags: []
categories: Java
date: 2025-12-16 13:52:30
updated: 2025-12-16 13:52:30
---


## 引言

还在用“传参大法”吗？

把 `userId`、`traceId`、`pageNo`从Controller一路传到Service，再传到Repository？你的方法签名是不是已经长到看不清，代码里到处是重复的取值和校验？

**这不是优雅，这是“参数包袱”**。它让代码臃肿、难以测试，更在异步编程时直接“瘫痪”。

<!--more-->

本文为你彻底梳理：在Spring Boot的请求旅途中，如何告别这种原始而脆弱的传参方式。我们将从最经典的 **ThreadLocal** 出发，揭秘其内存泄漏的坑与异步传递的痛；再深入阿里开源的 **TransmittableThreadLocal**，看它如何征服线程池；最终，前瞻JDK 21的 **Scoped Values**，探索下一代线程上下文管理的终极形态。

不止于用法，更深入原理与选型。无论你的项目处于哪个阶段，这里都有你需要的“优雅之道”。



## 一、提问：Spring Boot如何处理你的请求？

要理解上下文传递，首先要明白Spring Boot的**线程模型**。

当一个HTTP请求到达你的Spring Boot应用时，它并不会“奢侈地”为你创建一个全新线程。相反，它依赖于一个**线程池**（通常是Tomcat的`ThreadPoolExecutor`）。

**简单来说**：

- **1、接收请求**：容器（如Tomcat）的Acceptor线程接收到请求。
- **2、分配线程**：从内置的**业务线程池**中取出一个空闲的**工作线程**（通常是`http-nio-8080-exec-X`这样的线程）。
- **3、全程托管**：这个工作线程将负责该请求的**完整生命周期**——依次经过`Filter`、`Interceptor`、`Controller`、`Service`、`Repository`，直至返回响应。
- **3、线程回收**：请求处理完毕，该线程被释放回线程池，等待服务下一个请求。

**关键结论**：这意味着，同一个工作线程会处理无数个不同的用户请求。如果你把用户A的数据残留在线程变量中，当下一个用户B的请求复用到这个线程时，就可能发生数据错乱的灾难。这就是我们需要**线程隔离的请求上下文**的根本原因。





#### 1、问题开始：一个请求的典型痛点

让我们看一个查询订单的API，它暴露出参数传递的典型烦恼：



```java
@RestController
public class OrderController {
    @Autowired
    private OrderService orderService;

    @GetMapping("/orders")
    public List<Order> getOrders(@RequestParam int pageNo, 
                                 @RequestParam int pageSize, 
                                 @RequestHeader String token) {
        // 需要解析token、传递分页参数，代码开始臃肿
        Long userId = authService.parseUserId(token);
        return orderService.getOrders(userId, pageNo, pageSize);
    }
}
```



这个请求将穿越层层关卡：`Filter`-> `Interceptor`-> `AOP`-> `Controller`-> `Service`-> `Repository`。在每一关，我们可能都需要：

- **用户身份**（从Token解析出的`userId`）
- **链路追踪**（用于全链路监控的`traceId`）
- **分页参数**（如`pageNo`和`pageSize`）



如果每个方法都像上面那样显式传递这些参数，代码将迅速变成“超长参数列表”的重灾区。我们需要一个能在**同一个线程内**全局共享的“通行证”。



**我们要如何解决？**

- 我们可以使用ThreadLocal，ThreadLocal是什么？



## 二、ThreadLocal的作用



- ThreadLocal是Java提供的一种线程局部变量。每个线程都有一个独立的变量副本，因此可以在同一个线程中共享数据，而不同线程之间互不干扰。

- 在Spring Boot中，我们通常使用ThreadLocal来保存请求级别的上下文信息。例如，我们可以在拦截器中从HTTP请求头中提取用户Token，解析出用户ID，然后存入ThreadLocal，这样在后续的业务代码中就可以直接获取，而无需通过方法参数传递。

- 示例：

```java
/**
 * 用户请求上下文管理类
 */
public class RequestContext {
    // 用户身份
    private static final ThreadLocal<Long> USER_ID = new ThreadLocal<>();
    // 分页参数
    private static final ThreadLocal<Integer> PAGE_NO = new ThreadLocal<>();
    private static final ThreadLocal<Integer> PAGE_SIZE = new ThreadLocal<>();
    // 追踪ID
    private static final ThreadLocal<String> TRACE_ID = new ThreadLocal<>();

    // 设置方法
    public static void setContext(Long userId, Integer pageNo, Integer pageSize, String traceId) {
        USER_ID.set(userId);
        PAGE_NO.set(pageNo);
        PAGE_SIZE.set(pageSize);
        TRACE_ID.set(traceId);
    }
    
    // 获取方法
    public static Long getUserId() { return USER_ID.get(); }
    public static Integer getPageNo() { return PAGE_NO.get(); }
    public static Integer getPageSize() { return PAGE_SIZE.get(); }
    public static String getTraceId() { return TRACE_ID.get(); }
    
    // 关键：必须清理！
    public static void clear() {
        USER_ID.remove();
        PAGE_NO.remove();
        PAGE_SIZE.remove();
        TRACE_ID.remove();
    }
}

/**
 * 认证拦截器，用于设置上下文参数
 */
@Component
public class AuthInterceptor implements HandlerInterceptor {
    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) {
        // 从请求中提取所有上下文信息
        Long userId = parseToken(request.getHeader("Token"));
        // 分页参数可以从url提取或者从header提取都可以
        Integer pageNo = parseInt(request.getHeader("pageNo"), 1);
        Integer pageSize = parseInt(request.getHeader("pageSize"), 10);
        String traceId = Optional.ofNullable(request.getHeader("traceId"))
                                .orElse(UUID.randomUUID().toString());
        
        RequestContext.setContext(userId, pageNo, pageSize, traceId);
        return true;
    }
    
    @Override
    public void afterCompletion(HttpServletRequest request, HttpServletResponse response, Object handler, Exception ex) {
        // 请求结束，必须清空！
        RequestContext.clear(); 
    }
}
```



**业务代码变得极其简洁**：：

```java
@Service
public class OrderService {
    public PageResult<Order> getOrders() {
        // 直接从上下文获取所有必要信息
        Long userId = RequestContext.getUserId();
        int pageNo = RequestContext.getPageNo();
        int pageSize = RequestContext.getPageSize();
        
        // MyBatis分页插件或JPA分页查询可以直接使用
        return orderRepository.findByUserId(userId, pageNo, pageSize);
    }
}
```

这样，我们避免了在Controller和Service之间传递userId参数。



### 1、ThreadLocal的缺点

- **内存泄漏风险**：`ThreadLocal`使用不当可能导致内存泄漏。因为`ThreadLocal`变量是保存在`Thread`的`ThreadLocalMap`中的，而`ThreadLocalMap`的`Entry`的`key`是弱引用，但`value`是强引用。如果线程长时间运行（比如线程池中的线程），并且没有手动`remove`，那么`value`可能一直不会被回收。
- **异步场景下上下文传递问题**：当使用异步处理时，比如使用`@Async`注解或者使用`CompletableFuture`，业务代码会在另一个线程中执行，而原线程的ThreadLocal变量不会被自动传递到新线程。



**示例**：

```java
@Service
public class OrderService {
    
    @Async
    public CompletableFuture<List<Order>> getOrdersAsync() {
        Long userId = RequestContext.getUserId(); // 这里获取不到，因为在新线程中
        // ...
    }
    
    public List<Order> getOrders() {
        // 直接从上下文获取，可以拿到数据
        Long userId = RequestContext.getUserId();
        
        executor.submit(() -> {
            // 获取不到！线程池线程不是当前线程
           Long userId = RequestContext.getUserId(); // null
        });
        return orderRepository.findByUserId(userId);
    }
    
}



```



- **代码侵入性**：我们需要在拦截器中设置和清理ThreadLocal，如果忘记清理，可能会导致上下文错乱（因为线程池中的线程会被复用）。



## 三、TransmittableThreadLocal



- `TransmittableThreadLocal`是阿里巴巴开源的一个工具类，它继承自`InheritableThreadLocal`，并解决了在线程池中上下文传递的问题。

- `InheritableThreadLocal`可以实现在父线程创建子线程时传递`ThreadLocal`变量，但对于线程池，线程是复用的，不会每次创建新线程，因此`InheritableThreadLocal`不适用。

- `TransmittableThreadLocal`通过包装`Runnable`和`Callable`，在任务执行前将父线程的`ThreadLocal`变量复制到子线程，任务执行后再恢复。



**示例：**

#### 1、添加依赖：

```xml
<dependency>
    <groupId>com.alibaba</groupId>
    <artifactId>transmittable-thread-local</artifactId>
    <version>2.14.5</version>
</dependency>
```

#### 2、使用TransmittableThreadLocal：

```java
public class RequestContext {

    // ThreadLocal变量定义
    private static final TransmittableThreadLocal<String> TRACKER_ID_HOLDER = new TransmittableThreadLocal<>();
    // 分页
    private static final TransmittableThreadLocal<Integer> PAGE_NO_HOLDER = new TransmittableThreadLocal<>();
    private static final TransmittableThreadLocal<Integer> PAGE_SIZE_HOLDER = new TransmittableThreadLocal<>();
    // 用户token相关
    private static final TransmittableThreadLocal<String> TOKEN_HOLDER = new TransmittableThreadLocal<>();
    private static final TransmittableThreadLocal<Long> USER_ID_HOLDER = new TransmittableThreadLocal<>();

    // 默认值常量
    private static final int DEFAULT_PAGE_NO = 1;
    private static final int DEFAULT_PAGE_SIZE = 10;
    private static final int MAX_PAGE_SIZE = 1000;

    public static String getTrackerId() {
        String trackerId = TRACKER_ID_HOLDER.get();
        if (trackerId == null) {
            trackerId = IdUtil.fastSimpleUUID();
            setTrackerId(trackerId);
        }
        return trackerId;
    }

    public static void setTrackerId(String trackerId) {
        TRACKER_ID_HOLDER.set(trackerId);
    }

    //=== 分页相关方法 ===
    public static int getPageNo() {
        Integer pageNo = PAGE_NO_HOLDER.get();
        return pageNo != null && pageNo > 0 ? pageNo : DEFAULT_PAGE_NO;
    }

    public static void setPageNo(Integer pageNo) {
        if (pageNo != null && pageNo > 0) {
            PAGE_NO_HOLDER.set(pageNo);
        } else {
            PAGE_NO_HOLDER.set(DEFAULT_PAGE_NO);
        }
    }

    public static int getPageSize() {
        Integer pageSize = PAGE_SIZE_HOLDER.get();
        return pageSize != null && pageSize > 0 ? pageSize : DEFAULT_PAGE_SIZE;
    }

    public static void setPageSize(Integer pageSize) {
        if (pageSize != null && pageSize > 0) {
            // 限制最大分页大小，防止内存溢出
            int safePageSize = Math.min(pageSize, MAX_PAGE_SIZE);
            PAGE_SIZE_HOLDER.set(safePageSize);
        } else {
            PAGE_SIZE_HOLDER.set(DEFAULT_PAGE_SIZE);
        }
    }

    public static String getToken() {
        return TOKEN_HOLDER.get();
    }

    public static void setToken(String token) {
        TOKEN_HOLDER.set(token);
    }

    public static boolean hasToken() {
        return StringUtils.hasLength(getToken());
    }

    public static Long getUserId() {
        return USER_ID_HOLDER.get();
    }

    public static void setUserId(Long userId) {
        USER_ID_HOLDER.set(userId);
    }

    public static boolean hasUserId() {
        return getUserId() != null;
    }


    /**
     * 批量设置上下文参数
     */
    public static void setContext(String trackerId, Integer pageNo, Integer pageSize,
                                  String token, Long userId) {
        if (StringUtils.hasLength(trackerId)) {
            setTrackerId(trackerId);
        }
        if (pageNo != null) {
            setPageNo(pageNo);
        }
        if (pageSize != null) {
            setPageSize(pageSize);
        }
        if (StringUtils.hasLength(token)) {
            setToken(token);
        }
        if (userId != null) {
            setUserId(userId);
        }
    }

    /**
     * 从HttpServletRequest初始化上下文
     */
    public static void initFromRequest(HttpServletRequest request) {
        String trackerId = getHeaderOrParam(request, Const.HeaderKey.TRACKER_ID);
        String pageNoStr = getHeaderOrParam(request, Const.HeaderKey.PAGE_NO);
        String pageSizeStr = getHeaderOrParam(request, Const.HeaderKey.PAGE_SIZE);
        String token = getHeaderOrParam(request, Const.HeaderKey.TOKEN);
        String userIdStr = getHeaderOrParam(request, Const.HeaderKey.USER_ID);

        setContext(
                StringUtils.hasLength(trackerId) ? trackerId : IdUtil.fastSimpleUUID(),
                parsePositiveInt(pageNoStr, DEFAULT_PAGE_NO),
                parsePositiveInt(pageSizeStr, DEFAULT_PAGE_SIZE),
                token,
                parseLong(userIdStr)
        );
    }



    /**
     * 重置为默认值
     */
    public static void reset() {
        setTrackerId(IdUtil.fastSimpleUUID());
        setPageNo(DEFAULT_PAGE_NO);
        setPageSize(DEFAULT_PAGE_SIZE);
        setToken(null);
        setUserId(null);
    }

    /**
     * 清理所有ThreadLocal变量，防止内存泄漏
     */
    public static void clear() {
        TRACKER_ID_HOLDER.remove();
        PAGE_NO_HOLDER.remove();
        PAGE_SIZE_HOLDER.remove();
        TOKEN_HOLDER.remove();
        USER_ID_HOLDER.remove();
    }


    //=== 私有工具方法 ===
    private static String getHeaderOrParam(HttpServletRequest request, String key) {
        String headerValue = request.getHeader(key);
        if (StringUtils.hasLength(headerValue)) {
            return headerValue;
        }
        return request.getParameter(key);
    }

    private static Integer parsePositiveInt(String str, int defaultValue) {
        if (!StringUtils.hasLength(str) || !StrUtil.isNumeric(str)) {
            return defaultValue;
        }
        try {
            int value = Integer.parseInt(str);
            return value > 0 ? value : defaultValue;
        } catch (NumberFormatException e) {
            return defaultValue;
        }
    }

    private static Long parseLong(String str) {
        if (!StringUtils.hasLength(str) || !StrUtil.isNumeric(str)) {
            return null;
        }
        try {
            return Long.parseLong(str);
        } catch (NumberFormatException e) {
            return null;
        }
    }
}
```

- 只需要把之前的`ThreadLocal` 改为`TransmittableThreadLocal` 即可，其他不变



#### 3、在线程池中使用：

```java
// 使用线程池
ExecutorService executorService = Executors.newFixedThreadPool(10);

// 提交任务
executorService.submit(() -> {
    Long userId = RequestContext.getUserId(); // 可以获取到父线程设置的userId
    // ...
});
```

#### 4、在Spring Boot的异步任务中使用：

```java
@Configuration
public class AsyncConfig implements AsyncConfigurer {
    @Override
    public Executor getAsyncExecutor() {
        ThreadPoolTaskExecutor executor = new ThreadPoolTaskExecutor();
        executor.setCorePoolSize(10);
        executor.setMaxPoolSize(100);
        executor.setQueueCapacity(100);
        executor.initialize();
        // 使用TransmittableThreadLocal装饰异步任务
        return TtlExecutors.getTtlExecutor(executor);
    }
}
```

## 四、Scoped Values

Scoped Values是JDK 21中引入的一个新特性，它提供了一种更安全、更便捷的线程局部变量管理方式。Scoped Values与ThreadLocal类似，但它的设计目标是解决ThreadLocal的内存泄漏问题，并且更适合虚拟线程（Virtual Threads）的使用场景。

Scoped Values的主要特点：

- **不可变**：一旦绑定，在作用域内不可改变。
- **自动清理**：当作用域结束时，绑定自动解除，无需手动remove。
- **支持继承**：在创建新线程或虚拟线程时，Scoped Values可以自动继承。



简单示例：



```java
// 定义Scoped Value
private static final ScopedValue<String> USER_ID = ScopedValue.newInstance();

// 在作用域内绑定值并运行
ScopedValue.where(USER_ID, "12345")
           .run(() -> {
               // 在这个作用域内，USER_ID被绑定为"12345"
               System.out.println(USER_ID.get()); // 输出 12345
           });

// 作用域外，绑定自动解除
```





### 1、实战示例：

```java
// 1、定义ScopedValue
public class RequestContext {
    public static final ScopedValue<String> TRACKER_ID = ScopedValue.newInstance();
    public static final ScopedValue<Long> USER_ID = ScopedValue.newInstance();
}
```

#### 方案一：使用Filter

- 创建Filter

```java
@Component
public class ScopedValuesFilter implements Filter {

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {
        HttpServletRequest httpRequest = (HttpServletRequest) request;
        
        // 从请求头中获取trackerId和userId
        String trackerId = httpRequest.getHeader("trackerId");
        Long userId = getUserIdFromRequest(httpRequest); // 假设有一个方法从请求中获取userId
        
        // 如果trackerId为空，生成一个
        if (trackerId == null || trackerId.isEmpty()) {
            trackerId = generateTrackerId();
        }
        
        // 创建Scoped Values的作用域，并执行后续处理
        ScopedValue.where(RequestContext.TRACKER_ID, trackerId)
                   .where(RequestContext.USER_ID, userId)
                   .run(() -> {
                       try {
                           chain.doFilter(request, response);
                       } catch (IOException | ServletException e) {
                           throw new RuntimeException(e);
                       }
                   });
    }

    private Long getUserIdFromRequest(HttpServletRequest request) {
        // 从请求中获取userId，这里只是示例，具体逻辑根据实际情况
        String userIdHeader = request.getHeader("userId");
        return userIdHeader != null ? Long.parseLong(userIdHeader) : null;
    }

    private String generateTrackerId() {
        return UUID.randomUUID().toString();
    }
}
```



- 但是，请注意，上面的Filter中，我们使用ScopedValue.where创建了一个作用域，并在其中调用了chain.doFilter，这意味着整个请求处理（包括拦截器、控制器、服务层等）都在这个作用域内，因此这些地方都可以通过ScopedValue.get()获取到值。

  但是，如果有异步处理，比如使用了@Async，那么新线程中是否能够获取到呢？Scoped Values在创建新线程（虚拟线程）时会自动继承，但是如果是平台线程（普通线程）则不会。因此，如果使用虚拟线程，那么在新线程中也能获取到。

- 但是，注意：Spring Boot的@Async默认使用的是线程池，是平台线程。所以如果要在异步任务中获取，需要确保使用虚拟线程，或者使用其他机制。



#### 方案二：AOP



```java
/**
 * 使用AOP将Controller方法包装在Scoped Values作用域内
 */
@Aspect
@Component
@Slf4j
public class ControllerScopedValuesAspect {
    
    @Around("@annotation(org.springframework.web.bind.annotation.RequestMapping) || " +
            "@annotation(org.springframework.web.bind.annotation.GetMapping) || " +
            "@annotation(org.springframework.web.bind.annotation.PostMapping) || " +
            "@annotation(org.springframework.web.bind.annotation.PutMapping) || " +
            "@annotation(org.springframework.web.bind.annotation.DeleteMapping)")
    public Object wrapControllerWithScopedValues(ProceedingJoinPoint joinPoint) throws Throwable {
        
        // 查找HttpServletRequest参数
        HttpServletRequest request = findHttpServletRequest(joinPoint.getArgs());
        
        // 从请求头中获取trackerId和userId
        String trackerId = httpRequest.getHeader("trackerId");
        Long userId = getUserIdFromRequest(httpRequest); // 假设有一个方法从请求中获取userId
        
        // 如果trackerId为空，生成一个
        if (trackerId == null || trackerId.isEmpty()) {
            trackerId = generateTrackerId();
        }
        
        log.debug("为Controller方法创建Scoped Values作用域: {}", 
                  joinPoint.getSignature().toShortString());
         // 创建Scoped Values作用域并执行Controller方法
         return ScopedValue.where(RequestContext.TRACKER_ID, trackerId)
                   .where(RequestContext.USER_ID, userId)
                   .call(() -> {
                       try {
                          return joinPoint.proceed();
                       } catch (IOException | ServletException e) {
                           throw new RuntimeException(e);
                       }
                   });

    }
    
}
```





### 2、实战使用：


- 在业务方法中获取

```java
@Service
public class OrderService {
    
    public List<Order> getOrders() {
        // 直接从Scoped Values获取上下文信息
        String trackerId = RequestContext.TRACKER_ID.get();
        Long userId = RequestContext.USER_ID.get();
        
        System.out.println("trackerId: " + trackerId + ", userId: " + userId);
        // 使用trackerId和userId进行业务处理
        // ...
        return new ArrayList<>();
    }
}
```



- Spring Boot 为 JDK 21+ 引入的 Scoped Values 提供了初步集成，用于替代传统的 `ThreadLocal`来管理请求上下文，其对虚拟线程更友好。然而，该集成目前仍处于早期阶段，与 Spring 生态中其他组件（如数据源、事务管理）的协作尚不完善。因此，在生产环境中大规模采用仍需谨慎，当前更常见的做法仍是使用`ThreadLocal`或 `TransmittableThreadLocal`。





## 五、总结

- **ThreadLocal**：适用于简单的线程局部变量管理，但在异步场景下需要额外处理，且需注意内存泄漏。
- **TransmittableThreadLocal**：解决了线程池中ThreadLocal传递问题，适合异步场景，但需要第三方依赖。
- **Scoped Values**：JDK 21的新特性，解决了ThreadLocal的内存泄漏问题，更适合虚拟线程，但需要JDK 21及以上版本。

在实际项目中，我们可以根据具体情况选择：

- 如果项目使用JDK 21+，并且大量使用虚拟线程，可以考虑使用Scoped Values。
- 如果项目使用线程池进行异步处理，并且需要上下文传递，可以使用TransmittableThreadLocal。
- 如果只是简单的同步请求处理，使用ThreadLocal并注意清理即可。



希望这篇文章能帮助你理解从请求到Spring Boot处理过程中，线程局部变量的作用和演进。



**✨ 一个小小的邀请**

如果这篇文章帮你理清了思路，**不妨点个「关注」**。

作为一名10年经验的一线开发者兼编辑，我在这里持续分享：

- **避坑指南**：那些只有踩过才知道的技术深坑
- **架构心得**：从代码到系统的设计思考
- **效率工具**：能真正提升开发体验的“神器”



**期待在评论区，看到你的故事。** 我们一起，把代码写得更明白。