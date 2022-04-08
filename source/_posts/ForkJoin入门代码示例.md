---
title: ForkJoin入门代码示例
date: 2022-04-08 21:37:22
updated: 2022-04-08 21:37:22
tags: [Java,多线程]
categories: Java
---

### 一、ForkJoin简介
+ ForkJoin是JDK1.7引入的一钟新的并发框架，主要用于实现 分而治之 的算法。
+ 简单的讲就是，把一个大任务分割成若干个小任务，最终汇总每个小任务结果后得到大任务的计算结果。

### 二、如何使用
+ 只需要两个类即可：
+ ForkJoinPool
	+ `ForkJoinPool` 它和`ThreadPoolExecutor` 一样，也实现了Executor和ExecutorService接口。
	+ 它使用了一个无限队列来保存需要执行的任务，如果没有像构造函数中传入线程数量，则默认使用计算机CPU数量为线程数量
	+ 它是来运行 ForkJoinTask 任务的。
+ ForkJoinTask
	+ ForkJoinTask就是我们要分割的任务实现
	+ 框架帮我们封装好了两个实现类：
		+ RecursiveAction 用于没有返回结果的任务
		+ RecursiveTask 用于有返回结果的任务
+ 然后我们还要设置一个任务分割的阈值

### 三、代码案例实现
+ 实现需求：计算2个数之间的和
+ 代码如下：

```java
/**
 * 需求：计算2个数之间的和
 */
@Slf4j
public class ForkJoinDemo extends RecursiveTask<Long> {

    /**
     * 这个是我们要分割任务的最小阈值
     */
    private static final int threshold = 10;

    /**
     * 这个就是我们需要的参数
     */
    private long start;
    private long end;

    /**
     * 我们可以在构造器传入我们需要的参数
     */
    public ForkJoinDemo(long start, long end) {
        this.start = start;
        this.end = end;
    }

    /**
     * 这个就是我们要实现任务的地方
     * @return
     */
    @Override
    protected Long compute() {
        // 需要计算的总和
        long sum = 0;
        if(end-start>threshold){
            // 因为大于我们设置的最小阈值，所以需要分割
            long middle = (end+start)/2;
            //我们可以分裂成两个子任务
            ForkJoinDemo leftForkJoin = new ForkJoinDemo(start,middle);
            ForkJoinDemo rightForkJoin = new ForkJoinDemo(middle+1,end);

            //执行子任务
            leftForkJoin.fork();
            rightForkJoin.fork();

            // 等待子任务执行结束并合并结果
            Long leftSum = leftForkJoin.join();
            Long rightSum = rightForkJoin.join();
            sum = leftSum+rightSum;
        }else{
            // 小于或刚好等于阈值，那可以直接执行我们需要的业务
            for (long i = start; i <= end; i++) {
                sum+=i;
            }
        }
        return sum;
    }

    public static void main(String[] args) throws ExecutionException, InterruptedException {
        // 构造参数是并发线程数量，默认是CPU个数
        ForkJoinPool forkJoinPool = new ForkJoinPool();
		// 求15-50直接的 总和
        ForkJoinDemo forkJoinDemo = new ForkJoinDemo(15,50);
        ForkJoinTask<Long> forkJoinTask = forkJoinPool.submit(forkJoinDemo);
        Long sum = forkJoinTask.get();
        if (forkJoinTask.isCompletedAbnormally()) {
            log.error("forkJoin 发生了异常:",forkJoinDemo.getException());
        }
        System.out.println("结果="+sum);
        forkJoinPool.shutdown();
    }
}

```


+ 需求二： 求一个集合的总和
+ 代码如下：

```java
/**
 * 需求：计算集合的和
 */
@Slf4j
public class ForkJoinListDemo extends RecursiveTask<Long> {

    /**
     * 这个是我们要分割任务的最小阈值
     */
    private static final int threshold = 10;

    /**
     * 这个就是我们需要的参数
     */
    private List<Integer> list;

    /**
     * 我们可以在构造器传入我们需要的参数
     */
    public ForkJoinListDemo(List<Integer> list) {
        this.list = list;
    }

    /**
     * 这个就是我们要实现任务的地方
     * @return
     */
    @Override
    protected Long compute() {
        // 需要计算的总和
        long sum = 0;
        if(!ObjectUtils.isEmpty(list) && list.size()>threshold){
            // 因为大于我们设置的最小阈值，所以需要分割
            int middle = list.size() / 2;
            List<Integer> leftList = list.subList(0, middle);
            List<Integer> rightList = list.subList(middle, list.size());
            //我们可以分裂成两个子任务
            ForkJoinListDemo leftForkJoin = new ForkJoinListDemo(leftList);
            ForkJoinListDemo rightForkJoin = new ForkJoinListDemo(rightList);

            //执行子任务
            leftForkJoin.fork();
            rightForkJoin.fork();

            // 等待子任务执行结束并合并结果
            Long leftSum = leftForkJoin.join();
            Long rightSum = rightForkJoin.join();
            sum = leftSum+rightSum;
        }else{
            // 小于或刚好等于阈值，那可以直接执行我们需要的业务
            sum=list.stream().mapToInt(i -> i).sum();
        }
        return sum;
    }

    public static void main(String[] args) {
        List<Integer> list = new ArrayList<>();
        for (int i = 15; i <= 50; i++) {
            list.add(i);
        }
        ForkJoinPool forkJoinPool = new ForkJoinPool();
        ForkJoinListDemo forkJoinDemo = new ForkJoinListDemo(list);
        Long sum = forkJoinPool.invoke(forkJoinDemo);
        System.out.println("结果="+sum);
        forkJoinPool.shutdown();
    }
}
```

+ 上面的示例代码算是入门版的ForkJoin，只有理解掌握了，我们就可以写出复杂的ForkJoin了。
