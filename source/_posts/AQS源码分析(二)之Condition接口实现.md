---
title: AQS源码分析(二)之Condition接口实现
date: 2020-08-22 18:00:29
updated: 2020-08-22 18:00:29
tags: [多线程,AQS]
categories: Java
---
### 一、Condition是什么？有什么用？
> Tip: 本文源码基于JDK8

我们知道 `wait()`、`notify()`是和`synchronized`关键字配合使用的。如果使用了显示锁Lock，就不能用了，所以Condition应运而生。
Condition是一个接口，主要功能就是提供了与 `wait()`、`notify()`一样的等待/唤醒功能。
全部接口如下：
+ await()
线程在调用condition.await()后处于await状态，此时调用thread.interrupt()会报错
+ awaitUninterruptibly()
但是使用condition.awaitUninterruptibly()后，调用thread.interrupt()则不会报错
+ awaitNanos(long nanosTimeout)
等待到nanosTimeout纳秒
+ await(long time, TimeUnit unit)
等待到单位时间
+ awaitUntil(Date deadline)
等待到特定日期
+ signal()
唤醒一个等待在condition上的线程
+ signalAll()
醒所有等待在condition上的线程


<!--more-->

Condition是在JDK1.5中才出现的，它用来替代传统的Object的`wait()`、`notify()`实现线程间的协作，相比使用Object的`wait()`、`notify()`，使用Condition的`await()`、`signal()`这种方式实现线程间协作更加安全和高效。而它的她的实现类就是AQS的ConditionObject。

### 二、源码分析
调用Condition的`await()`和`signal()`方法，都必须在lock保护之内，就是说必须在`lock.lock()`和`lock.unlock`之间才可以使用。
AQS内部维护了一个同步队列，如果是独占式锁的话，所有获取锁失败的线程的尾插入到同步队列，同样的，condition内部也是使用同样的方式，内部维护了一个 等待队列，所有调用condition.await方法的线程会加入到等待队列中，并且线程状态转换为等待状态。另外注意到ConditionObject中有两个成员变量：
```java
/** First node of condition queue. */
private transient Node firstWaiter;
/** Last node of condition queue. */
private transient Node lastWaiter;
```

这两个就是条件等待队列的头尾节点，和同步等待队列不同的是，条件等他队列是单向链表。Node类有这样一个属性：
```java
//后继节点
Node nextWaiter;
```

还有一个重要的变量 `waitStatus` 与它的取值范围。
```
volatile int waitStatus;
static final int CANCELLED =  1;
static final int SIGNAL    = -1;
static final int CONDITION = -2;
static final int PROPAGATE = -3;
```
在条件队列中，我们只需要关注一个值即可——CONDITION。它表示线程处于正常的等待状态。
而只要waitStatus不是CONDITION，我们就认为线程不再等待了，此时就要从条件队列中移到同步等待队列。

**来看看条件等待队列的示例图，如下**
![](condition1.png)
![](condition2.png)

Condition接口的实现类是AQS的内部类ConditionObject。和之前一样通过Demo一行行分析。Demo如下：
```java
public class ConditionTest {
    private static Lock lock = new ReentrantLock();
    private static Condition condition = lock.newCondition();
    private static Condition consume = lock.newCondition();
    private static Condition product = lock.newCondition();
    private static BlockingQueue<Object> queue = new LinkedBlockingQueue<>();

    public static void main(String[] args) {
        ConditionTest conditionTest = new ConditionTest();
        new Thread(()->conditionTest.Consume()).start();
        new Thread(()->conditionTest.Product()).start();
    }

    public void Consume(){
        lock.lock();
        try {
            System.out.println("===消费端拿到了锁---");
            if(queue.size()<=0){
                System.out.println("队列没数据了，等待数据");
                consume.await();
            }
            System.out.println("消费金额：$"+ queue.poll());
            System.out.println("通知生产数据");
            product.signal();

        } catch (InterruptedException e) {
            e.printStackTrace();
        } finally {
            System.out.println("===消费端释放锁---");
            lock.unlock();
        }
    }

    public void Product(){
        lock.lock();
        try {
            System.out.println("===生产端拿到了锁========");
            if (queue.size() > 0) {
                System.out.println("队列还有数据，等待消费");
                product.await();
            }
            if(queue.offer(100))System.out.println("添加金额: $100");
            System.out.println("通知消费端");
            consume.signal();
        } catch (InterruptedException e) {
            e.printStackTrace();
        } finally {
            System.out.println("===生产端释放了锁=========");
            lock.unlock();
        }
    }
}

/*
输出结果：

===消费端拿到了锁---
队列没数据了，等待数据
===生产端拿到了锁========
添加金额: $100
通知消费端
===生产端释放了锁=========
消费金额：$100
通知生产数据
===消费端释放锁---

*/
```
> 先无视代码的质量与性能什么的。

#### await() 上
lock调用lock()方法上次分析过了，来看看await方法做了什么操作。
```java
public final void await() throws InterruptedException {
	// 判断线程是否被中断，若中断则抛InterruptedException异常
	if (Thread.interrupted())
		throw new InterruptedException();
	// 添加新的节点到条件等待队列，并清除所有被cancel的节点
	Node node = addConditionWaiter();
	// 全部释放当前线程所占用的锁，并返回锁状态，下面抢锁的时候需要用到
	int savedState = fullyRelease(node);
	/**
	 * 中断的模式：
	 * 0: 代表整个过程中一直没有中断发生
	 * THROW_IE(-1): 表示退出await()方法时需要抛出InterruptedException，这种模式对应于中断发生在signal之前
	 * REINTERRUPT: 表示退出await()方法时只需要再自我中断一下，这种模式对应于中断发生在signal之后，即中断来的太晚了。
	 */
	int interruptMode = 0;
	/**
	 * isOnSyncQueue() 方法返回的是节点是否在同步等待队列，
	 * 如果当前队列不在同步队列中,说明刚刚被await, 还没有人调用signal方法，则直接将当前线程挂起
	 */
	while (!isOnSyncQueue(node)) {
		// 线程挂起
		LockSupport.park(this);
		/**
		 * 能执行到这里说明要么是signal方法被调用了，要么是线程被中断了
		 * 所以检查下线程被唤醒的原因，如果是因为中断被唤醒，则跳出while循环
		 */ 
		if ((interruptMode = checkInterruptWhileWaiting(node)) != 0)
			break;
	}
	// 不管是signal唤醒还是中断，都会加入到同步等待队列，那么就尝试去获取锁，如果获取不到，就会加入到同步队列中，并阻塞
	if (acquireQueued(node, savedState) && interruptMode != THROW_IE)
		interruptMode = REINTERRUPT;
	// 如果是正常的signal唤醒，那这个节点的nextWaiter应该等于null,如果这里成立，那就是中断唤醒的，unlinkCancelledWaiters 清除所有被cancel的节点
	if (node.nextWaiter != null) // clean up if cancelled
		unlinkCancelledWaiters();
	// 报告中断状态，是抛异常还是重新设置中断标识
	if (interruptMode != 0)
		reportInterruptAfterWait(interruptMode);
}
```

#### addConditionWaiter()
上面的代码注释基本把大体流程分析了一下。来看看具体到行的代码，addConditionWaiter:
```java
private Node addConditionWaiter() {
	// 尾节点
	Node t = lastWaiter;
	// If lastWaiter is cancelled, clean out.
	if (t != null && t.waitStatus != Node.CONDITION) {
		// 如果尾节点状态不是CONDITION，说明应该是被中断了，清除所有被cancel的节点
		unlinkCancelledWaiters();
		// 清除之后新的尾节点赋值给t,
		t = lastWaiter;
	}
	// 创建新的条件等待节点
	Node node = new Node(Thread.currentThread(), Node.CONDITION);
	// 如果条件等待队列为空则，首尾都是node,否则尾插入node
	if (t == null)
		firstWaiter = node;
	else
		t.nextWaiter = node;
	// 新创建的node为最新的尾节点
	lastWaiter = node;
	return node;
}
```
上面代码都有注释了，我这里就不重复说了，之前在同步等待队列的添加节点中用到了CAS，这里没有用到是因为这里不存在并发问题。
因为能调用await方法的线程必然是已经获得了锁，来看看`unlinkCancelledWaiters()`清除cancel节点的方法：
```java
private void unlinkCancelledWaiters() {
	// 条件队列首节点
	Node t = firstWaiter;
	// 存尾节点的临时变量
	Node trail = null;
	while (t != null) {
		Node next = t.nextWaiter;
		// 需要清除的节点
		if (t.waitStatus != Node.CONDITION) {
			t.nextWaiter = null;
			if (trail == null)
				firstWaiter = next;
			else
				trail.nextWaiter = next;
			if (next == null)
				lastWaiter = trail;// next == null 就是遍历到最后了，把临时遍历赋值给 lastWaiter
		}
		else
			trail = t;
		t = next;
	}
}
```
这就是从头遍历，剔除不等于`CONDITION`状态的节点，也就是`CANCELLED`节点了，代码都不算难理解。

#### fullyRelease(node)
既然已经把当前线程封装成Node添加到了条件等待队列了，那就要把当前线程的锁释放出去。这里是一次性释放所有锁（对于可重入锁而言）。
```java
final int fullyRelease(Node node) {
	boolean failed = true;
	try {
		int savedState = getState();
		// 释放savedState
		if (release(savedState)) {
			failed = false;
			return savedState;
		} else {
			throw new IllegalMonitorStateException();
		}
	} finally {
		if (failed)
			node.waitStatus = Node.CANCELLED;
	}
}
```
最终调的是 `release()`方法.而release上次讲过，这次不粘贴代码了。
这里需要注意的是：**可能会发生IllegalMonitorStateException 异常，当然了如果正确使用的话是不会抛异常的。**
而抛这个异常的原因是：**当前线程可能并不是持有锁的线程，为什么这么说，因为调用await方法时，我们其实并没有检测`Thread.currentThread() == getExclusiveOwnerThread()`**
就比如这个demo代码，如果你的await()方法在lock()方法之前调用，那就会报这个异常。如果报错,finally 的if语句就成立。就会把`waitStatus=CANCELLED`。
所以`addConditionWaiter()`才会有去检测尾节点是否有效。

#### signal()
在上面释放锁之后，来到while循环，判断`isOnSyncQueue(node)` 是否在同步队列中。
```java
final boolean isOnSyncQueue(Node node) {
	if (node.waitStatus == Node.CONDITION || node.prev == null)
		return false;
	if (node.next != null) // If has successor, it must be on queue
		return true;
	/*
	 * node.prev can be non-null, but not yet on queue because
	 * the CAS to place it on queue can fail. So we have to
	 * traverse from tail to make sure it actually made it.  It
	 * will always be near the tail in calls to this method, and
	 * unless the CAS failed (which is unlikely), it will be
	 * there, so we hardly ever traverse much.
	 */
	// 从同步等待队列的尾部开始向上查找是否存在这个node
	return findNodeFromTail(node);
}

/**
 * 从同步队列的尾部开始向前遍历，如果找到就返回true，否则false
 */
private boolean findNodeFromTail(Node node) {
        Node t = tail;
        for (;;) {
            if (t == node)
                return true;
            if (t == null)	// 这个就是到头了，到头还没找到就返回false
                return false;
            t = t.prev;
        }
    }
```
一直在讲条件等待队列，为什么就判断是否存在在同步等待队列中了呢？不要慌，慢慢分析。在while条件中，第一次`isOnSyncQueue(node)`肯定返回false,那`!isOnSyncQueue(node)=true`
进入while 循环，调用` LockSupport.park(this)` 把当前线程挂起，**代码执行到此就阻塞起来了**。等待signal/signalAll 唤醒或中断。
阻塞后面的代码后面分析，接下来分析signal方法。
```java
public final void signal() {
	//isHeldExclusively()方法是需要子类重新，判断当前线程是否是持有锁的线程。
	if (!isHeldExclusively())
		throw new IllegalMonitorStateException();
	Node first = firstWaiter;
	if (first != null)
		doSignal(first);// 唤醒条件等待队列的第一节点
}
```
signal()方法 最终调用的是`doSignal(first)`方法：
```java
private void doSignal(Node first) {
	do {
		// 令firstWaiter等于first的下一个节点，因为first要出队了
		if ( (firstWaiter = first.nextWaiter) == null)
			lastWaiter = null;
		// help gc
		first.nextWaiter = null;
		/**
		 * transferForSignal(first) 把节点从 condition queue 转移到  sync queue,返回boolean值。
		 * 两种情况：
		 *  返回true： !transferForSignal(first)==false ,那好说直接就结束while循环了，因为已经到同步队列，等待它的前驱节点唤醒
		 *  返回false：first等于新的firstWaiter 继续循环。返回false 的原因就是节点被取消了，
		 *              CANCELLED 状态的节点不能将它移到同步队列中，所以需要继续从条件等待队列找没有被取消的节点。
		 */
	} while (!transferForSignal(first) &&
			 (first = firstWaiter) != null);
}
```
唤醒第一个条件等待队列的节点（出队），上面的主要方法就是`transferForSignal(first)` 从条件等待队列转移到同步等待队列。因为两个队列都是Node对象，只不过涉及的属性不太相同而已。
如果返回的是false，说明要转移的节点是取消的状态，所以需要继续遍历。来看看源码：
```java
final boolean transferForSignal(Node node) {
	/**
	 * If cannot change waitStatus, the node has been cancelled.
	 * 
	 * 就是把 Node 的 waitStatus 从 CONDITION 状态变成 0
	 * 如果CAS失败的话，那 waitStatus就被修改过，就不等于CONDITION，也就只能是 CANCELLED
	 */
	if (!compareAndSetWaitStatus(node, Node.CONDITION, 0))
		return false;

	/*
	 * Splice onto queue and try to set waitStatus of predecessor to
	 * indicate that thread is (probably) waiting. If cancelled or
	 * attempt to set waitStatus fails, wake up to resync (in which
	 * case the waitStatus can be transiently and harmlessly wrong).
	 */
	/**
	 * enq(node) 上次分析过，就是把node CAS添加到同步等待队列的尾部，并返回node的前驱节点
	 * 为什么要返回前驱节点呢？还记得 之前分析过的 shouldParkAfterFailedAcquire() 把前驱节点的waitStatus 设置成SIGNAL
	 * 表示同步队列中还有线程在等待，你记得唤醒我！！！
	 */
	Node p = enq(node);
	int ws = p.waitStatus;
	// 如果已经ws>0 说明前驱节点已经被取消 或者 CAS修改状态失败 唤醒当前线程
	if (ws > 0 || !compareAndSetWaitStatus(p, ws, Node.SIGNAL))
		LockSupport.unpark(node.thread);
	return true;
}
```
transferForSignal()方法从条件等待队列移到同步队列，如果返回true,说明正常等待同步队列唤醒。如果前驱节点取消了那就直接唤醒当前线程
#### await()下
前面我们已经分析了signal方法，它会将节点添加进sync queue队列中，并要么立即唤醒线程，要么等待前驱节点释放锁后将自己唤醒。
无论怎样，被唤醒的线程要从哪里恢复执行呢？当然是被挂起的地方呀，还记得while 循环里的`LockSupport.park(this)` 吧，来回忆下：
```java
public final void await() throws InterruptedException {
	if (Thread.interrupted())
		throw new InterruptedException();
	Node node = addConditionWaiter();
	int savedState = fullyRelease(node);
	/**
	 * 中断的模式：
	 * 0: 代表整个过程中一直没有中断发生
	 * THROW_IE(-1): 表示退出await()方法时需要抛出InterruptedException，这种模式对应于中断发生在signal之前
	 * REINTERRUPT: 表示退出await()方法时只需要再自我中断一下，这种模式对应于中断发生在signal之后，即中断来的太晚了。
	 */
	int interruptMode = 0;
	/**
	 * isOnSyncQueue() 方法返回的是节点是否在同步等待队列，
	 * 如果当前队列不在同步队列中,说明刚刚被await, 还没有人调用signal方法，则直接将当前线程挂起
	 */
	while (!isOnSyncQueue(node)) {
		// 线程挂起
		LockSupport.park(this);
		/**
		 * 能执行到这里说明要么是signal方法被调用了，要么是线程被中断了
		 * 所以检查下线程被唤醒的原因，如果是因为中断被唤醒，则跳出while循环
		 */
		if ((interruptMode = checkInterruptWhileWaiting(node)) != 0)
			break;
	}
	// 不管是signal唤醒还是中断，都会加入到同步等待队列，那么就尝试去获取锁，如果获取不到，就会加入到同步队列中，并阻塞
	if (acquireQueued(node, savedState) && interruptMode != THROW_IE)
		interruptMode = REINTERRUPT;
	// 如果是正常的signal唤醒，那这个节点的nextWaiter应该等于null,如果这里成立，那就是中断唤醒的，unlinkCancelledWaiters 清除所有被cancel的节点
	if (node.nextWaiter != null) // clean up if cancelled
		unlinkCancelledWaiters();
	// 报告中断状态，是抛异常还是重新设置中断标识
	if (interruptMode != 0)
		reportInterruptAfterWait(interruptMode);
}
```

park 方法之后是`checkInterruptWhileWaiting()` 判断后续的处理应该是抛出 InterruptedException 还是重新中断，来看看代码：
```java
private int checkInterruptWhileWaiting(Node node) {
	return Thread.interrupted() ?
		(transferAfterCancelledWait(node) ? THROW_IE : REINTERRUPT) :
		0;
}
```
这代码还真短小精悍，`interrupted()`方法上篇讲过，其作用返回Boolean(当前线程是否被中断)并清除中断状态。
如果interrupted()返回false,那就是没有中断，直接返回0，然后再次判断`isOnSyncQueue()`不出意外那肯定是返回true,`!`取反，那就结束while循环。
这里假设是发生了中断，那就走`transferAfterCancelledWait()` 方法，进一步判断是否发生了signal。
```java
final boolean transferAfterCancelledWait(Node node) {
	// 只要一个节点的waitStatus还是Node.CONDITION，那就说明它还没有被signal过
	if (compareAndSetWaitStatus(node, Node.CONDITION, 0)) {
		/**
         * 如果没有被signal，说明是中断唤醒的，enq(node)把节点从条件等待队列移动到同步队列并返回true.
         * 这里注意一点就是和正常signal 不同的是，我们这里没有把 nextWaiter 设置为null
         * 也就是还和条件等待队列关联着
         */
		enq(node);
		return true;
	}
	/*
	 * If we lost out to a signal(), then we can't proceed
	 * until it finishes its enq().  Cancelling during an
	 * incomplete transfer is both rare and transient, so just
	 * spin.
	 */
	/**
	 * 因为不管是正常signal还是中断唤醒，最终都会移动到同步队列
	 * 一直自旋判断是否移动到同步队列，没有则Thread.yield()把CPU让给其他线程，不一定让步成功，可能自己又抢到了
	 * 
	 * 而代码能走到这里说明上面的CAS更新失败，也就是在其他地方（signal）已经把node移动到同步队列
	 * 说明signal 和中断 基本上是同时发生的，但最终还是中断来得太晚，返回false,重新标识中断状态
	 */
	while (!isOnSyncQueue(node))
		Thread.yield();
	return false;
}
```
如果`transferAfterCancelledWait()`方法执行了，说明线程被中断了，因为只有`Thread.interrupted()`返回true的时候才会调用。
而中断不一定成功，可能在中断的时候刚好signal 了，而且抢在中断的时候把节点移到了同步队列，那中断就来得比较慢了。重新赋值给`interruptMode`。
+ 0: 代表整个过程中一直没有中断发生
+ THROW_IE(-1): 表示退出await()方法时需要抛出InterruptedException，这种模式对应于中断发生在signal之前
+ REINTERRUPT: 表示退出await()方法时只需要再自我中断一下，这种模式对应于中断发生在signal之后，即中断来的太晚了。

最终代码执行到`acquireQueued()`方法，这个方法熟悉吧，上篇讲过，来看下代码，之前讲过这回不注释了

**acquireQueued**
```java
final boolean acquireQueued(final Node node, int arg) {
        boolean failed = true;
        try {
            boolean interrupted = false;
            for (;;) {
                final Node p = node.predecessor();
                if (p == head && tryAcquire(arg)) {
                    setHead(node);
                    p.next = null; // help GC
                    failed = false;
                    return interrupted;
                }
                if (shouldParkAfterFailedAcquire(p, node) &&
                    parkAndCheckInterrupt())
                    interrupted = true;
            }
        } finally {
            if (failed)
                cancelAcquire(node);
        }
    }
```
+ acquireQueued() 抢锁设置为同步队列头节点，判断`nextWaiter`是否不为null,清理掉相关的CANCELLED状态
+ 如果interruptMode 不等于0,说明是被中断了，但是中断是否成功需要看`interruptMode`最终是什么。执行reportInterruptAfterWait方法

##### reportInterruptAfterWait
```java
private void reportInterruptAfterWait(int interruptMode)
	throws InterruptedException {
	if (interruptMode == THROW_IE)
		throw new InterruptedException();
	else if (interruptMode == REINTERRUPT)
		selfInterrupt();
}
```
代码很简单，如果`transferAfterCancelledWait()`返回true,那么`interruptMode==THROW_IE` 抛出中断异常。
如果等于REINTERRUPT 则，调用`selfInterrupt()`重新标识中断状态（上面分析过）。


### 三、总结
condition用法的整体流程：
+ 调用await()方法的时候必须是持有锁
+ 把线程封装成Node加入到条件等待队列
+ 释放所有锁并阻塞，等待signal
+ signal唤醒，把Node从条件等待队列出队移到同步等待队列
+ 判断是否是中断，然后阻塞式抢锁
+ 从同步队列出队，报告中断信息
+ 结束await()

![](condition-process.png)

当然还有 await与signal相同功能方法还没讲，比如：
```java
void awaitUninterruptibly();
long awaitNanos(long nanosTimeout) throws InterruptedException;
boolean await(long time, TimeUnit unit) throws InterruptedException;
boolean awaitUntil(Date deadline) throws InterruptedException;
void signalAll();
```
代码逻辑大体都差不多，上面看得懂，基本上都可自行分析。至此关于Condition 源码基本分析完了。
