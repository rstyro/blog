---
title: Quartz介绍与SpringBoot使用
date: 2019-10-28 15:03:45
tags: [Spring Boot]
categories: Java
---
## 一、Quartz简介
用过Quartz的都懂，Quartz就是一个完全由java编写的开源作业调度框架。
### 1、组件简介
需要使用这个框架需要知道几个词。
#### Job
+ `Job`是一个任务接口，开发者定义自己的任务须实现该接口，并重写`execute(JobExecutionContext context)`方法.
+ `Job`中的任务有可能并发执行，例如任务的执行时间过长，而每次触发的时间间隔太短，则会导致任务会被并发执行。
+ 为了避免出现上面的问题，可以在`Job`实现类上使用`@DisallowConcurrentExecution`,保证上一个任务执行完后，再去执行下一个任务


#### JobDetail
+ `JobDetail`是任务详情。
+ 包含有：任务名称，任务组名称，任务描述、具体任务Job的实现类、参数配置等等信息
+ 可以说`JobDetail`是任务的定义，而`Job`是任务的执行逻辑。

#### Trigger
+ Trigger是一个触发器,定义Job执行的时间规则。
+ 主要触发器:`SimpleTrigger`,`CronTrigger`,`CalendarIntervalTrigger`,`DailyTimeIntervalTrigger`。
+ `SimpleTrigger`:从某一个时间开始，以一定的时间间隔来执行任务,重复多少次。
+ `CronTrigger`: 适合于复杂的任务，使用cron表达式来定义执行规则。
+ `CalendarIntervalTrigger`:指定从某一个时间开始，以一定的时间间隔执行的任务,时间间隔比`SimpleTrigger`丰富
+ `DailyTimeIntervalTrigger`:指定每天的某个时间段内，以一定的时间间隔执行任务。并且它可以支持指定星期。
+ 所有的Trigger都包含了`StartTime`和`endTime`这两个属性，用来指定`Trigger`被触发的时间区间。
+ 所有的Trigger都可以设置`MisFire`策略.
+ `MisFire`策略是对于由于系统奔溃或者任务时间过长等原因导致Trigger在应该触发的时间点没有触发.
+ 并且超过了`misfireThreshold`设置的时间（默认是一分钟，没有超过就立即执行）就算misfire(失火)了。
+ 这个时候就该设置如何应对这种变化了。激活失败指令（`Misfire Instructions`）是触发器的一个重要属性

**发生Misfire 对于SimpleTrigger的处理策略**
```
//将任务马上执行一次。对于不会重复执行的任务，这是默认的处理策略。
MISFIRE_INSTRUCTION_FIRE_NOW = 1;

// 调度引擎重新调度该任务，立即执行任务，repeat count 保持不变，
// 按照原有制定的执行方案执行repeat count次，但是，如果当前时间，已经晚于end-time，那么这个触发器将不会再被触发
// 简单的说就是，错过了应该触发的时间没有按时执行，但是最终它还是以原来的重复次数执行，就是会比预计终止的时间晚。
MISFIRE_INSTRUCTION_RESCHEDULE_NOW_WITH_EXISTING_REPEAT_COUNT

//和上面的类似，区别就是不会立马执行，而是在下一个激活点执行，且超时期内错过的执行机会作废。　							
MISFIRE_INSTRUCTION_RESCHEDULE_NEXT_WITH_REMAINING_COUNT

// 这个也是重新调度任务，但是它只按照剩余次数来触发，
// 比如，应该执行10次，但是中间错过了3次没有执行，那它最终只会执行剩余次数 7次。
MISFIRE_INSTRUCTION_RESCHEDULE_NOW_WITH_REMAINING_REPEAT_COUNT

//在下一个激活点执行，并重复到指定的次数。
MISFIRE_INSTRUCTION_RESCHEDULE_NEXT_WITH_EXISTING_COUNT

// 立即执行任务，repeat count 保持不变，就算到了endtime,也继续执行
MISFIRE_INSTRUCTION_IGNORE_MISFIRE_POLICY
```

**发生Misfire 对于其他的Trigger**
```
//立刻执行一次，然后就按照正常的计划执行。
MISFIRE_INSTRUCTION_FIRE_ONCE_NOW

//目前不执行，然后就按照正常的计划执行。这意味着如果下次执行时间超过了end time，实际上就没有执行机会了。
MISFIRE_INSTRUCTION_DO_NOTHING
```

#### Scheduler
+ 调度器，主要是用来管理`Trigger`、`JobDetail`的。
+ `Scheduler`可以通过组名或者名称来对`Trigger`和`JobDetail`来进行管理
+ 一个`Trigger`只能对应一个`Job`，但是一个`Job`可以对应多个`Trigger`.
+ `Scheduler` 有两个实现类：`RemoteScheduler`、`StdScheduler`。但它是由`SchdulerFactory`创建的。
+ `SchdulerFactory`是个接口，它有两个实现类：`StdSchedulerFactory`、`DirectSchedulerFactory`

### 2、相关Builder介绍
Quartz提供了相应的Builder方便我们进行构造。

#### JobBuilder
这个主要方便我们构建任务详情，常用方法：
+ `withIdentity(String name, String group)`:配置Job名称与组名
+ `withDescription(String jobDescription)`: 任务描述
+ `requestRecovery()`: 出现故障是否重新执行，默认false
+ `storeDurably()`: 作业完成后是否保留存储，默认false
+ `usingJobData(String dataKey, String value)`: 配置单个参数key
+ `usingJobData(JobDataMap newJobDataMap)`: 配置多个参数，放入一个map
+ `setJobData(JobDataMap newJobDataMap)`: 和上面类似，但是这个参数直接指向newJobDataMap,直接设置的参数无效

#### TriggerBuilder
这个主要方便我们构建触发器，常用方法：
+ `withIdentity(String name, String group)`： 配置Trigger名称与组名
+ `withIdentity(TriggerKey triggerKey)`：	配置Trigger名称与组名
+ `withDescription(String triggerDescription)`： 描述
+ `withPriority(int triggerPriority)`： 设置优先级，默认是：5
+ `startAt(Date triggerStartTime)`： 设置开始时间
+ `startNow() `： 触发器立即生效
+ `endAt(Date triggerEndTime)`： 设置结束时间
+ `withSchedule(ScheduleBuilder<SBT> schedBuilder)`： 设置调度builder,下面的builder就是

#### SimpleScheduleBuilder
几种触发器类型之一，最简单常用的。常用方法：
+ `repeatForever()`：指定触发器将无限期重复
+ `withRepeatCount(int triggerRepeatCount)`：指定重复次数，总触发的次数=triggerRepeatCount+1
+ `repeatSecondlyForever(int seconds)`：每隔seconds秒无限期重复
+ `repeatMinutelyForever(int minutes)`：每隔minutes分钟无限期重复
+ `repeatHourlyForever(int hours)`：每隔hours小时无限期重复
+ `repeatSecondlyForever()`：每隔1秒无限期重复
+ `repeatMinutelyForever()`：每隔1分钟无限期重复
+ `repeatHourlyForever()`：每隔1小时无限期重复
+ `withIntervalInSeconds(int intervalInSeconds)`：每隔intervalInSeconds秒执行
+ `withIntervalInMinutes(int intervalInMinutes) `：每隔intervalInMinutes分钟执行
+ `withIntervalInHours(int intervalInHours)`：每隔intervalInHours小时执行
+ `withMisfireHandlingInstructionFireNow()`：失火后的策略为：`MISFIRE_INSTRUCTION_FIRE_NOW`


#### CronScheduleBuilder
算是非常常用的了，crontab 表达式，常用方法：
+ `cronSchedule(String cronExpression)`：使用cron表达式

简单的一笔
#### CalendarIntervalScheduleBuilder
常用方法：
+ `inTimeZone(TimeZone timezone)`：设置时区
+ `withInterval(int timeInterval, IntervalUnit unit)`：相隔多少时间执行，单位有：毫秒、秒、分、时、天、周、月、年
+ `withIntervalInSeconds(int intervalInSeconds)`：相隔秒
+ `withIntervalInWeeks(int intervalInWeeks)`：相隔周
+ `withIntervalInMonths(int intervalInMonths)`：相隔月

等等方法

#### DailyTimeIntervalScheduleBuilder
+ `withInterval(int timeInterval, IntervalUnit unit)`：相隔多少时间执行，单位有：秒、分、时，其他单位的不支持会报错
+ `withIntervalInSeconds(int intervalInSeconds)`：相隔秒
+ `withIntervalInMinutes(int intervalInMinutes)`：相隔分
+ `withIntervalInHours(int intervalInHours)`：相隔时
+ `onDaysOfTheWeek(Set<Integer> onDaysOfWeek)`：将触发器设置为在一周的指定日期触发。取值范围可以是1-7，1是星期天，2是星期一...
+ `onDaysOfTheWeek(Integer ... onDaysOfWeek)`：和上面一样，3是星期二...7是星期六
+ `onMondayThroughFriday()`：每星期的周一导周五触发
+ `onSaturdayAndSunday()`：每星期的周六周日触发
+ `onEveryDay()`：每天触发
+ `withRepeatCount(int repeatCount)`：重复次数，总的重复次数=`1 (at start time) + repeatCount`
+ `startingDailyAt(TimeOfDay timeOfDay)`：触发的开始时间
+ `endingDailyAt(TimeOfDay timeOfDay)`：触发的结束时间


### 3、基本使用
引用jar，就可以玩了。
#### 引用依赖

```
<dependency>
    <groupId>org.quartz-scheduler</groupId>
    <artifactId>quartz</artifactId>
    <version>2.3.2</version>
</dependency>
```
在pom.xml文件中，引入

### 简单例子：
```
public class Demo {
    public static final String COUNT = "count";

    //这个属性如不是static,那么每次都要实例这个任务类,始终打印为: 1
    private static int num = 1;

    public static void main(String[] args) throws SchedulerException {
        SchedulerFactory schedulerfactory = new StdSchedulerFactory();
//        Scheduler scheduler = schedulerfactory.getScheduler();
        Scheduler scheduler = StdSchedulerFactory.getDefaultScheduler();
        scheduler.start();
        JobDetail job = JobBuilder.newJob(HelloJob.class).withIdentity("jobName", "jobGroupName")
                .usingJobData(COUNT,num).build();
        // 各种builder 的基本使用
        SimpleScheduleBuilder simpleScheduleBuilder = SimpleScheduleBuilder.simpleSchedule().repeatForever().withIntervalInSeconds(3);
        CronScheduleBuilder cronScheduleBuilder = CronScheduleBuilder.cronSchedule("*/3 * * * * ?");
        CalendarIntervalScheduleBuilder calendarIntervalScheduleBuilder = CalendarIntervalScheduleBuilder.calendarIntervalSchedule().withInterval(3, DateBuilder.IntervalUnit.SECOND);
        DailyTimeIntervalScheduleBuilder dailyTimeIntervalScheduleBuilder = DailyTimeIntervalScheduleBuilder.dailyTimeIntervalSchedule().withIntervalInSeconds(3);

        Trigger trigger =  TriggerBuilder.newTrigger().withIdentity("jobName", "jobGroupName")
                .withSchedule(dailyTimeIntervalScheduleBuilder)
                .startNow().build();
        scheduler.scheduleJob(job, trigger);
    }

    // 保存在JobDataMap传递的参数
    @PersistJobDataAfterExecution
    @DisallowConcurrentExecution
    public static class HelloJob implements Job{
        @Override
        public void execute(JobExecutionContext context) throws JobExecutionException {
            JobDataMap jobDataMap = context.getJobDetail().getJobDataMap();
            int count = jobDataMap.getInt(COUNT);
            System.out.println("=========="+ LocalDateTimeUtils.formatDateTimeNow()+",count="+count);
            jobDataMap.put(COUNT,++num);
        }
    }
}
```

是不是感觉很简单，自己定义一个类，然后实现`Job`接口，重写`execute(JobExecutionContext context)` 方法，然后使用调度器去调度一下即可。
简单玩完了，和springboot整合一波。

## 二、与Springboot整合
这个才是重点，Springboot基本是一个Java程序猿必备的技能了。什么框架都得和它整一下。

### 1、引入依赖
```
<dependency>
	<groupId>org.springframework.boot</groupId>
	<artifactId>spring-boot-starter-quartz</artifactId>
</dependency>
```

spring官方自己都帮我们搞好了一些配置。

### 2、配置application.yml
如下：
```
spring:
  quartz:
    job-store-type: jdbc #数据库方式
    jdbc:
      initialize-schema: NEVER #不初始化表结构
    properties:
      org:
        quartz:
          scheduler:
            instanceId: AUTO #默认主机名和时间戳生成实例ID,可以是任何字符串，但对于所有调度程序来说，必须是唯一的 对应qrtz_scheduler_state INSTANCE_NAME字段
            #instanceName: clusteredScheduler #quartzScheduler
          jobStore:
            class: org.quartz.impl.jdbcjobstore.JobStoreTX #持久化配置
            driverDelegateClass: org.quartz.impl.jdbcjobstore.StdJDBCDelegate #我们仅为数据库制作了特定于数据库的代理
            useProperties: false #以指示JDBCJobStore将JobDataMaps中的所有值都作为字符串，因此可以作为名称 - 值对存储而不是在BLOB列中以其序列化形式存储更多复杂的对象。从长远来看，这是更安全的，因为您避免了将非String类序列化为BLOB的类版本问题。
            tablePrefix: qrtz_  #数据库表前缀
            misfireThreshold: 60000 #在被认为“失火”之前，调度程序将“容忍”一个Triggers将其下一个启动时间通过的毫秒数。默认值（如果您在配置中未输入此属性）为60000（60秒）。
            clusterCheckinInterval: 5000 #设置此实例“检入”*与群集的其他实例的频率（以毫秒为单位）。影响检测失败实例的速度。
            isClustered: true #打开群集功能
          threadPool: #连接池
            class: org.quartz.simpl.SimpleThreadPool
            threadCount: 10
            threadPriority: 5
            threadsInheritContextClassLoaderOfInitializingThread: true

```
+ 这里打算搞个集群版的，就算你部署多台服务器，定时任务会自己负载均衡，不会每台服务器都执行。
+ 表的生成，其实可以修改配置，启动的时候自己在数据库生成表。操作方法：
+ 修改:`spring.quartz.jdbc.initialize-schema: ALWAYS`、说明一下，
+ 这里有3个值可选：`ALWAYS`（每次都生成）、`EMBEDDED`（仅初始化嵌入式数据源）、`NEVER`（不初始化数据源）。
+ 表生成之后，再改为never即可。

### 3、怎么使用
+ 当我们引入`spring-boot-starter-quartz`的依赖后，springboot在启动的时候会自动加载配置类：`org.springframework.boot.autoconfigure.quartz.QuartzAutoConfiguration`。
+ 会帮我们初始化好调度器,源码：`SchedulerFactoryBean`实现`InitializingBean`，重写`afterPropertiesSet()` 里面就有了。
+ 而且Scheduler,Spring默认是帮我们启动的，不需要手动启动。
+ 使用如下：
```
@Autowired
private Scheduler scheduler;
```

spring会自己注入，通过工厂类`SchedulerFactoryBean`的` getObject()`方法。
搞个基本的增删改查,很简单，代码也没怎么优化，就这样吧。

```
@Component
public class JobService {

    @Autowired
    private Scheduler scheduler;


    /**
     * 增加一个job
     *
     * @param jobClass
     *            任务实现类
     * @param jobName
     *            任务名称(建议唯一)
     * @param jobGroupName
     *            任务组名
     * @param cron
     *            时间表达式 （如：0/5 * * * * ? ）
     * @param jobData
     *            参数
     */
    public void addJob(Class<? extends Job> jobClass, String jobName, String jobGroupName, String cron, Map jobData,Date endTime)
        throws SchedulerException {
        // 创建jobDetail实例，绑定Job实现类
        // 指明job的名称，所在组的名称，以及绑定job类
        // 任务名称和组构成任务key
        JobDetail jobDetail = JobBuilder.newJob(jobClass).withIdentity(jobName, jobGroupName).build();
        // 设置job参数
        if (jobData != null && jobData.size() > 0) {
            jobDetail.getJobDataMap().putAll(jobData);
        }
        // 定义调度触发规则
        // 使用cornTrigger规则
        // 触发器key
        Trigger trigger = TriggerBuilder.newTrigger().withIdentity(jobName, jobGroupName)
            .startAt(DateBuilder.futureDate(1, DateBuilder.IntervalUnit.SECOND))
            .withSchedule(CronScheduleBuilder.cronSchedule(cron)).startNow().build();
        if(endTime!=null){
            trigger.getTriggerBuilder().endAt(endTime);
        }
        // 把作业和触发器注册到任务调度中
        scheduler.scheduleJob(jobDetail, trigger);
    }



    public Trigger getTrigger(String jobName, String jobGroupName) throws SchedulerException {
        return scheduler.getTrigger(TriggerKey.triggerKey(jobName, jobGroupName));
    }

    /**
     * 删除任务一个job
     *
     * @param jobName
     *            任务名称
     * @param jobGroupName
     *            任务组名
     */
    public void deleteJob(String jobName, String jobGroupName) {
        try {
            scheduler.deleteJob(JobKey.jobKey(jobName, jobGroupName));
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    /**
     * 暂停一个job
     *
     * @param jobName
     * @param jobGroupName
     */
    public void pauseJob(String jobName, String jobGroupName) {
        try {
            JobKey jobKey = JobKey.jobKey(jobName, jobGroupName);
            scheduler.pauseJob(jobKey);
        } catch (SchedulerException e) {
            e.printStackTrace();
        }
    }

    /**
     * 恢复一个job
     *
     * @param jobName
     * @param jobGroupName
     */
    public void resumeJob(String jobName, String jobGroupName) {
        try {
            JobKey jobKey = JobKey.jobKey(jobName, jobGroupName);
            scheduler.resumeJob(jobKey);
        } catch (SchedulerException e) {
            e.printStackTrace();
        }
    }

    /**
     * 立即执行一个job
     *
     * @param jobName
     * @param jobGroupName
     */
    public void runJobNow(String jobName, String jobGroupName) {
        try {
            JobKey jobKey = JobKey.jobKey(jobName, jobGroupName);
            scheduler.triggerJob(jobKey);
        } catch (SchedulerException e) {
            e.printStackTrace();
        }
    }

    /**
     * 修改 一个job的 时间表达式
     *
     * @param jobName
     * @param jobGroupName
     * @param cron
     */
    public void updateJob(String jobName, String jobGroupName, String cron,Map jobData) {
        try {
            TriggerKey triggerKey = TriggerKey.triggerKey(jobName, jobGroupName);
            Trigger trigger = scheduler.getTrigger(triggerKey);
            if(trigger instanceof CronTrigger){
                CronTrigger cronTrigger = (CronTrigger) trigger;
                cronTrigger = cronTrigger.getTriggerBuilder().withIdentity(triggerKey)
                        .withSchedule(CronScheduleBuilder.cronSchedule(cron)).build();
            }else {
                // 这里其实可以删掉在添加即可，懒得写了
                throw new RuntimeException("格式转换错误");
            }
            // 设置job参数
            if (jobData != null && jobData.size() > 0) {
                trigger.getJobDataMap().putAll(jobData);
            }
            // 重启触发器
            scheduler.rescheduleJob(triggerKey, trigger);
        } catch (SchedulerException e) {
            e.printStackTrace();
        }
    }
}
```

+ 和上面得基本demo没什么两样，就是scheduler 并不需要我们去创建了。
+ 当部署多个服务时，也不会重复执行。且任务会负载均衡分配。


### 4、时间演练
Quartz 提供了下一次运行的时间，我们可以通过下一次运行的时间，比对是否符合我们的预期
```
public class Test {
    public static void main(String[] args) throws ParseException, SchedulerException {
        String cron = "0/10 * * * * ?";
        CronExpression cronExpression = new CronExpression(cron);
        Date nextValidTimeAfter = cronExpression.getNextValidTimeAfter(new Date());
        System.out.println("nextValidTimeAfter=" + nextValidTimeAfter);
        nextValidTimeAfter = cronExpression.getNextValidTimeAfter(nextValidTimeAfter);
        System.out.println("nextValidTimeAfter=" + nextValidTimeAfter);
        nextValidTimeAfter = cronExpression.getNextValidTimeAfter(nextValidTimeAfter);
        System.out.println("nextValidTimeAfter=" + nextValidTimeAfter);
        CalendarIntervalTrigger calendarIntervalTrigger =
            newTrigger().withIdentity("trigger3", "group1")
                .withSchedule(calendarIntervalSchedule().withIntervalInWeeks(3)).build();

        Date nextFireTime = calendarIntervalTrigger.getFireTimeAfter(new Date());
        System.out.println("nextFireTime=" + DateUtils.formatTime(nextFireTime));
        nextFireTime = calendarIntervalTrigger.getFireTimeAfter(nextFireTime);
        System.out.println("nextFireTime=" + DateUtils.formatTime(nextFireTime));
        nextFireTime = calendarIntervalTrigger.getFireTimeAfter(nextFireTime);
        System.out.println("nextFireTime=" + DateUtils.formatTime(nextFireTime));
        nextFireTime = calendarIntervalTrigger.getFireTimeAfter(nextFireTime);
        System.out.println("nextFireTime=" + DateUtils.formatTime(nextFireTime));

    }
}
```

每个 Tigger 都有一个`Date getFireTimeAfter(Date afterTime)` 的方法，返回的就是下一次运行的时间。

