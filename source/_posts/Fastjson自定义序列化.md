---
title: Fastjson自定义序列化
date: 2021-05-11 14:48:47
updated: 2021-05-11 14:48:47
tags: [Fastjson]
categories: Java
---
## 一、Fastjson自定义序列化
通过SerializeFilter可以使用扩展编程的方式实现定制序列化。fastjson提供了多种SerializeFilter：
+ **PropertyPreFilter**	 
根据PropertyName判断是否序列化
+ **PropertyFilter**	 
根据PropertyName和PropertyValue来判断是否序列化
+ **NameFilter**	 
修改Key，如果需要修改Key,process返回值则可
+ **ValueFilter**	 
修改Value
+ **BeforeFilter**	 
序列化时在最前添加内容
+ **AfterFilter**	 
序列化时在最后添加内容

## 二、导入依赖
+ 导入pom依赖
```
<dependency>
    <groupId>com.alibaba</groupId>
    <artifactId>fastjson</artifactId>
    <version>1.2.76</version>
</dependency>
```

## 三、序列化示例
+ 例子
+ 代码

```java
@Data
@Accessors(chain = true)
public class Demo {
    private Long id;
    private String userName;
    private Integer age;
    private String introduce;
    private String test;
}
```

#### 1、PropertyPreFilter
+ 根据PropertyName判断是否序列化
+ 只根据object和name进行判断，在调用getter之前，这样避免了getter调用可能存在的异常。
+ demo如下：

```java
public static void main(String[] args){
	Demo obj = new Demo().setId(1l).setAge(28).setUserName("rstyro").setIntroduce("世界上最帅的男人");
	PropertyPreFilter propertyPreFilter=new PropertyPreFilter() {
		@Override
		public boolean apply(JSONSerializer serializer, Object object, String name) {
			if ("userName".equals(name)) {
				// true则序列化
			   return true;
			}
			// 不序列化
			return false;
		}
	};
	// 使用propertyPreFilter
	System.out.println("json="+JSON.toJSONString(obj, propertyPreFilter)); 
}

// 打印结果：json={"userName":"rstyro"}
```

+ 只有userName返回true,所以只序列化 userName

#### 2、PropertyFilter
+ 根据PropertyName和PropertyValue来判断是否序列化

```java
public static void main(String[] args){
	Demo obj = new Demo().setId(1l).setAge(28).setUserName("rstyro").setIntroduce("世界上最帅的男人");
	PropertyFilter propertyFilter = new PropertyFilter() {
		public boolean apply(Object source, String name, Object value) {
			if ("id".equals(name)) {
			   // 如果key 为 id,则不序列
				return false;
			}
			if ("age".equals(name)) {
				// 如果key 为 age,且age <18 则不序列
				int age = ((Integer) value).intValue();
				return age<18;
			}
			// true 则序列化
			return true;
		}
	};
	System.out.println("json="+JSON.toJSONString(obj, propertyFilter));
}

// 打印结果：json={"introduce":"世界上最帅的男人","userName":"rstyro"}
```

+ id不序列化，age小于18不序列化

#### 3、NameFilter
+ 修改Key，如果需要修改Key,process返回值则可

```java
public static void main(String[] args){
	Demo obj = new Demo().setId(1l).setAge(28).setUserName("rstyro").setIntroduce("世界上最帅的男人");
	NameFilter nameFilter = new NameFilter() {
		@Override
		public String process(Object object, String name, Object value) {
			return name.toLowerCase();
		}
	};
	System.out.println("json="+JSON.toJSONString(obj,nameFilter));
}

// 打印结果：
// json={"age":28,"id":1,"introduce":"世界上最帅的男人","username":"rstyro"}
```

+ 注意看，userName，已经变成小写，这个时修改key的，key全部转小写

#### 4、ValueFilter
+ 修改Value

```java
public static void main(String[] args){
	Demo obj = new Demo().setId(1l).setAge(28).setUserName("rstyro").setIntroduce("世界上最帅的男人");
	ValueFilter valueFilter = new ValueFilter() {
		@Override
		public Object process(Object object, String name, Object value) {
			if ("age".equals(name)) {
				return 18;
			}
			return value;
		}
	};
	System.out.println("json="+JSON.toJSONString(obj,valueFilter));
}

// 打印结果：
// json={"age":18,"id":1,"introduce":"世界上最帅的男人","userName":"rstyro"}
```

+ 修改age为18

#### 5、BeforeFilter
+ 序列化时在最前添加内容

```java
public static void main(String[] args){
	Demo obj = new Demo().setId(1l).setAge(28).setUserName("rstyro").setIntroduce("世界上最帅的男人");
	BeforeFilter beforeFilter = new BeforeFilter() {
		@Override
		public void writeBefore(Object object) {
			if(object instanceof Demo){
				Demo demoBefore = (Demo) object;
				demoBefore.setAge(18);
				demoBefore.setIntroduce("序列化之前修改介绍");

			}
		}
	};
	System.out.println("json="+JSON.toJSONString(obj));
	System.out.println("json="+JSON.toJSONString(obj,beforeFilter));
	
}

// 打印结果：
// json={"age":18,"id":1,"introduce":"世界上最帅的男人","userName":"rstyro"}
// json={"age":18,"id":1,"introduce":"序列化之前修改介绍","userName":"rstyro"}
```

#### 6、AfterFilter
+ 序列化时在最后添加内容

```java
public static void main(String[] args){
	Demo obj = new Demo().setId(1l).setAge(28).setUserName("rstyro").setIntroduce("世界上最帅的男人");
	AfterFilter afterFilter = new AfterFilter() {
		@Override
		public void writeAfter(Object object) {
			if(object instanceof Demo){
				Demo demoBefore = (Demo) object;
				demoBefore.setAge(18);
				demoBefore.setIntroduce("序列化之后修改介绍");
				demoBefore.setTest("序列化之后设置");
			}
		}
	};
	System.out.println("json="+JSON.toJSONString(obj,afterFilter));
	System.out.println("json="+JSON.toJSONString(obj));
	
}

// 打印结果：
// json={"age":18,"id":1,"introduce":"序列化之前修改介绍","userName":"rstyro"}
// json={"age":18,"id":1,"introduce":"序列化之后修改介绍","test":"序列化之后设置","userName":"rstyro"}
```

## 四、注解的方式序列化

+ 通过`@JSONField`定制序列化
+ 通过`@JSONType`定制序列化
+ 通过`SerializeFilter`定制序列化
+ 通过`ParseProcess`定制反序列化

### 例子1
+ 在属性上使用注解

```java
public class VO {
	  @JSONField(name="ID")
	  private int id;

	  @JSONField(name="birthday",format="yyyy-MM-dd")
	  public Date date;
 }
```


### 例子2
+ 使用serialize/deserialize指定字段不序列化

```java
public class A {
      @JSONField(serialize=false)
      public Date date;
 }

 public class A {
      @JSONField(deserialize=false)
      public Date date;
 }
```

### 例子3
+ 使用serializeUsing制定属性的序列化类
+ 在fastjson 1.2.16版本之后，JSONField支持新的定制化配置serializeUsing，可以单独对某一个类的某个属性定制序列化，比如：

```java
public static class Model {
    @JSONField(serializeUsing = ModelValueSerializer.class)
    public int value;
}

public static class ModelValueSerializer implements ObjectSerializer {
    @Override
    public void write(JSONSerializer serializer, Object object, Object fieldName, Type fieldType,
                      int features) throws IOException {
        Integer value = (Integer) object;
        String text = value + "元";
        serializer.write(text);
    }
}
```

+ 测试代码：

```java
Model model = new Model();
model.value = 100;
String json = JSON.toJSONString(model);
Assert.assertEquals("{\"value\":\"100元\"}", json);
```


### 参考链接：[官方WIKI](https://github.com/alibaba/fastjson/wiki/Quick-Start-CN)