---
title: Springboot自定义参数校验注解
date: 2021-05-19 18:12:32
updated: 2021-05-19 18:12:32
tags: [Spring Boot]
categories: Java
---
### 前言
+ 日常开发中，一般都会有参数校验，判空校验是最常见的。
+ 如果每个接口都写一大推重复的校验，代码不够简洁且复用不强
+ 所以可以使用`hibernate-validator`通过注解校验。

### 一、快速开始
+ 本文以Springboot项目为例

#### 1、导入依赖
```
<dependency>
	<groupId>org.springframework.boot</groupId>
	<artifactId>spring-boot-starter-validation</artifactId>
</dependency>
```
<!--more-->
+ 引入上面的依赖，springboot的配置类：`ValidationAutoConfiguration` 会自动帮我们配置。


#### 2、校验注解详解
+ 常见注解：

|注解 <div style="width:150px;"></div>|支持的类型|描述说明|
|--|--|--|
|`@AssertFalse`|Boolean, boolean|检查带注释的元素是否为false|
|`@AssertTrue`|Boolean, boolean|检查带注释的元素是否为true|
|`@DecimalMax`|BigDecimal, BigInteger, CharSequence, byte, short, int, long|当`inclusive = false`时，检查带注释的值是否小于指定的最大值。否则，该值是否小于或等于指定的最大值。|
|`@DecimalMin`|BigDecimal, BigInteger, CharSequence, byte, short, int, long|当`inclusive = false`时，检查带注释的值是否大于指定的最小值。否则，该值是否大于或等于指定的最小值。|
|`@Digits`|BigInteger, CharSequence, byte, short, int, long|检查带注释的值是否是一个最多包含整数位数和小数位数的数字|
|`@Email`|BigInteger, CharSequence, byte, short, int, long|检查指定的字符序列是否为有效的电子邮件地址。可选参数regexp和flags允许指定电子邮件必须匹配的其他正则表达式|
|`@Min`|BigInteger, CharSequence, byte, short, int, long|检查带注释的值是否大于或等于指定的最小值|
|`@Max`|BigInteger, CharSequence, byte, short, int, long|检查带注释的值是否小于或等于指定的最大值|
|`@NotBlank`|CharSequence|检查带注释的字符序列不为null，并且修剪的长度大于0。与`@NotEmpty`的区别在于，此约束只能应用于字符序列|
|`@NotEmpty`|CharSequence，Collection，Map和数组|检查带注释的元素是否不为null或为空|
|`@NotNull`|任何类型|检查注释的值是否不是 null|
|`@Negative`|BigDecimal，BigInteger，byte，short，int，long|检查元素是否为负数。|
|`@NegativeOrZero`|BigDecimal，BigInteger，byte，short，int，long|检查元素是不是小于等于0。|
|`@Null`|任何类型|检查注释的值是 null|
|`@Size`|CharSequence，Collection，Map和数组|检查带注释的元素的大小是否介于min和之间max（包括）|


> 详细参考文档：[https://docs.jboss.org/hibernate/validator/6.2/reference/en-US/html_single/#validator-defineconstraints-spec](https://docs.jboss.org/hibernate/validator/6.2/reference/en-US/html_single/#validator-defineconstraints-spec)


#### 3、使用方式
+ 新建一个controller类，如下

```
@Validated
@RestController
public class TestController {

    @GetMapping("/get")
    public String getUser(@NotNull(message = "name 不能为空") String name, @Max(value = 100, message = "age不能大于100岁") Integer age) {
        return "name: " + name + " ,age:" + age;
    }

    @PostMapping("/test")
    public Object test(@RequestBody @Valid TestDto dto){
        System.out.println("dto="+dto.toString());
        return "ok";
    }
}


@Data
@Accessors(chain = true)
public class TestDto {

    @NotBlank(message = "name不能为空")
    private String name;

    @NotNull(message = "age 不能为空")
    @Min(value = 1,message = "age最小是1")
    @Max(value = 200,message = "age最大为200")
    private Integer age;
}
```

+ 在类上面使用：`@Validated` 注解。
+ 如果是Get请求，在方法参数上使用校验注解。
+ 如果是`@RequestBody`方式，可在参数上使用`@Valid`注解。

#### 4、自定义全局异常
+ 因为报错不太雅观，我们自定义全局异常捕获
+ 如下：

```
/**
 * 描述：全局统一异常处理

 */
@Slf4j
@RestControllerAdvice
public class GlobalExceptionHandlerAdvice {

    /**
     * 参数验证异常
     */
    @ExceptionHandler(value = {MethodArgumentNotValidException.class})
    public Result handleMethodArgumentNotValidException(MethodArgumentNotValidException e) {
        String errorMsg =  e.getBindingResult().getFieldError().getDefaultMessage();
        if (!StringUtils.isEmpty(errorMsg)) {
            return Result.error(errorMsg);
        }
        log.error(e.getMessage(),e);
        return Result.error(e.getMessage());
    }

    /**
     * 参数验证异常
     */
    @ExceptionHandler(value = {ValidationException.class})
    public Result constraintViolationException(ValidationException e) {
        if(e instanceof ConstraintViolationException){
            ConstraintViolationException err = (ConstraintViolationException) e;
            ConstraintViolation<?> constraintViolation = err.getConstraintViolations().stream().findFirst().get();
            String messageTemplate = constraintViolation.getMessageTemplate();
            if(!StringUtils.isEmpty(messageTemplate)){
                return Result.error(messageTemplate);
            }
        }
        log.error(e.getMessage(),e);
        return Result.error(e.getMessage());
    }

    /**
     * 默认异常
     */
    @ExceptionHandler(value = Exception.class)
    public Result defaultException(Exception e) {
        log.error("系统异常:" + e.getMessage(), e);
        return Result.error();
    }

}
```

+ 使用`@RestControllerAdvice`注解，和`@ExceptionHandler`注解实现，异常统一处理

### 二、自定义参数校验注解
+ 本文的重点，默认的注解，可能没能符合我们的业务需要。
+ 比如，有个字段性别（sex），它只能是`男`或者`女`，我们可以自定义注解来判断传上来的参数是否符合

#### 1、新建自定义注解
```
/**
 * 自定义校验注解
 */
@Target({ElementType.METHOD, ElementType.FIELD, ElementType.ANNOTATION_TYPE,
        ElementType.CONSTRUCTOR, ElementType.PARAMETER})
@Retention(RetentionPolicy.RUNTIME)
@Documented
// 指定此注解的实现，即:验证器
@Constraint(validatedBy = MatchValidator.class)
public @interface MatchValue {

    /**
     * 固定的值校验
     */
    String[] values() default {};

    /**
     * 校验不通过提示
     */
    String message() default "";

    /**
     * 通过枚举类校验
     */
    Class<? extends Enum>[] enums() default {};

    Class<?>[] groups() default {};

    Class<? extends Payload>[] payload() default {};
}
```

+ `values()` 代表它可以为的值
+ `enums()` 代表它可以是一个枚举
+ 新建注解之后，还要为他创建一个验证器的类

```
/**
 * 自定义验证器
 */
public class MatchValidator implements ConstraintValidator<MatchValue, String> {

    /**
     * 接收注解传过来的值
     */
    private Set<String> enumName=new HashSet<>();

    /**
     * 初始化方法，可以获取注解的参数信息
     */
    @Override
    public void initialize(MatchValue matchValue) {
        try {
            String[] values = matchValue.values();
            if(values.length>0){
                for (String item:values){
                    enumName.add(item);
                }
            }
            Class<?extends Enum>[] enums = matchValue.enums();
            if(enums.length>0){
                Enum[] enumConstants = Arrays.stream(enums).findFirst().get().getEnumConstants();
                for (Enum e:enumConstants){
                    enumName.add(e.name());
                }
            }
        }catch (Throwable e){
            e.printStackTrace();
        }

    }

    /**
     * 校验值
     * @param value 参数的值信息
     * @param context 上下文对象，可以禁用默认提示模板，然后更改提示模板
     * @return boolean
     */
    @Override
    public boolean isValid(String value, ConstraintValidatorContext context) {
        if(!StringUtils.isEmpty(value)){
            for(String name:enumName){
                if(name.equals(value)){
                    return true;
                }
            }
            return false;
        }
        return true;
    }
}
```

+ 需要实现 `ConstraintValidator` 的接口
+ 重新`isValid()`方法即可，返回false代表失败，会提示message里面的内容
+ `initialize()` 方法可以初始化一些值，比如拿到注解上的值信息。

#### 2、使用方法
+ 和其他的注解使用方式一致，如下：

```
@Data
@Accessors(chain = true)
public class TestDto {

// 自定义注解 哪种都可以
//    @MatchValue(values = {"男","女"},message = "sex参数无效")
    @MatchValue(enums = SexEnum.class,message = "sex参数无效")
    private String sex;

}


public enum SexEnum {
    男, 女 ;
}
```


#### 3、完整代码
+ 完整的示例代码：
+ Github:[https://github.com/rstyro/Springboot/tree/master/springboot-validator](https://github.com/rstyro/Springboot/tree/master/springboot-validator)
+ Gitee: [https://gitee.com/rstyro/spring-boot/tree/master/springboot-validator](https://gitee.com/rstyro/spring-boot/tree/master/springboot-validator)
