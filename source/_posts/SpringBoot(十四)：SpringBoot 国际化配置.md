---
title: SpringBoot(十四)：SpringBoot 国际化配置
date: 2018-07-26 18:31:20
tags: [Spring Boot]
categories: Java
---
# SpringBoot 国际化配置

## 一、配置LocaleResolver
```
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

## 四、前端调用
```
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

## 五、对`@ResponseBody` 接口返回值拦截
##### 有一种需求就是对接口的返回值进行拦截,我们需要实现`ResponseBodyAdvice<T>` 接口，代码如下
```
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
## [Github地址](https://github.com/rstyro/spring-boot/tree/master/SpringBoot-i18n)