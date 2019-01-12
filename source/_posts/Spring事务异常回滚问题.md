---
title: Spring事务异常回滚问题
date: 2017-09-26 15:26:09
tags: [Spring, Java]
categories: Java
---
# Spring  try...catch 捕获异常不抛出就不会回滚

## 比如:第一个删除成功了，第二个失败。事务不回滚
```
try {
    roleDao.delRole(roleId);
    int i = 1/0;
    roleDao.delUserRole(roleId);
} catch (Exception e) {
    e.printStackTrace();
    log.error("del role error", e);
}
```
### 解决方法：
#### 第一种：主动抛出RuntimeException
```
try {
    roleDao.delRole(roleId);
    int i = 1/0;
    roleDao.delUserRole(roleId);
} catch (Exception e) {
    e.printStackTrace();
    log.error("del role error", e);
     
    throw new RuntimeException();
}
```
#### 第二种：手动回滚（推荐做法）
```
try {
    roleDao.delRole(roleId);
    int i = 1/0;
    roleDao.delUserRole(roleId);
} catch (Exception e) {
    e.printStackTrace();
    log.error("del role error", e);
    TransactionAspectSupport.currentTransactionStatus().setRollbackOnly();
}
```

## spring aop  异常捕获原理：
### 被拦截的方法需显式抛出异常，并不能经任何处理，这样aop代理才能捕获到方法的异常，才能进行回滚，默认情况下aop只捕获runtimeexception的异常，但可以通过