---
title: SpringCloud （九）、Zuul 回退
date: 2018-05-27 12:41:48
tags: [SpringCloud]
categories: Java
---
## 一、Zuul 的回退
Zuul 本身就有断路器的功能
很简单只需自定义一个`ZuulFallbackProvider`即可，在实现这个ZuulFallbackProvider的`getRoute()`方法中定义你的服务名称。下面是简单的示例
我这个是`producer`这个微服务的fallback
```java
@Component
public class MyFallbackProvider implements ZuulFallbackProvider {

	/**
	 * 这个是你要配置的是那个微服务
	 */
	@Override
	public String getRoute() {
		return "producer";
	}

	/**
	 * 这个是服务器端返回的数据体，
	 * 可以自己定义重写
	 */
	@Override
	public ClientHttpResponse fallbackResponse() {
		return new ClientHttpResponse() {
			@Override
			public HttpStatus getStatusCode() throws IOException {
				return HttpStatus.OK;
			}

			@Override
			public int getRawStatusCode() throws IOException {
				return 200;
			}

			@Override
			public String getStatusText() throws IOException {
				return "OK";
			}

			@Override
			public void close() {

			}

			/**
			 * fallback 返回的信息
			 */
			@Override
			public InputStream getBody() throws IOException {
				return new ByteArrayInputStream("这个就是当服务掉掉的时候，返回的是这个数据".getBytes("utf-8"));
			}

			@Override
			public HttpHeaders getHeaders() {
				HttpHeaders headers = new HttpHeaders();
				headers.setContentType(MediaType.APPLICATION_JSON);
				return headers;
			}
		};
	}

}
```

我上面这个是`Dalston.SR5` 版本的，为什么用这个版本，刚学的时候，感觉这个版本名称比较亲切不知道为啥。

如果 Edgware及更高版本的话，回退是这样的
`FallbackProvider`是`ZuulFallbackProvider`的子接口。
`ZuulFallbackProvider`已经被标注`Deprecated `，很可能在未来的版本中被删除。
`FallbackProvider`接口比`ZuulFallbackProvider`多了一个`ClientHttpResponse fallbackResponse(Throwable cause)`方法，使用该方法，可获得造成回退的原因

```java
@Component
public class MyFallbackProvider implements FallbackProvider {
  @Override
  public String getRoute() {
    // 表明是为哪个微服务提供回退，*表示为所有微服务提供回退
    return "*";
  }
  @Override
  public ClientHttpResponse fallbackResponse(Throwable cause) {
    if (cause instanceof HystrixTimeoutException) {
      return response(HttpStatus.GATEWAY_TIMEOUT);
    } else {
      return this.fallbackResponse();
    }
  }
  @Override
  public ClientHttpResponse fallbackResponse() {
    return this.response(HttpStatus.INTERNAL_SERVER_ERROR);
  }
  private ClientHttpResponse response(final HttpStatus status) {
    return new ClientHttpResponse() {
      @Override
      public HttpStatus getStatusCode() throws IOException {
        return status;
      }
      @Override
      public int getRawStatusCode() throws IOException {
        return status.value();
      }
      @Override
      public String getStatusText() throws IOException {
        return status.getReasonPhrase();
      }
      @Override
      public void close() {
      }
      @Override
      public InputStream getBody() throws IOException {
        return new ByteArrayInputStream("服务不可用，请稍后再试。".getBytes());
      }
      @Override
      public HttpHeaders getHeaders() {
        // headers设定
        HttpHeaders headers = new HttpHeaders();
        MediaType mt = new MediaType("application", "json", Charset.forName("UTF-8"));
        headers.setContentType(mt);
        return headers;
      }
    };
  }
}
```
##### 完整的[Github代码地址](https://github.com/rstyro/SpringCloud/tree/master/SpringCloud-zuul-fallback)

