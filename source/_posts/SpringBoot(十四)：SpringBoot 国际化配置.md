---
title: SpringBoot(十四)：SpringBoot 国际化配置
date: 2018-07-26 18:31:20
updated: 2018-07-26 18:31:20
tags: [Spring Boot]
categories: Java
---
# SpringBoot 国际化配置

## 一、配置LocaleResolver
```java
@Configuration
public class LocaleConfig extends WebMvcConfigurerAdapter{

	@Bean
    public LocaleResolver localeResolver() {
        SessionLocaleResolver slr = new SessionLocaleResolver();
        // 默认语言
        slr.setDefaultLocale(Locale.CHINA);
        return slr;
    }
 
    @Bean
    public LocaleChangeInterceptor localeChangeInterceptor() {
        LocaleChangeInterceptor lci = new LocaleChangeInterceptor();
        // 参数名
        lci.setParamName("lang");
        return lci;
    }
 
    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        registry.addInterceptor(localeChangeInterceptor());
        super.addInterceptors(registry);
    }

}
```

<!--more-->


## 二、创建国际化文件
```
messages.properties
messages_zh_CN.properties
messages_en_US.properties
messages_ja_JP.properties
...


内容如下：
top.lrshuai.text=简体
top.lrshuai.name=帅哥
top.lrshuai.age=20
message=国际化


```

## 三、配置国际化文件路径
在application.yml 配置国际化文件所在位置
```
spring:
    messages:
        encoding: UTF-8  
        cache-seconds: 1  
        basename: static/i18n/messages
```

## 四、前端页面调用国际化
在Thymeleaf模板中通过 `th:text`与`#{国际化文件的KEY}` 即可使用国际化   
前端需要传的语言参数为`lang`示例如下：
```html
<body>
	<div class="language">
	<div th:switch="${#locale.getCountry()}">
		<span th:case="'CN'" >简体中文</span>
		<span th:case="'TW'" >繁體中文</span>
		<span th:case="'US'" >English</span>
		<span th:case="'JP'" >日语</span>
		<span th:case="'KR'" >韩语</span>
	</div>
        <ul class="langBody">
            <li><a href="?lang=zh_CN">简体中文</a></li>
            <li><a href="?lang=zh_TW">繁體中文</a></li>
            <li><a href="?lang=en_US">English</a></li>
            <li><a href="?lang=ja_JP">日语</a></li>
            <li><a href="?lang=ko_KR">韩语</a></li>
        </ul>
	</div>
	<div class="language">
		<div th:text="#{top.lrshuai.text}">asdfSW</div>
		<div th:text="#{top.lrshuai.name}">asdf</div>
		<div th:text="#{top.lrshuai.age}">asdf</div>
		<span th:text="#{message}">ffff</span><br/>
	</div>
</body>
```

## 五、接口返回值国际化 
通过前端传上来的语言，我们接口返回值需要通过转上来的语言，返回对应的数据。
在Spring中,我们只需要实现`ResponseBodyAdvice<T>` 接口即可，代码如下
```java
/**
* 别忘了加注解，basePackages 是对哪些包进行扫描
*/
@ControllerAdvice(basePackages={"top.lrshuai.controller"})
public class I18nResponseAdvice implements ResponseBodyAdvice<Object> {

	protected Logger log = LoggerFactory.getLogger(this.getClass());

	@Override
	public boolean supports(MethodParameter returnType,
			Class<? extends HttpMessageConverter<?>> converterType) {
		return true;
	}

	/**
	*这个方法获取到返回数据，对其进行拦截修改即可
	*/
	@Override
	public Object beforeBodyWrite(Object body, MethodParameter returnType,
			MediaType selectedContentType,
			Class<? extends HttpMessageConverter<?>> selectedConverterType,
			ServerHttpRequest request, ServerHttpResponse response) {
		try {
			//body 就是返回的数据体
			HttpServletRequest req = ((ServletRequestAttributes)RequestContextHolder.getRequestAttributes()).getRequest();
			String value = getMessage(req, "name");
			//TODO
			
			
		} catch (Exception e) {
			e.printStackTrace();
			log.error("返回值国际化拦截异常",e);
		}
		return body;
	}
	
	/**
	 * 返回国际化的值
	 * @param request
	 * @param key
	 * @return
	 */
	public String getMessage(HttpServletRequest request, String key){
        RequestContext requestContext = new RequestContext(request);
        String value = requestContext.getMessage(key);
        return value;
    }

}
```
在上面的代码中 `getMessage(HttpServletRequest request, String key)` 就是获取国际化的值，通过`key` 获取对应国际化的文件值
### 代码地址
+ Github地址:[https://github.com/rstyro/spring-boot/tree/master/SpringBoot-i18n](https://github.com/rstyro/spring-boot/tree/master/SpringBoot-i18n)
+ Gitee地址:[https://gitee.com/rstyro/spring-boot/tree/master/SpringBoot-i18n](https://gitee.com/rstyro/spring-boot/tree/master/SpringBoot-i18n)
