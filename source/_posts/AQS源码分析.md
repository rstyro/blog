---
title: AQS源码分析
date: 2020-08-21 18:00:29
tags: [多线程]
categories: Java
---
### 一、AQS是什么
AQS(AbstractQueuedSynchronizer):顾名思义是一个抽象队列同步器。在JDK5 之后的 `java.util.concurrent` 下的的很多常用的多线程工具类都依赖这个类。
面试常考的点，也是学习多线程必掌握的知识点。
看JDK源码注释说，AQS是基于CLH自旋锁变种的一个虚拟的双向队列，而队列一般都是先进先出(First Input First Output)。
>CLH是一种基于链表的可扩展、高性能、公平的自旋锁，申请线程只在本地变量上自旋，它不断轮询前驱的状态，如果发现前驱释放了锁就结束自旋。
> 大概长下面这样子：
      +------+  prev +-----+       +-----+
 head |      | <---- |     | <---- |     |  tail
      +------+       +-----+       +-----+

直白点说AQS就是一个框架，具体资源的获取/释放方式交由我们自定义同步器去实现。AQS定义两种资源共享方式：Exclusive 独占资源（ReentrantLock）、Share 共享资源（Semaphore/CountDownLatch）
框架的两大核心：同步等待队列和条件等待队列。虽然有两个队列，但我们不一定都用得到，所以它的获取/释放方法没有定义成`abstract`。自定义同步器在实现时只需要实现共享资源 state的获取与释放方式即可，至于具体线程等待队列的维护（如获取资源失败入队/
唤醒出队等），AQS 已经在顶层实现好了。

我们自定义的同步器主要实现一下方法：
+ 1．isHeldExclusively()：
该线程是否正在独占资源。只有用到 condition 才需要去实现它。
+ 2．tryAcquire(int)：
独占方式。尝试获取资源，成功则返回 true，失败则返回 false。 
+ 3．tryRelease(int)：
独占方式。尝试释放资源，成功则返回 true，失败则返回 false。 
+ 4．tryAcquireShared(int)：
共享方式。尝试获取资源。负数表示失败；0 表示成功，但没有剩余可用资源；正数表示成功，且有剩余资源。
+ 5．tryReleaseShared(int)：
共享方式。尝试释放资源，如果释放后允许唤醒后续等待结点返回true，否则返回 false。

### 二、AQS之队列同步器
+ 队列同步器大致的运行过程：
当线程去请求的共享资源空闲就把当前请求线程设为工作线程并把状态标记为锁定状态。如果此时有其他线程进来看到状态为锁定，就会按顺序放入到同步等待队列中自旋挂起。当此时的工作线程执行结束后，又唤醒队列的第一个节点，因为是自旋挂起的，当唤醒的时候就会去更新状态锁，重复之前线程的操作。

这个队列同步器是由AQS静态内部类Node组成的双向链表.当一个线程去请求同步状态时失败的时候就会生成一个Node节点加入同步等待队列中。

> 条件等待队列下一篇在讲

Node的重要属性如下：

|属性名|作用|
|--|--|
|Node prev|同步队列中，当前节点的前一个节点，如果当前节点是同步队列的头结点，那么prev属性为null|
|Node next|同步队列中，当前节点的后一个节点，如果当前节点是同步队列的尾结点，那么next属性为null|
|Node thread|当前节点代表的线程，如果当前线程获取到了锁，那么当前线程所代表的节点一定处于同步队列的队首，且thread属性为null，至于为什么要将其设置为null，当获取到锁的时候已经把当前线程设置为拥有权的线程（setExclusiveOwnerThread），所以节点的thread就可以设置为null了。|
|int waitStatus|当前线程的等待状态，有5种取值。0表示初始值，1表示线程被取消，-1表示当前线程处于等待状态，-2表示节点处于条件等待队列中，-3表示下一次共享式同步状态获取将会无条件地被传播下去|
|Node nextWaiter|在条件等待队列中，该节点的下一个节点，单单在同步等待队列中没有用到|

通过Node的prev属性和next属性就构成了一个双向链表，也就是AQS中的同步队列，但是想要通过这个队列找到队列中的每一个元素，我们就需要知道这个队列的头结点是谁，尾结点是谁。因此AQS中又提供了两个属性：head和tail，这两个属性的类型均是Node类型，它们分别指向同步队列中的头结点和尾结点。这样AQS就能通过head和tail，找到队列中的每一个元素。同步队列的结构示意图如下。
![](aqs-sync.png)

### 3、源码分析
如果直接讲`AbstractQueuedSynchronizer` 的源码可能有点不知道从哪讲好，所以通过一个Demo来进行分析。Demo如下：
```
package com.amico.contract.trade.controller;

import java.util.concurrent.locks.Lock;
import java.util.concurrent.locks.ReentrantLock;

public class LockTest {
    public static void main(String[] args) {
        Lock lock = new ReentrantLock(true);
        try{
            lock.lock();
            System.out.println("Lock Test");
        }finally {
            lock.unlock();
        }
    }
}

```

我觉得ReentrantLock 应该算是比较常用，`lock()`上锁，`unlock()` 解锁。`lock()`方法调用的是ReentrantLock抽象静态内部类Sync的`lock()`方法，而Sync继承了AbstractQueuedSynchronizer，最终调用的是AQS的`acquire(int)`方法。代码如下：
```
public final void acquire(int arg) {
	if (!tryAcquire(arg) &&
		acquireQueued(addWaiter(Node.EXCLUSIVE), arg))
		selfInterrupt();
}
```
代码很少功能却很强大复杂,这个方法其实可以拆成4个方法：
+ 调用tryAcquire()方法
+ 执行addWaiter()方法
+ 执行acquireQueued()方法
+ 执行selfInterrupt()方法。

先说说`acquire(int)` 方法的总体功能与流程，看代码注释：
```
/*
acquire()的作用是获取同步状态(state)，这里同步状态的含义等价于锁
tryAcquire()方法是尝试获取同步状态，如果该方法返回true，表示获取同步状态成功；返回false表示获取同步状态失败
tryAcquire()方法是AQS中定义的一个方法，它需要子类来重写该方法。因此在公平锁的同步组件FairSync和非公平锁的同步组NonfairSync中，tryAcquire()方法的实现代码逻辑是不一样的。

第1种情况：当tryAcquire()返回true时，acquire()方法会直接结束。
		因为此时!tryAcquire(arg) 就等于false，而&&判断具有短路作用，当因为&&判断前面的条件判断为false，&&后面的判断就不会进行了，
		所以此时就不会执行if条件判断的 acquireQueued(addWaiter(Node.EXCLUSIVE), arg)方法，此时方法就直接返回了。
		这种情况表示线程获取锁成功了
第2中情况：当tryAcquire()返回false时，表示线程没有获取到锁，
		这个时候就需要将线程加入到同步队列中了。此时 !tryAcquire() == true，因此会进行&&后面的判断，即acquireQueued()方法的判断，在进行acquireQueued()方法判断之前会先执行addWaiter()方法。

		addWaiter()方法返回的是当前线程代表的节点，这个方法的作用是将当前线程放入到同步队列中。
		然后再调用acquireQueued()方法，在这个方法中，会先判断当前线程代表的节点是不是第二个节点，如果是就会尝试获取锁，如果获取不到锁，线程就会被阻塞；如果获取到锁，就会返回。
		如果当前线程代表的节点不是第二个节点，那么就会直接阻塞，只有当获取到锁后，acquireQueued()方法才会返回

		acquireQueued()方法如果返回的是true，表示线程是被中断后醒来的，此时if的条件判断成功，就会执行selfInterrupt()方法，该方法的作用就是将当前线程的中断标识位设置为中断状态。
		如果acquireQueued()方法返回的是false，表示线程不是被中断后醒来的，是正常唤醒，此时if的条件判断不会成功。acquire()方法执行结束

		selfInterrupt()方法，最终调用的是interrupt()设置中断标识,线程阻塞的时候设置中断标识，在结束阻塞的时候又调用interrupted() 清除标记
		这里随便啰嗦说一下：interrupt()、interrupted()、isInterrupted() 方法区别
		interrupt() 其作用是中断此线程,但实际上只是给线程设置一个中断标志，线程仍会继续运行。
		interrupted() 其作用返回Boolean(当前线程是否被中断)并清除中断状态，第二次再调用时中断状态已经被清除，将返回一个false。
		isInterrupted() 其作用返回此线程是否被中断 ，不清除中断状态。

总结：只有当线程获取到锁时，acquire()方法才会结束；如果线程没有获取到锁，那么它就会一直阻塞在acquireQueued()方法中，那么acquire()方法就一直不结束。

*/
public final void acquire(int arg) {
	if (!tryAcquire(arg) &&
		acquireQueued(addWaiter(Node.EXCLUSIVE), arg))
		selfInterrupt();
}
```


