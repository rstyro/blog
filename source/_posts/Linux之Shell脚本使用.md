---
title: Linux之Shell脚本使用
date: 2021-01-26 11:44:48
tags: [Linux]
categories: 网络运维
---

### 一、Shell简介
Shell 是一个用 C 语言编写的程序，它是用户使用 Linux 的桥梁。Shell 既是一种命令语言，又是一种程序设计语言。
Shell 是指一种应用程序，这个应用程序提供了一个界面，用户通过这个界面访问操作系统内核的服务。
Ken Thompson 的 sh 是第一种 Unix Shell，Windows Explorer 是一个典型的图形界面 Shell。

业界所说的 shell 通常都是指 shell 脚本，但读者朋友要知道，shell 和 shell script 是两个不同的概念。
Shell 脚本（shell script），是一种为 shell 编写的脚本程序，一般文件后缀为 `.sh`。

### 二、Shell环境
Shell 编程跟 JavaScript 编程一样，只要有一个能编写代码的文本编辑器和一个能解释执行的脚本解释器就可以了。
Linux 的 Shell 种类众多，常见的有：
+ Bourne Shell（`/usr/bin/sh`或`/bin/sh`）是 Unix 标准默认的 shell。
+ Bourne Again Shell（`/bin/bash`） 是 Linux 标准默认的 shell。
+ C Shell（`/usr/bin/csh`）
+ K Shell（`/usr/bin/ksh`）
+ Shell for Root（`/sbin/sh`）

### 三、Hello World
脚本的第一行一般是这样的：`#!/bin/bash`。
`#!` 是一个约定的标记，它告诉系统这个脚本需要什么解释器来执行，即使用哪一种 Shell。
写个hello world 入门，`vi helloworld.sh` 新建一个文件，编辑如下内容：
```bash
#!/bin/bash
echo "Hello World !"
```
保存退出后，给文件执行权限和执行，命令如下：
```
// 给helloworld.sh文件添加可执行权限
chmod +x helloworld.sh

// 在当前目录下执行
./helloworld.sh
```
echo 命令用于向窗口输出文本。
结果打印：Hello World !

![](helloworld.png)

写出HelloWorld，就入门了，把你在终端敲的命令写到脚本里面来执行，最终结果都是一致的。
接下来就可以写复杂的脚本了。要写复杂的脚本，首先得知道语法。

### 四、常用语法
下面列出常用的语法，或者我使用过的。

#### 1、注释
注释，可以说明你这段代码的作用，防止忘记或者让别人更加精彩你写的代码。
+ 单行注释 - 以 `#` 开头，到行尾结束。
+ 多行注释 - 以 `:<<EOF` 开头，到 `EOF` 结束。
```bash
# 这个是单行注释

:<<EOF
这里的内容都是注释的内容，不执行。
这个是多行注释，在这里的代码都不执行。
EOF

```

#### 2、echo
上面Hello World的例子用过，就是在屏幕中打印一个字符串的。
```bash
#!/bin/bash
# name这个就是定义的一个变量，后面讲，这里先用着
name=rstyro

# 简单的打印字符串
echo "打印字符串"
# 打印变量
echo "打印字符串加变量，变量=$name,name就是变量在前面加一个$即可"

# 变量用大括号括起来效果和上面一样
echo "打印字符串加变量，变量=${name},name就是变量在前面加一个$即可"

# 重定向到文件test.txt，是重新写入，不是追加
echo "test" > test.txt

# 表示在test.txt后面追加
echo "test" >> test.txt

# 打印 pwd命令返回的结果，这里使用的是反引号
echo `pwd`

# 单引号原样输出
echo 'pwd'

# 显示转义字符，打印结果："It is a test"
echo "\"It is a test\""
```

#### 3、变量
Bash 中没有数据类型，bash 中的变量可以保存一个数字、一个字符、一个字符串等等。同时无需提前声明变量，给变量赋值会直接创建变量。

**变量命名规则：**
注意，变量名和等号之间不能有空格，这可能和你熟悉的所有编程语言都不一样。同时，变量名的命名须遵循如下规则：
+ 命名只能使用英文字母，数字和下划线，首个字符不能以数字开头。
+ 中间不能有空格，可以使用下划线（`_`）。
+ 不能使用标点符号。
+ 不能使用bash里的关键字（可用help命令查看保留关键字）。

**使用变量：**
使用一个定义过的变量，只要在变量名前面加美元符号即可，如下：

```bash
# 这个就是我定义的变量，值为rstyro
name=rstyro
# 使用变量，如下两种方式
echo $name
# 变量名外面的花括号是可选的，加不加都行，加花括号是为了帮助解释器识别变量的边界
echo ${name}name

# 使用 readonly 命令可以将变量定义为只读变量，只读变量的值不能被改变。
readonly blogUrl=http://rstyro.gitee.io/blog/

# 尝试修改会报错
blogUrl=http://rstyro.github.io/blog/

MYNAME=rstyro
# 使用 unset 命令可以删除变量，变量被删除后不能再次使用。unset 命令不能删除只读变量
unset MYNAME
# 没任何输出
echo $MYNAME
```

**变量类型：**
+ 局部变量
局部变量在脚本或命令中定义，仅在当前shell实例中有效，其他shell启动的程序不能访问局部变量。
+ 环境变量
所有的程序，包括shell启动的程序，都能访问环境变量，有些程序需要环境变量来保证其正常运行。必要的时候shell脚本也可以定义环境变量。
+ shell变量
shell变量是由shell程序设置的特殊变量。shell变量中有一部分是环境变量，有一部分是局部变量，这些变量保证了shell的正常运行

#### 4、printf
Shell 的另一个输出命令 printf，printf 命令模仿 C 程序库（library）里的 printf() 程序。
printf 由 POSIX 标准所定义，因此使用 printf 的脚本比使用 echo 移植性好。
printf 使用引用文本或空格分隔的参数，外面可以在 printf 中使用格式化字符串，还可以制定字符串的宽度、左右对齐方式等。
默认 printf 不会像 echo 自动添加换行符，我们可以手动添加 \n。

**语法：**
```bash
# format-string: 为格式控制字符串，arguments: 为参数列表
printf  format-string  [arguments...]
```
实例：
```
#!/bin/bash

printf "%-10s %-8s %-4s\n" 姓名 性别 体重kg  
printf "%-10s %-8s %-4.2f\n" 郭靖 男 66.1234
printf "%-10s %-8s %-4.2f\n" 杨过 男 48.6543
printf "%-10s %-8s %-4.2f\n" 郭芙 女 47.9876
```
执行脚本输出：
```
姓名     性别   体重kg
郭靖     男      66.12
杨过     男      48.65
郭芙     女      47.99
```
**参数解析：**
+ **%s %c %d %f**
都是格式替代符，`％s` 输出一个字符串，`％d` 整型输出，`％c` 输出一个字符，`％f` 输出实数，以小数形式输出。
+ **%-10s**
指一个宽度为 10 个字符（`-` 表示左对齐，没有则表示右对齐），任何字符都会被显示在 10 个字符宽的字符内，如果不足则自动以空格填充，超过也会将内容全部显示出来。
+ **%-4.2f**
指格式化为小数，其中 `.2` 指保留2位小数。


#### 5、字符串
字符串是shell编程中最常用最有用的数据类型，字符串可以用单引号，也可以用双引号，也可以不用引号。

**单引号字符串的限制：**
+ 单引号里的任何字符都会原样输出，单引号字符串中的变量是无效的；
+ 单引号字串中不能出现单独一个的单引号（对单引号使用转义符后也不行），但可成对出现，作为字符串拼接使用。

**双引号的优点：**
+ 双引号里可以有变量
+ 双引号里可以出现转义字符

**字符串拼接**
```
#!/bin/bash
your_name="rstyro"
# 使用双引号拼接
greeting="hello, "$your_name" !"
greeting_1="hello, ${your_name} !"
echo $greeting  $greeting_1

# 使用单引号拼接
greeting_2='hello, '$your_name' !'
greeting_3='hello, ${your_name} !'
echo $greeting_2  $greeting_3
```
如上输出如下：
```
hello, rstyro ! hello, rstyro !
hello, rstyro ! hello, ${your_name} !
```

**字符串方法**
```
#!/bin/bash
string="rstyro"
# 输出字符串长度
echo ${#string} # 输出 6

string="rstyro.gitee is a great site"
# 字符串截取，从索引1开始，截取4个字符。索引从0开始
echo ${string:1:5} # 输出 styro

# 字符串位置，查找字符 i 或 g 的位置(哪个字母先出现就计算哪个)
echo `expr index "$string" ig` # 输出 8

# 下面的所有例子，“*”只是一个通配符可以不要
# 从左向右截取最后一个abc后的字符串，
${varible##*abc} 

# 从左向右截取第一个abc后的字符串
${varible#*abc}

# 从右向左截取最后一个abc后的字符串
${varible%%abc*}

# 从右向左截取第一个abc后的字符串
${varible%abc*}

```

#### 6、数组
bash支持一维数组（不支持多维数组），并且没有限定数组的大小。
类似于 C 语言，数组元素的下标由 0 开始编号。获取数组中的元素要利用下标，下标可以是整数或算术表达式，其值应大于或等于 0
在 Shell 中，用括号来表示数组，数组元素用"空格"符号分割开。定义数组的一般形式为：

**定义数组：**
```bash
#!/bin/bash

# 格式：数组名=(值1 值2 ... 值n)
# 方式一
array_name1=(value0 value1 value2 value3)

# 方式二
array_name2=(
value0
value1
value2
value3
)

# 方式三，可以不使用连续的下标，而且下标的范围没有限制
array_name3=([0]=rstyro [2]=gitee [1]=blog [888]=恭喜发财)

```

**操作数组：**
获取数组和操作如下：
```
# 打印array_name1 索引为1 的元素
echo ${array_name1[1]}
# 使用@ 或 * 可以获取数组中的所有元素，如下
echo ${array_name3[@]} 
# 或者
echo ${array_name3[*]}



# 取得数组元素的个数
echo ${#array_name1[@]}
# 或者
echo ${#array_name1[*]}


# 取得数组单个元素的长度
echo ${#array_name3[888]}


# 给数组添加元素
# 使用此方式添加元素后，数组中原有元素的下标会重置，会从0开始变成连续的
# 其次，双引号不能省略，否则，当数组array_name中存在包含空格的元素时会按空格将元素拆分成多个。
array_name3=(新年快乐 "${array_name3[@]}" 红包拿来)
echo ${array_name3[@]}

# 根据下标添加元素
array_name3[7]=66大顺

# 从数组中删除数据
unset array_name3[3]
echo ${array_name3[@]}

# 删除整个数组
unset array_name3
echo "删除后的arrayname3=${array_name3[@]}"
```

输出：
```
value1
rstyro blog gitee 恭喜发财
rstyro blog gitee 恭喜发财
4
4
4
新年快乐 rstyro blog gitee 恭喜发财 红包拿来
新年快乐 rstyro blog gitee 恭喜发财 红包拿来 66大顺
新年快乐 rstyro blog 恭喜发财 红包拿来 66大顺
删除后的arrayname3=
```

#### 7、test
+ test 是 Shell 内置命令，用来检测某个条件是否成立。
+ test 通常和 if 语句一起使用，并且大部分 if 语句都依赖 test
+ 它可以进行数值、字符和文件三个方面的测试
+ test 命令也可以简写为`[]`，它的用法为:`[ expression(表达式) ]`
+ 注意`[]`和`expression`之间的空格，这两个空格是必须的，否则会导致语法错误。`[]`的写法更加简洁，比 test 使用频率高.

```
#!/bin/bash

# -eq	等于则为真
# -ne	不等于则为真
# -gt	大于则为真
# -ge	大于等于则为真
# -lt	小于则为真
# -le	小于等于则为真

a=10
b=100
if test $a -eq $b; then
    echo "a等于b"
elif test $a -gt $b; then
    echo "a大于b"
else
    echo "a小于b"
fi



# 字符串测试
str1="ru1noob"
str2="runoob"
if test $str1 = $str2
then
    echo '两个字符串相等!'
else
    echo '两个字符串不相等!'
fi
```

#### exit

+ exit 是一个 Shell 内置命令，用来退出当前 Shell 进程，并返回一个退出状态；
+ 使用`$?`可以接收这个退出状态。
+ exit 命令可以接受一个整数值作为参数，代表退出状态。如果不指定，默认状态值是 0
+ exit 退出状态只能是一个介于 0~255 之间的整数，其中只有 0 表示成功，其它值都表示失败

编写下面的脚本，并命名为 test.sh：
```
#!/bin/bash
echo "新年快乐"
exit 88
echo "恭喜发财"
```

执行结果：
```
[root@kvm-yanfa ods]# chmod +x test.sh 
[root@kvm-yanfa ods]# 
[root@kvm-yanfa ods]# ./test.sh 
新年快乐
[root@kvm-yanfa ods]# 
[root@kvm-yanfa ods]# echo $?
88
[root@kvm-yanfa ods]# 
[root@kvm-yanfa ods]# 

```


### 五、流程控制
流程控制指令是指会改变程序运行顺序的指令，可能是运行不同位置的指令，或是在二段（或多段）程序中选择一个运行。

#### 1、if判断
if判断条件是否满足，满足则执行，语法格式如下：
```bash
# 第一种格式：如果else分支没有语句执行，就不要写这个else。
if condition
then
    command1 
    command2
    ...
    commandN 
fi

# 第二种格式：

if condition
then
    command1 
    command2
    ...
    commandN
else
    command
fi

# 第三种格式：
if condition1
then
    command1
elif condition2 
then 
    command2
else
    commandN
fi
```

实例：
```
#!/bin/bash

age=25

if test $age -le 2; then
    echo "婴儿"
elif test $age -ge 3 && test $age -le 8; then
    echo "幼儿"
elif [ $age -ge 9 ] && [ $age -le 17 ]; then
    echo "少年"
elif [ $age -ge 18 ] && [ $age -le 25 ]; then
    echo "成年"
elif test $age -ge 26 && test $age -le 40; then
    echo "青年"
elif test $age -ge 41 && [ $age -le 60 ]; then
    echo "中年"
else
    echo "老年"
fi
```

+ 条件表达式要放在方括号之间，并且要有空格

#### 2、while
+ while 循环是 Shell 脚本中最简单的一种循环，当条件满足时，while 重复地执行一组语句，当条件不满足时，就退出 while 循环。
+ 格式如下：
```
while condition
do
    command
done
```

**例子：**
```
#!/bin/bash
i=1
sum=0
while ((i <= 10))
do
    ((sum += i))
    ((i++))
done
echo "The sum is: $sum"
# 输出：The sum is: 55
```

**无限循环**

```bash
#!/bin/bash

# 方式一
while :
do
    echo "一直输出"
done

# 方式二
while true
do
    echo "一直输出"
done
```


#### 3、until
unti 循环和 while 循环恰好相反，当判断条件不成立时才进行循环，一旦判断条件成立，就终止循环。
```
#!/bin/bash
i=1
sum=0
until ((i > 10))
do
    ((sum += i))
    ((i++))
done
echo "The sum is: $sum"
# 输出：The sum is: 55
```

#### 4、for循环、
for循环格式如下：
```
for var in item1 item2 ... itemN
do
    command1
    command2
    ...
    commandN
done
```

实例：
```
#!/bin/bash

arr=(新年快乐 恭喜发财 红包拿来)

for item in ${arr[@]}
do
 echo "$item"
done
```
或者上面的加法例子：
```
#!/bin/bash

i=0
sum=0

for ((;i<=10;i++))
do
	((sum += i))
done

echo "the sum is $sum"

```

+ 格式：for(( 初始化语句; 判断条件; 自增或自减 ))
+ for 循环中的 exp1（初始化语句）、exp2（判断条件）和 exp3（自增或自减）都是可选项，都可以省略（但分号;必须保留）


#### 5、break与continue
在循环过程中，有时候需要在未达到循环结束条件时强制跳出循环，Shell使用两个命令来实现该功能：break和continue。
实例：
```
#!/bin/bash

echo "请输入数字："
for (( ; ; ))
do
	# 等待输入一个
	read num
	if (($num < 0)); then
		echo "数字不符合请继续输入"
		continue;
	elif (( $num > 0)); then
		echo "你输入的是：$num"
	else
		echo "你选择退出"
		break;
	fi
	echo "--------------------"
done
```
+ 如上，输入大于0的数，就一直可以输入，输入小于0提示继续输入，输入0或字符则退出
+ break命令允许跳出所有循环（终止执行后面的所有循环）
+ continue 用来结束本次循环，直接跳到下一次循环，如果循环条件成立，还会继续循环。

#### 6、case in 
Shell case语句为多选择语句。可以用case语句匹配一个值与一个模式，如果匹配成功，执行相匹配的命令。case语句格式如下：
```
case 值 in
模式1)
    command1
    command2
    ...
    commandN
    ;;
模式2）
    command1
    command2
    ...
    commandN
    ;;
esac
```

实例：
```
#!/bin/bash

printf "请输入星期数字: "
# read 等待接收我们输入的值
read num
case $num in
    1)
        echo "Monday"
        ;;
    2)
        echo "Tuesday"
        ;;
    3)
        echo "Wednesday"
        ;;
    4)
        echo "Thursday"
        ;;
    5)
        echo "Friday"
        ;;
    6)
        echo "Saturday"
        ;;
    7)
        echo "Sunday"
        ;;
    *)
        echo "error"
esac
```

+ case工作方式如上所示。取值后面必须为单词in，每一模式必须以右括号结束
+ 取值可以为变量或常数。匹配发现取值符合某一模式后，其间所有命令开始执行直至 `;;`
+ 如果无一匹配模式，使用星号 * 捕获该值，再执行后面的命令。
+ 每个 case 分支用右圆括号开始，用两个分号 ;; 表示 break，esac（就是 case 反过来）作为结束标记。


### 六、运算符

#### 1、关系运算符
实例：
```
#!/bin/bash

a=50
b=70

# 关系运算符
# -eq	检测两个数是否相等，相等返回 true。	 
# -ne	检测两个数是否相等，不相等返回 true。 
# -gt	检测左边的数是否大于右边的，如果是，则返回 true。 
# -lt	检测左边的数是否小于右边的，如果是，则返回 true。 
# -ge	检测左边的数是否大于等于右边的，如果是，则返回 true。 
# -le	检测左边的数是否小于等于右边的，如果是，则返回 true。 

if [ $a -nq $b]
then
	echo "a b 不相等"
fi
```
+ 关系运算符只支持数字，不支持字符串，除非字符串的值是数字。


#### 2、布尔运算符

实例：
```
#!/bin/bash
a=50
b=70
# !		非运算，表达式为 true 则返回 false， 
# -o	或运算，有一个表达式为 true 则返回 true。	 
# -a	与运算，两个表达式都为 true 才返回 true。

if [ $a -gt 60 -o $b -gt 60 ]
then
	echo "a与b至少有一个大于60"
fi
```


#### 3、逻辑运算符

实例：
```
#!/bin/bash
a=50
b=70
# &&	逻辑的 AND	
# ||	逻辑的 OR

if [[ $a -gt 60 || $b -gt 60 ]]
then
	echo "a与b至少有一个大于60"
fi

# 整数判断可以用(()) 双括号
if (( $a > 60 || $b > 60 ))
then
    echo "a与b至少有一个大于60"
fi
```

+ 注意使用逻辑运算符要两个方括号


#### 4、字符串运算符

```
#!/bin/bash

# =		检测两个字符串是否相等，相等返回 true。	 
# !=	检测两个字符串是否相等，不相等返回 true。	 
# -z	检测字符串长度是否为 0，为 0 返回 true。	 
# -n	检测字符串长度是否为 0，不为 0 返回 true。	 
# $		检测字符串是否为空，不为空返回 true。

str1="abc"
str2="efg"

if [ $str1 = $str2 ]
then
   echo "字符串相等"
fi

if [ -n "$a" ]
then
   echo "-n $a : 字符串长度不为 0"
fi

if [ $a ]
then
   echo "$a : 字符串不为空"
else
   echo "$a : 字符串为空"
fi
```



#### 5、文件测试运算符

文件测试运算符用于检测 Unix 文件的各种属性。

属性如下：

|操作符<div style="width:90px;"></div>|	说明|	举例<div style="width:200px;"></div>|
|--|--|--|
|`-b file` |	检测文件是否是块设备文件，如果是，则返回 true。|	`[ -b $file ]` 返回 false。|
|`-c file` |	检测文件是否是字符设备文件，如果是，则返回 true。|	`[ -c $file ]` 返回 false。|
|`-d file` |	检测文件是否是目录，如果是，则返回 true。|	`[ -d $file ]` 返回 false。|
|`-f file` |	检测文件是否是普通文件（既不是目录，也不是设备文件），如果是，则返回 true。|	`[ -f $file ]` 返回 true。|
|`-g file` |	检测文件是否设置了 SGID 位，如果是，则返回 true。|	`[ -g $file ]` 返回 false。|
|`-k file` |	检测文件是否设置了粘着位(Sticky Bit)，如果是，则返回 true。|	`[ -k $file ]` 返回 false。|
|`-p file` |	检测文件是否是有名管道，如果是，则返回 true。|	`[ -p $file ]` 返回 false。|
|`-u file` |	检测文件是否设置了 SUID 位，如果是，则返回 true。|	`[ -u $file ]` 返回 false。|
|`-r file` |	检测文件是否可读，如果是，则返回 true。|	`[ -r $file ]` 返回 true。|
|`-w file` |	检测文件是否可写，如果是，则返回 true。|	`[ -w $file ]` 返回 true。|
|`-x file` |	检测文件是否可执行，如果是，则返回 true。|	`[ -x $file ]` 返回 true。|
|`-s file` |	检测文件是否为空（文件大小是否大于0），不为空返回 true。|	`[ -s $file ]` 返回 true。|
|`-e file` |	检测文件（包括目录）是否存在，如果是，则返回 true。|	`[ -e $file ]` 返回 true。|


实例：
```
#!/bin/bash

file="/var/test.sh"
if [ -r $file ]
then
   echo "文件可读"
else
   echo "文件不可读"
fi
```

### 七、shell传递参数
+ 运行 Shell 脚本文件时我们可以给它传递一些参数，这些参数在脚本文件内部可以使用`$n`的形式来接收。
+ 例如，`$1` 表示第一个参数，`$2` 表示第二个参数，依次类推。
+ 除了 `$n`，Shell 中还有 `$#`、`$*`、`$@`、`$?`、`$$` 几个特殊参数


实例：
```
#!/bin/bash

echo "Shell 传递参数实例！";
echo "执行的文件名：$0";
echo "第一个参数为：$1";
echo "第二个参数为：$2";
echo "第三个参数为：$3";
```

为脚本设置可执行权限，并执行脚本，输出结果如下所示：
```
$ chmod +x test.sh 
$ ./test.sh 1 2 3
Shell 传递参数实例！
执行的文件名：./test.sh
第一个参数为：1
第二个参数为：2
第三个参数为：3
```

特殊字符参数与含义:

|变量|	含义|
|--|--|
|$0|	当前脚本的文件名。|
|$n|（n≥1）	传递给脚本或函数的参数。n 是一个数字，表示第几个参数。例如，第一个参数是 $1，第二个参数是 $2。|
|$#|	传递给脚本或函数的参数个数。|
|$*|	以一个单字符串显示所有向脚本传递的参数。如"$*"用「"」括起来的情况、以"$1 $2 … $n"的形式输出所有参数。|
|$@|	与$*相同，但是使用时加引号，并在引号中返回每个参数。如"$@"用「"」括起来的情况、以"$1" "$2" … "$n" 的形式输出所有参数。|
|$?|	显示最后命令的退出状态。0表示没有错误，其他任何值表明有错误|
|$$|	当前 Shell 进程 ID。对于 Shell 脚本，就是这些脚本所在的进程 ID。|
|$!|	后台运行的最后一个进程的ID号|

**$* 与 $@ 区别：**
+ 相同点：都是引用所有参数。
+ 不同点：只有在双引号中体现出来。假设在脚本运行时写了三个参数 1、2、3，，则 " * " 等价于 "1 2 3"（传递了一个参数），而 "@" 等价于 "1" "2" "3"（传递了三个参数）。


### 八、函数
函数的本质是一段可以重复使用的脚本代码，这段代码被提前编写好了，放在了指定的位置，使用时直接调取即可。
函数的格式：
```
function methodName() {
    // doing
    [return value]
}
```
+ function是 Shell 中的关键字，专门用来定义函数；
+ methodName 是函数名；
+ 由`{ }`包围的部分称为函数体，调用一个函数，实际上就是执行函数体中的代码。
+ return value表示函数的返回值，其中 return 是 Shell 关键字，专门用在函数中返回一个值；这一部分可以写也可以不写。如果不写，将以最后一条命令运行结果，作为返回值
+ 如果你嫌麻烦，函数定义时也可以不写 function 关键字

**实例一：**
```
#!/bin/bash

# 定义函数
function myblog(){
	echo 'http://rstyro.gitee.io/blog'
}

# 函数调用
myblog

```

+ 所有函数在使用前必须定义。这意味着必须将函数放在脚本开始部分，直至shell解释器首次发现它时，才可以使用。调用函数仅使用其函数名即可
+ 函数返回值在调用该函数后通过 $? 来获得

**实例二：**
```
#!/bin/bash

add(){
    echo "这个函数会对输入的两个数字进行相加运算..."
    echo "输入第一个数字: "
    read a
    echo "输入第二个数字: "
    read b
    echo "两个数字分别为 $a 和 $b !"
    echo $(( a+b ))
    return $(( a+b ))
}
add
# 函数返回值在调用该函数后通过 $?来获取
echo "输入的两个数字之和为 $? !"
# 再次调用，就是上一条命令（echo）的返回结果了,0代表成功
echo $?

```

执行结果如下：
![](test.png)

+ 发现 `$?` 最大能接收的值是：255，刚好是一个byte类型。
+ 连续使用两次 `echo $?`，得到的结果不同。第一次`$?`是add 函数的返回值，第二次就是 `echo "输入的两个数字之和为 $? !"` 的返回值了。



**实例三：**
+ 方法带参数的调用方式

```
#!/bin/bash

add(){
    echo "两个数字分别为 $1 和 $2 !"
    echo $1+$2=$(($1+$2))
    return $(($1+$2))
}

# 在调用的方法后面添加参数即可
add 1 2
```



### 九、多线程用法
shell也是有多线程用法的，先看例子：

#### 1、串行例子
```
#!/bin/bash
begin_time=`date "+%s"`
for i in `seq 1 10`
do
	sleep 1s
    echo "i=$i"
done

end_time=`date "+%s"`

offset_time=`expr $end_time - $begin_time`

echo "开始时间=${begin_time}s"
echo "结束时间=${end_time}s"


echo "总耗时=${offset_time}s"
```
+ 上面的例子很简单，每隔1秒输出1到10的数，最后打印总耗时
+ seq：是squeue一个序列的缩写，`seq 1 10` 是输出1到10的整数
+ 结果耗时是：`10s`,可以知道执行结果是串行的。符合逻辑
+ 现在来试试多线程的写法，需要用到`& wait`。


#### 2、并行例子
```
#!/bin/bash
begin_time=`date "+%s"`
for i in `seq 1 10`
do
{
	sleep 1s
    echo "i=$i"
} &
done

# 等待子进程执行完，继续往下走
wait

end_time=`date "+%s"`

offset_time=`expr $end_time - $begin_time`

echo "begin_time=$begin_time"
echo "end_time=$end_time"

echo "offset_time=${offset_time}s"
```

+ 多条命令用`{}` 括起来然后在使用`&`
+ 然后在for后面使用`wait` 等待所以子进程执行结束。
+ 最终offset_time打印为：`offset_time=1s` 所以它们是并行执行的。


### 十、常用的脚本命令
记录一下吧
#### 1、获取本机IP地址 
```
# 方式一
ip addr | awk '/^[0-9]+: / {}; /inet.*global/ {print gensub(/(.*)\/(.*)/, "\\1", "g", $2)}'

# 方式二
ip -o -4 addr show up primary scope global | awk '{print $2,$4}'


# ifconfig -a  　　　　 和window下执行此命令一样道理，返回本机所有ip信息
# grep inet               　   截取包含ip的行
# grep -v 127.0.0.1      去掉本地指向的那行
# grep -v inet6             去掉包含inet6的行
# awk { print $2}         $2 表示默认以空格分割的第二组 同理 $1表示第一组​
# tr -d "addr:               删除"addr:"这个字符串
ifconfig -a |grep inet |grep -v 127.0.0.1 |grep -v inet6|awk '{print $2}'
```

#### 2、获取Java进程PID进程
```
pid=`ps -ef | grep yourJavaServiceName.jar |grep -v color |grep -v grep | awk '{print $2}'`
echo $pid
```

#### 3、多线程扫描相同网段ip
```
#!/bin/bash

# 网段前缀
ip_prefix=192.168.2

for i in `seq 1 254`
do
{
	ping $ip_prefix.$i -fqc2 | grep -q "rtt" && echo "$ip_prefix.$i yes" || echo "$ip_prefix.$i no"
   
} &
done
wait  ##等待所有子后台进程结束

echo "over..."
```
+ ` & 与 wait` 结合使用就相当于多线程。
+ `&` 是后台执行（新建子进程）的意思
+ `wait` 等待所有子进程结束继续往下执行。


#### 4、通过mac地址获取ip
```
#!/bin/bash

# 参数就是mac地址
mac=$1
if [[ $mac = "" ]]
then
	echo "mac不能为空"
	exit 0
fi

echo "mac=$mac"
ip=`ip neigh show | grep $mac | awk '{print $1}'`
echo "ip=$ip"
```

+ 执行脚本的参数就是mac地址，例：`./macToIp.sh 52:54:00:b0:4f:13` 这样执行即可。
+ 这个可以先通过扫描同网段的ip，然后在查
+ 类似这个 `cat /proc/net/arp | grep 52:54:00:b0:4f:13`，但是arp有时会有多条（缓存）


#### 5、其他
```bash
# 获取脚本执行的当前路径
CUR_PATH=$( cd ${0%/*} && pwd )

# 获取脚本执行的当前路径
CUR_PATH=$(cd "$(dirname "$0")" && pwd)

# 查看当前目录下的 .jar 文件名得到，例：./abc.jar
# 其中 ”-maxdepth 1“ 1代表只查当前目录，2是查看当前目录和其子目录，3子目录的子目录...
JAR=$(find . -maxdepth 1 -name "*.jar")
# 去掉前面的 ./   , 例： abc.jar
JAR="${JAR:2}"

# 完整路径
JAR_PATH="$CUR_PATH/$JAR"


```


**参考链接：**
+ [https://www.runoob.com/linux/linux-shell.html](https://www.runoob.com/linux/linux-shell.html)
