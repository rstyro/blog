---
title: AQS源码分析(一)
date: 2020-08-21 18:00:29
tags: [多线程,AQS]
categories: Java
---
### 一、AQS是什么
AQS(AbstractQueuedSynchronizer):顾名思义是一个抽象队列同步器。在JDK5 之后的 `java.util.concurrent` 下的的很多常用的多线程工具类都依赖这个类。
面试常考的点，也是学习多线程必掌握的知识点。
看JDK源码注释说，AQS是基于CLH自旋锁变种的一个虚拟的双向队列，而队列一般都是先进先出(First Input First Output)。
>CLH是一种基于链表的可扩展、高性能、公平的自旋锁，申请线程只在本地变量上自旋，它不断轮询前驱的状态，如果发现前驱释放了锁就结束自旋。
> 大概长下面这样子：
> ```
      +------+  prev +-----+       +-----+
 head |      | <---- |     | <---- |     |  tail
      +------+       +-----+       +-----+
```

直白点说AQS就是一个框架，具体资源的获取/释放方式交由我们自定义同步器去实现。AQS定义两种资源方式：Exclusive 独占资源（ReentrantLock）、Share 共享资源（Semaphore/CountDownLatch）

框架的两大核心：同步等待队列和条件等待队列。虽然有两个队列，但我们不一定都用得到，所以它的获取/释放方法没有定义成`abstract`。自定义同步器在实现时只需要实现共享资源 state的获取与释放方式即可，至于具体线程等待队列的维护（如获取资源失败入队/唤醒出队等），AQS 已经在顶层实现好了。

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
> 这篇文章主要讲独占模式，不讲共享模式和Condition 部分

+ 队列同步器大致的运行过程：
当线程去请求的共享资源空闲就把当前请求线程设为工作线程并把状态标记为锁定状态。如果此时有其他线程进来看到状态为锁定，就会按顺序放入到同步等待队列中自旋挂起。当此时的工作线程执行结束后，又唤醒队列的第一个节点，因为是自旋挂起的，当唤醒的时候就会去更新状态锁，重复之前线程的操作。我们可以理解为头节点(Head)就是持有锁的工作线程。

这个队列同步器是由AQS静态内部类Node组成的双向链表.当一个线程去请求同步状态时失败的时候就会生成一个Node节点加入同步等待队列中。

> 条件等待队列下一篇在讲

Node的重要属性如下：

|属性名|作用|
|--|--|
|Node prev <div style="width:130px;"></div>|同步队列中，当前节点的前一个节点，如果当前节点是同步队列的头结点，那么prev属性为null|
|Node next|同步队列中，当前节点的后一个节点，如果当前节点是同步队列的尾结点，那么next属性为null|
|Node thread|当前节点代表的线程，如果当前线程获取到了锁，那么当前线程所代表的节点一定处于同步队列的队首，且thread属性为null，至于为什么要将其设置为null，当获取到锁的时候已经把当前线程设置为持有锁的线程（setExclusiveOwnerThread），所以节点的thread就可以设置为null了。|
|int waitStatus|当前线程的等待状态，有5种取值。0表示初始值，1表示线程被取消，-1表示当前线程处于等待状态，-2表示节点处于条件等待队列中，-3表示下一次共享式同步状态获取将会无条件地被传播下去|
|Node nextWaiter|在条件等待队列中，该节点的下一个节点，单单在同步等待队列中没有用到|

通过Node的prev属性和next属性就构成了一个双向链表，也就是AQS中的同步队列，但是想要通过这个队列找到队列中的每一个元素，我们就需要知道这个队列的头结点是谁，尾结点是谁。因此AQS中又提供了两个属性：head和tail，这两个属性的类型均是Node类型，它们分别指向同步队列中的头结点和尾结点。这样AQS就能通过head和tail，找到队列中的每一个元素。同步队列的结构示意图如下。
![](aqs-sync.png)

>第一次初始化时，`head=tail=new Node()` 头尾都等于一个空属性的节点。同步等待队列是不包含 head 节点，因为`head`是持有锁的工作线程不需要等待。

### 3、源码分析
如果直接讲`AbstractQueuedSynchronizer` 的源码可能有点不知道从哪讲好，所以通过一个Demo来进行分析。Demo如下：
```java
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

**以ReentrantLock类demo来分析AQS源码，`lock()`上锁，`unlock()` 解锁。`lock()`方法调用的是ReentrantLock抽象静态内部类Sync的`lock()`方法。**
```java
 static final class FairSync extends Sync {
        private static final long serialVersionUID = -3000897897090466540L;

        final void lock() {
            acquire(1);
        }
}
```

而Sync继承了AbstractQueuedSynchronizer，最终调用的是AQS的`acquire(int)`方法。代码如下：
```java
public final void acquire(int arg) {
	if (!tryAcquire(arg) &&
		acquireQueued(addWaiter(Node.EXCLUSIVE), arg))
		selfInterrupt();
}
```
acquire方法的代码很少功能却很强大复杂,这个方法其实可以拆成4个方法：
+ 调用tryAcquire()方法
+ 执行addWaiter()方法
+ 执行acquireQueued()方法
+ 执行selfInterrupt()方法。

#### acquire方法
先说说`acquire(int)` 方法的总体功能与流程，看代码注释：
```java
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
#### tryAcquire 方法
先看上面代码的注释，接下来分析`tryAcquire(arg)` 方法，源码如下：
```java
protected final boolean tryAcquire(int acquires) {
	// 获取当前线程，如果获取到锁就把当前线程设置为独占拥有权限执行的线程
	final Thread current = Thread.currentThread();
	//获取同步状态state(在AQS中，state就相当于锁)，如果后面成功修改此状态就说明获取到锁
	int c = getState();
	if (c == 0) {
	// 如果c等于0，表示还没有任何线程获取到锁
	// hasQueuedPredecessors() 查询是否有其他线程等待时间比当前线程更长,也就是是否已经有线程在排队，返回true表示有线程在排队，返回false表示没有线程在排队
	//   第一种情况：hasQueuedPredecessors()返回true，表示有线程排队，(AQS设置原则FIFO,所以有排队了，那你肯定获取锁失败，你得到队列后面排队)
	//          此时 !hasQueuedPredecessors() == false，由于&& 运算符的短路作用，if的条件判断为false，那么就不会进入到if语句中，tryAcquire()方法就会返回false
	//   第二种情况：hasQueuedPredecessors()返回false，表示没有线程排队
	//          此时 !hasQueuedPredecessors() == true, 那么就会进行&&后面的判断，就会调用compareAndSetState()方法去进行修改state字段的值
	//          compareAndSetState()方法是一个CAS方法,它会对state字段进行修改，它的返回值结果又需要分两种情况
	//          
	//          第1种情况：对state字段进行CAS修改成功，就会返回true，此时if的条件判断就为true了，就会进入到if语句中，同时也表示当前线程获取到了锁。那么最终tryAcquire()方法会返回true
	//          第2种情况：如果对state字段进行CAS修改失败，说明在这一瞬间，已经有其他线程获取到了锁，那么if的条件判断就为false了，就不会进入到if语句块中，最终tryAcquire()方法会返回false。
		if (!hasQueuedPredecessors() &&
			compareAndSetState(0, acquires)) {
			// 把当前线程设置为独占拥有权限执行的线程
			setExclusiveOwnerThread(current);
			return true;
		}
	}
	else if (current == getExclusiveOwnerThread()) {
	// 这个就是可重入，state !=0 并且当前线程等于拥有执行线程
		int nextc = c + acquires;
		if (nextc < 0)
			throw new Error("Maximum lock count exceeded");
		// 当前线程再一次获得锁，次数+1 
		setState(nextc);
		// 返回true 说明获取到锁
		return true;
	}
	// state !=0 并且当前线程不等于拥有执行线程，说明没有获取到锁，返回false
	return false;
}
```

#### addWaiter 方法
之前也分析了，这个方法不一定会执行，得看`!tryAcquire(arg)` 是否是true。看方法名就猜到应该是把线程封装成Node节点添加到队列中等待执行。来看源码：
```java
 private Node addWaiter(Node mode) {
	// 把当前线程封装成Node
	Node node = new Node(Thread.currentThread(), mode);
	// Try the fast path of enq; backup to full enq on failure
	// 获取尾节点
	Node pred = tail;
	// 如果尾节点不为空，说明队列已经初始化过了。
	if (pred != null) {
		//然后把尾节点设置为当前节点得上一个节点（那么当前节点就是新的尾节点）
		node.prev = pred;
		// 通过CAS设置尾节点（保证原子性），用CAS是防止多个线程刚好执行到这个地方最终只有一个修改成功
		if (compareAndSetTail(pred, node)) {
			// 设置尾节点成功，和旧的尾节点做双向关联，并返回当前节点
			pred.next = node;
			return node;
		}
	}
	// 这里有两种情况会执行
	// 	第一种：第一次进来的时候，头尾节点还是null，就会走这个方法初始化。
	//  第二种：就是在上面CAS设置尾节点的时候失败了（被其他线程先设置成功了），那么会走这个方法把节点添加到队列尾部
	enq(node);
	return node;
}
```
来看看`end`方法的代码：
```java
private Node enq(final Node node) {
	// 一个死循环，自旋操作
	for (;;) {
		// 获取尾节点
		Node t = tail;
		// 如果等于null ，则初始化
		if (t == null) { // Must initialize
			// 防止多个线程初始化还是CAS操作，首节点是一个属性都不赋值的Node。操作失败就自旋直到成功并返回该节点
			if (compareAndSetHead(new Node()))
			//第一次操作，首尾相同，第二次之后就全部走else添加到尾部了
				tail = head;
		} else {
		// 已经初始化过了，和addWaiter 的方法一样，添加到尾节点。
			node.prev = t;
			if (compareAndSetTail(t, node)) {
				t.next = node;
				return t;
			}
		}
	}
}
```

#### acquireQueued 方法
没有获取到锁就没法执行，一直等到获取到锁了才行执行。那如何让线程等待呢，就是这个方法里面的代码，源码如下：
```java
final boolean acquireQueued(final Node node, int arg) {
	// 这个状态是是否是线程关闭的状态
	boolean failed = true;
	try {
		// 这个是代码该线程是否是中断后醒来的（也就是阻塞挂起中醒来的）
		boolean interrupted = false;
		// 死循环
		for (;;) {
			// 当前节点的上一个节点
			final Node p = node.predecessor();
			// 如果前一个节点是头结点（即当前线程是队列中的第二个节点），那么就调用tryAcquire()方法让当前线程去尝试获取锁
			if (p == head && tryAcquire(arg)) {
				// 如果获取锁成功，那么就将当前线程所代表的节点设置为头结点(因为AQS的设计原则就是：队列中占有锁的线程一定是头结点)
				setHead(node);
				p.next = null; // help GC
				failed = false;
				// 不是中断中醒来的，返回false
				return interrupted;
			}
			// 如果上面的p节点不是头节点或者tryAcquire 获取锁失败，就会执行这下面的代码
			// 在if判断中，先调用了shouldParkAfterFailedAcquire()方法。
			// 如果是第一次调用shouldParkAfterFailedAcquire()时，肯定返回false，为什么会返回false，（等会可以看下shouldParkAfterFailedAcquire()方法的源码），因为死循环，第二次就返回true了
			// 当shouldParkAfterFailedAcquire()返回true时，if就会继续调用parkAndCheckInterrupt()方法，该方法会将当前线程进行阻塞挂起，直到这个线程被唤醒或者被中断。
			// 因此当线程获取不到锁时，就会一直阻塞到这儿。直到被其他线程唤醒，才会继续向下执行，当线程想来后，再次进入到当前代码的无限for循环中，除非线程获取到锁，才会return返回
			if (shouldParkAfterFailedAcquire(p, node) &&
				parkAndCheckInterrupt())
				// 如果有中断过返回true,后面会调用方法清除中断标识
				interrupted = true;
		}
	} finally {
		// 只有获取到锁的时候failed才会设置为false,其他时候要么是自旋执行，要么就是parkAndCheckInterrupt 线程挂起，如果中途没获取倒锁，报错了，那就执行下面的代码
		if (failed)
			//这个方法里面就是取消当前线程的获取锁的任务，并从队列中踢出后重新更新队列关联关系
			cancelAcquire(node);
	}
}
```
看完上面代码的注释，接下来看看`shouldParkAfterFailedAcquire`方法的源码：
```java
private static boolean shouldParkAfterFailedAcquire(Node pred, Node node) {
	// 在初始情况下，所有的Node节点的waitStatus均为0，因为在初始化时，waitStatus字段是int类型，我们没有显示给它赋值，所以它默认是0
	int ws = pred.waitStatus;
	if (ws == Node.SIGNAL)
		/*
		 * This node has already set status asking a release
		 * to signal it, so it can safely park.
		 */
		// 这个在第一次是不会进来的，只有通过else设置之后再次进来才会返回true,因为外面的调用是for死循环，所以会再次进来第二次
		return true;
	if (ws > 0) {
		/*
		 * Predecessor was cancelled. Skip over predecessors and
		 * indicate retry.
		 */
		 // 这个是它的节点被取消了，如果取消了就一直往上找直到是正常节点
		do {
			node.prev = pred = pred.prev;
		} while (pred.waitStatus > 0);
		pred.next = node;
	} else {
		/*
		 * waitStatus must be 0 or PROPAGATE.  Indicate that we
		 * need a signal, but don't park yet.  Caller will need to
		 * retry to make sure it cannot acquire before parking.
		 */
		// CAS 设置pred的waitStatus为SIGNAL，之后再进来就走前面的逻辑直接返回true
		compareAndSetWaitStatus(pred, ws, Node.SIGNAL);
	}
	return false;
}
```
如果`shouldParkAfterFailedAcquire` 方法返回true,那就会调用`parkAndCheckInterrupt`方法使线程挂起。来看看源码：
```java
private final boolean parkAndCheckInterrupt() {
	// 将线程挂起，直到当前线程被唤醒并获取到锁以后，acquireQueued()方法才会返回。
	LockSupport.park(this);
	return Thread.interrupted();
}
```
**对于`acquireQueued()`方法而言，只有线程获取到了锁或者被中断，线程才会从这个方法里面返回，否则它会一直阻塞在里面。**

如果在中途报异常了什么的，就会调用`cancelAcquire`方法，来看看做了什么操作
```java
private void cancelAcquire(Node node) {
	// Ignore if node doesn't exist
	if (node == null)
		return;
	// 都取消了，所以thred 就没用了
	node.thread = null;

	// Skip cancelled predecessors
	Node pred = node.prev;
	// 过滤掉取消的节点，通俗点说获取上一个有效的节点
	while (pred.waitStatus > 0)
		node.prev = pred = pred.prev;

	// predNext is the apparent node to unsplice. CASes below will
	// fail if not, in which case, we lost race vs another cancel
	// or signal, so no further action is necessary.
	// 上一个有效节点的下一个节点
	Node predNext = pred.next;

	// Can use unconditional write instead of CAS here.
	// After this atomic step, other Nodes can skip past us.
	// Before, we are free of interference from other threads.
	// 设置当前节点为取消的状态
	node.waitStatus = Node.CANCELLED;

	// If we are the tail, remove ourselves.
	// 如果当前节点为尾节点，那直接把它上一个节点设置为尾节点，结束
	if (node == tail && compareAndSetTail(node, pred)) {
		//然后把关联关系给重新连一下
		compareAndSetNext(pred, predNext, null);
	} else {
		// If successor needs signal, try to set pred's next-link
		// so it will get one. Otherwise wake it up to propagate.
		int ws;
		// 如果不是尾节点且不是头节点，那就是中间位置了，这里有意思的操作就是把pred节点的waitStatus设置为SIGNAL。
		// 因为我们知道waitStatus初始等于0，它的改变是在 shouldParkAfterFailedAcquire方法里面，而且是下一个节点去改上一个节点的状态。
		// 如果没到shouldParkAfterFailedAcquire 方法就报错了，所以这里补上把pred的waitStatus改为waitStatus，如果已经是了，那if条件的 || 后面就不去执行了
		if (pred != head &&
			((ws = pred.waitStatus) == Node.SIGNAL ||
			 (ws <= 0 && compareAndSetWaitStatus(pred, ws, Node.SIGNAL))) &&
			pred.thread != null) {
			// 当前节点的下一个节点
			Node next = node.next;
			if (next != null && next.waitStatus <= 0)
				// 把当前线程移除，要重新更新队列的关联关系
				compareAndSetNext(pred, predNext, next);
		} else {
			// 如果这里能进来讲道理那就是pred为头节点了
			// 而unparkSuccessor 方法就是唤醒后面的线程，在解锁unlock()和release一起讲
			unparkSuccessor(node);
		}

		node.next = node; // help GC
	}
}
```
#### selfInterrupt 方法
当线程从acquireQueued()方法处返回时，返回值有两种情况，如果返回false，表示线程不是被中断才唤醒的，所以此时在acquire()方法中，if判断不成立，就不会执行selfInterrupt()方法，而是直接返回。
如果返回true，则表示线程是被中断才唤醒的，由于在parkAndCheckInterrupt()方法中调用了Thread.interrupted()方法，会返回线程是否被中断过且清除中断标识，所以此时需要返回true，使acquire()方法中的if判断成立，然后这样就会调用selfInterrupt()方法，该方法会将中断标识重新设置为中断状态。

#### release 方法
lock()上完锁之后，还是得释放锁的，ReentrantLock的unlock()方法释放锁，最终调用的是FairSync的release()方法。release()方法是AQS里面的方法，源码如下：
```java
public final boolean release(int arg) {
	if (tryRelease(arg)) {
		Node h = head;
		// 当waitStatus!=0时，表示同步队列中还有其他线程在等待获取锁（因为前面讲的shouldParkAfterFailedAcquire 方法，当前节点会把上一个节点的waitStatus设为-1，所以不为0，那后面就有节点呗）
		if (h != null && h.waitStatus != 0)
			// 唤醒h后面的线程
			unparkSuccessor(h);
		return true;
	}
	return false;
}
```
在release()方法中会先调用AQS子类的tryRelease()方法，也就是调用ReentrantLock类中Sync的tryRelease()方法，该方法就是让当前线程释放锁。方法源码如下。
```java
protected final boolean tryRelease(int releases) {
	int c = getState() - releases;
	// 判断当前线程是不是持有锁的线程，如果不是就抛出异常,讲道理这种情况是不会发生的吧
	if (Thread.currentThread() != getExclusiveOwnerThread())
		throw new IllegalMonitorStateException();
	boolean free = false;
	// 因为可能锁被重入了，所以这个地方需要判断
	if (c == 0) {
		free = true;
		setExclusiveOwnerThread(null);
	}
	// 因为上边已经判断是否是持有锁的线程，所以这里是不会有人抢的，所以没有CAS
	setState(c);
	return free;
}
```
之后来看看唤醒之后线程的方法unparkSuccessor，源码如下：
```java
 private void unparkSuccessor(Node node) {
	/*
	 * If status is negative (i.e., possibly needing signal) try
	 * to clear in anticipation of signalling.  It is OK if this
	 * fails or if status is changed by waiting thread.
	 */
	int ws = node.waitStatus;
	if (ws < 0)
		compareAndSetWaitStatus(node, ws, 0);

	/*
	 * Thread to unpark is held in successor, which is normally
	 * just the next node.  But if cancelled or apparently null,
	 * traverse backwards from tail to find the actual
	 * non-cancelled successor.
	 */
	 // 下一个需要唤醒的节点
	Node s = node.next;
	// 如果是空或者已经被取消了（就是waitStatus=1的），就得重新找
	if (s == null || s.waitStatus > 0) {
		s = null;
		// 从尾部开始找，知道找到一个有效的节点
		for (Node t = tail; t != null && t != node; t = t.prev)
			if (t.waitStatus <= 0)
				s = t;
	}
	// 最终的节点，如果不为null那就唤醒s节点的线程，之后acquireQueued方法里面的parkAndCheckInterrupt方法就会继续往下执行，所以acquireQueued也就不阻塞了
	if (s != null)
		LockSupport.unpark(s.thread);
}
```

### 总结
+ AQS中用state属性表示锁，如果能成功将state属性通过CAS操作从0设置成1即获取了锁
+ 当线程抢到锁时将线程设置为持有锁线程setExclusiveOwnerThread，也就是Head节点
+ 也就是说head节点的下一个节点，才是同步等待队列的第一个节点。
+ tryAcquire() 尝试获取锁
+ addWaiter() 把线程封装成Node节点添加到队列中等待执行
+ acquireQueued() 如果没获取到锁，调用parkAndCheckInterrupt()挂起,自旋等待获取到锁或中断
+ selfInterrupt() 此线程中断唤醒的，需要调此方法把中断标识重新设置为中断状态
+ cancelAcquire() 移除CANCELLED状态的节点，更新队列的关联关系
+ release() 释放锁，unparkSuccessor() 唤醒后续节点

**本文主要分析了独占模式下的同步队列相关代码，防止篇幅过长，共享式的条件等待队列等等下篇继续。**
