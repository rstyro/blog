---
title: Api接口防刷
date: 2019-04-15 14:48:01
tags: [Spring Boot, Java]
categories: Java
---

# API 接口防刷
顾名思义，想让某个接口某个人在某段时间内只能请求N次。  
在项目中比较常见的问题也有，那就是连点按钮导致请求多次，以前在web端有表单重复提交，可以通过token 来解决。  
除了上面的方法外，前后端配合的方法。现在全部由后端来控制。
## 原理
在你请求的时候，服务器通过redis 记录下你请求的次数，如果次数超过限制就不给访问。   
在redis 保存的key 是有时效性的，过期就会删除。

## 代码实现：
为了让它看起来逼格高一点，所以以自定义注解的方式实现  

### `@RequestLimit` 注解
```java
import java.lang.annotation.*;

/**
 * 请求限制的自定义注解
 *
 * @Target 注解可修饰的对象范围，ElementType.METHOD 作用于方法，ElementType.TYPE 作用于类
 * (ElementType)取值有：
 * 　　　　1.CONSTRUCTOR:用于描述构造器
 * 　　　　2.FIELD:用于描述域
 * 　　　　3.LOCAL_VARIABLE:用于描述局部变量
 * 　　　　4.METHOD:用于描述方法
 * 　　　　5.PACKAGE:用于描述包
 * 　　　　6.PARAMETER:用于描述参数
 * 　　　　7.TYPE:用于描述类、接口(包括注解类型) 或enum声明
 * @Retention定义了该Annotation被保留的时间长短：某些Annotation仅出现在源代码中，而被编译器丢弃；
 * 而另一些却被编译在class文件中；编译在class文件中的Annotation可能会被虚拟机忽略，
 * 而另一些在class被装载时将被读取（请注意并不影响class的执行，因为Annotation与class在使用上是被分离的）。
 * 使用这个meta-Annotation可以对 Annotation的“生命周期”限制。
 * （RetentionPoicy）取值有：
 * 　　　　1.SOURCE:在源文件中有效（即源文件保留）
 * 　　　　2.CLASS:在class文件中有效（即class保留）
 * 　　　　3.RUNTIME:在运行时有效（即运行时保留）
 *
 * @Inherited
 * 元注解是一个标记注解，@Inherited阐述了某个被标注的类型是被继承的。
 * 如果一个使用了@Inherited修饰的annotation类型被用于一个class，则这个annotation将被用于该class的子类。
 */
@Documented
@Inherited
@Target({ElementType.METHOD,ElementType.TYPE})
@Retention(RetentionPolicy.RUNTIME)
public @interface RequestLimit {
    // 在 second 秒内，最大只能请求 maxCount 次
    int second() default 1;
    int maxCount() default 1;
}

```

### `RequestLimitIntercept` 拦截器
自定义一个拦截器，请求之前，进行请求次数校验
```java
import com.alibaba.fastjson.JSONObject;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Component;
import org.springframework.web.method.HandlerMethod;
import org.springframework.web.servlet.handler.HandlerInterceptorAdapter;
import top.lrshuai.limit.annotation.RequestLimit;
import top.lrshuai.limit.common.ApiResultEnum;
import top.lrshuai.limit.common.Result;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.io.PrintWriter;
import java.lang.reflect.Method;
import java.util.concurrent.TimeUnit;

/**
 * 请求拦截
 */
@Slf4j
@Component
public class RequestLimitIntercept extends HandlerInterceptorAdapter {

    @Autowired
    private RedisTemplate<String,Object> redisTemplate;

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) throws Exception {
        /**
         * isAssignableFrom() 判定此 Class 对象所表示的类或接口与指定的 Class 参数所表示的类或接口是否相同，或是否是其超类或超接口
         * isAssignableFrom()方法是判断是否为某个类的父类
         * instanceof关键字是判断是否某个类的子类
         */
        if(handler.getClass().isAssignableFrom(HandlerMethod.class)){
            //HandlerMethod 封装方法定义相关的信息,如类,方法,参数等
            HandlerMethod handlerMethod = (HandlerMethod) handler;
            Method method = handlerMethod.getMethod();
            // 获取方法中是否包含注解
            RequestLimit methodAnnotation = method.getAnnotation(RequestLimit.class);
            //获取 类中是否包含注解，也就是controller 是否有注解
            RequestLimit classAnnotation = method.getDeclaringClass().getAnnotation(RequestLimit.class);
            // 如果 方法上有注解就优先选择方法上的参数，否则类上的参数
            RequestLimit requestLimit = methodAnnotation != null?methodAnnotation:classAnnotation;
            if(requestLimit != null){
                if(isLimit(request,requestLimit)){
                    resonseOut(response,Result.error(ApiResultEnum.REQUST_LIMIT));
                    return false;
                }
            }
        }
        return super.preHandle(request, response, handler);
    }
    //判断请求是否受限
    public boolean isLimit(HttpServletRequest request,RequestLimit requestLimit){
        // 受限的redis 缓存key ,因为这里用浏览器做测试，我就用sessionid 来做唯一key,如果是app ,可以使用 用户ID 之类的唯一标识。
        String limitKey = request.getServletPath()+request.getSession().getId();
        // 从缓存中获取，当前这个请求访问了几次
        Integer redisCount = (Integer) redisTemplate.opsForValue().get(limitKey);
        if(redisCount == null){
            //初始 次数
            redisTemplate.opsForValue().set(limitKey,1,requestLimit.second(), TimeUnit.SECONDS);
        }else{
            if(redisCount.intValue() >= requestLimit.maxCount()){
                return true;
            }
            // 次数自增
            redisTemplate.opsForValue().increment(limitKey);
        }
        return false;
    }

    /**
     * 回写给客户端
     * @param response
     * @param result
     * @throws IOException
     */
    private void resonseOut(HttpServletResponse response, Result result) throws IOException {
        response.setCharacterEncoding("UTF-8");
        response.setContentType("application/json; charset=utf-8");
        PrintWriter out = null ;
        String json = JSONObject.toJSON(result).toString();
        out = response.getWriter();
        out.append(json);
    }
}
```
拦截器写好了，但是还得添加注册

### `WebMvcConfig` 配置类
因为我的是`Springboot2.*` 所以只需实现`WebMvcConfigurer` 
如果是`springboot1.*` 那就继承自 `WebMvcConfigurerAdapter`  
然后重写`addInterceptors()` 添加自定义拦截器即可。

```java
@Slf4j
@Component
public class WebMvcConfig implements WebMvcConfigurer {

    @Autowired
    private RequestLimitIntercept requestLimitIntercept;

    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        log.info("添加拦截");
        registry.addInterceptor(requestLimitIntercept);
    }
}
```

### `Controller`
控制层测试接口，
##### 使用方式：  
+ 第一种：直接在类上使用注解`@RequestLimit(maxCount = 5,second = 1)`  
+ 第二种：在方法上使用注解`@RequestLimit(maxCount = 5,second = 1)`    

> maxCount 最大的请求数、second 代表时间，单位是秒  

默认1秒内，每个接口只能请求一次
```java
@RestController
@RequestMapping("/index")
@RequestLimit(maxCount = 5,second = 1)
public class IndexController {

    /**
     * @RequestLimit 修饰在方法上，优先使用其参数
     * @return
     */
    @GetMapping("/test1")
    @RequestLimit
    public Result test(){
        //TODO ...
        return Result.ok();
    }

    /**
     * @RequestLimit 修饰在类上，用的是类的参数
     * @return
     */
    @GetMapping("/test2")
    public Result test2(){
        //TODO ...
        return Result.ok();
    }
}
```

如果在类和方法上同时有`@RequestLimit`注解 ,以方法上的参数为准，好像注释有点多了。

## 代码地址
完整的代码，如下地址
#### Gitee地址：[https://gitee.com/rstyro/spring-boot/tree/master/SpringBoot-limit](https://gitee.com/rstyro/spring-boot/tree/master/SpringBoot-limit)
#### Github地址：[https://github.com/rstyro/Springboot/tree/master/SpringBoot-limit](https://github.com/rstyro/Springboot/tree/master/SpringBoot-limit)

