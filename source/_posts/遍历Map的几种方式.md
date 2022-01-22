---
title: 遍历Map的几种方式
date: 2017-06-05 15:06:08
updated: 2017-06-05 15:06:08
tags: [Java]
categories: Java
---
#遍历Map的几种方式
## 方法一
```java
for (String key : map.keySet()){
     System.out.println("key= "+ key + " and value= " + map.get(key));
}
```

## 方法二
```java
Iterator<Map.Entry<String, String>> it = map.entrySet().iterator();
 while (it.hasNext()) {
     Map.Entry<String, String> entry = it.next();
    System.out.println("key= " + entry.getKey() + " and value= " + entry.getValue());
}
```

## 方法三 （推荐）
```java
for (Map.Entry<String, String> entry : map.entrySet()) {
    System.out.println("key= " + entry.getKey() + " and value= " + entry.getValue());
}
```

## 方法四
```java
for (String v : map.values()) {
    System.out.println("value= " + v);
}
```

# 顺便把遍历proerties也说下，有点类似

## 初始化proerties
```java
Properties prop = new Properties();
//TODO....
```
## 方法一：
```java
Enumeration<String> eee = (Enumeration<String>) prop.propertyNames();
while (eee.hasMoreElements()) {
    String key = (String) eee.nextElement();
    String value = prop.getProperty(key);
    System.out.println("key= "+ key + " and value= " +value);
}
```

## 方法二：
```java
Enumeration<Object> enu = prop.elements();  
while (enu.hasMoreElements()) {  
    Object value = enu.nextElement();  
    System.out.println(value);  
}
````

## 方法三：
```java
Iterator<Entry<Object, Object>> it = prop.entrySet().iterator();  
while (it.hasNext()) {  
    Entry<Object, Object> entry = it.next();  
    Object key = entry.getKey();  
    Object value = entry.getValue();  
    System.out.println("key   :" + key+",value:"+value);  
}
```