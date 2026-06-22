# shell笔记

## Shabang

shabang是指的是出现在文本文件的第一行前两个字符`#!`

- 以`#!/bin/sh`开头的文件，程序在执行的时候会调用`/bin/sh`，也就是bash解释器
- 以`#!/usr/bin/python`开头的文件，代表指定python解释器去执行
- 以`#!/usr/bin/env`解释器名称，是一种在不同平台上都能正确找到解释器的办法

注：

- 如果脚本未指定shebang，脚本执行的时候，默认用当前shell去解释脚本，即`$SHELL`
- 如果shebang指定了可执行的解释器，如`/bin/bash` `/usr/bin/python`，脚本在执行时，文件名会作为参数传递给解释器
- 如果`#!`指定的解释程序没有可执行权限，则会报错“bad interpreter:Permission denied”。
- 如果`#!`指定的解释程序不是一个可执行文件，那么指定的解释程序会被忽略，转而交给当前的SHELL去执行这个脚本。
- 如果#!指定的解释程序不存在，那么会报错“bad interpreter: No such file or directory”。
- #!之后的解释程序，需要写其绝对路径（如：`#!/bin/bash`），它是不会自动到$PATH中寻找解释器的。
- 如果你使用"`bash test.sh`"这样的命令来执行脚本，那么`#!`这一行将会被忽略掉，解释器当然是用命令行中显式指定的bash。

## 父子shell及变量

父shell的变量是不能继承给子shell的（反之亦然），每次使用`bash xxx.sh`执行一个脚本的时候，系统都是默认开启一个新的子shell来执行这个脚本，而使用`source xxx.sh`则是在当前shell执行脚本，会保留当前shell的环境变量

>tips：Linux中，单引号变量不识别其中的特殊语法，双引号能识别其中的特殊语法
>
>```bash
>name="歪比巴卜"
>name2='${name}' #这里如果执行echo ${name2}会打印${name}
>
>name3="${name}" #这里echo ${name3}会打印"歪比巴卜"
>```
>
>

### 环境变量设置

环境变量一般指的是用export内置命令导出的变量，用于定义shell的运行环境、保证shell命令的正确执行。

shell通过环境变量确定登录的用户名、PATH路径、文件系统等各种应用。

环境变量可以在命令行中临时创建，但是用户退出shell终端，变量即丢失，如要永久生效，需要修改环境变量配置文件

- 用户个人配置文件~/.bash_profile、~/.bashrc远程登录用户特有文件
- 全局配置文件/etc/profile、etc/bashrc，且系统建议最好创建在/etc/profile.d/，而非直接修改主文件，修改全局配置文件，影响所有登录系统的用户

**检查系统环境变量的命令**

- `set`，输出所有变量，包括全局变量、局部变量
- `env`，只显示全局变量
- `declare`，输出所有的变量，如同set
- `export`，显示和设置环境变量值

**撤销环境変量**

- `unset 变量名`，删除变量或函数。

**设置只读变量**

- `readonly`，只有shell结束，只读变量失效

**环境变量初始化及加载顺序：**

1. 系统会先加载`/etc/profile`中的变量作为全局环境变量
2. 加载并执行`/etc/profile.d`目录中的脚本
3. 运行`$HOME/.bash_profile`
4. 运行`$HOME/.bashrc`
5. 运行`/etc/bashrc`

## 特殊变量

shell的特殊变量，用在如脚本，函数传递参数使用，有如下特殊的，位置参数变量

```BASH
$0	获取shell脚本文件名，以及脚本路径
$n	获取shell脚本的第n个参数,n在1~9之间，如$1，$2，$9，大于9则需要写，${10}，参数空格隔开
$#	获取执行的shel1脚本后面的参数总个数
$*	获取shell脚本所有参数，不加引号等同于$@作用，加上引号"$*"作用是接收所有参数为单个字符串，"$1 $2.
$@	不加引号，效果同上，加引号，是接收所有参数为独立字符串，如"$1”“$2”"$3”...，空格保留
```

### 特殊状态变量

```bash
$?	上一次命令执行状态返回值，0正确，非0失败
$$	当前shell脚本的进程号
$!	上一次后台进程的PID
$_	再次之前执行的命令，最后一个参数

查找方式manbash
	搜索Special Parameters
```

内置shell命令：

echo

> -n 不换行输出
>
> -e 解析字符串中的特殊符号
>
> \n 换行
>
> \t 制表符
>
> \r 回车
>
> \b 退格

eval

> 多命令执行，命令与命令之间用`;`隔开

exec

> 不创建子进程来执行命令，在命令执行完后，自动执行exit（会导致命令执行完后退出当前shell）

export

read

shift



## shell子串

```bash
`${变量}`	#返回变量值
`${#变量}`	#返回变量长度，字符长度
`${变量:n}`	#返回变量第n+1之后的字符（从0开始）
`${变量:start:length}`	#提取start之后的length限制的字符
`${变量#word}`	#从变量开头删除最短匹配的word子串
`${变量##word}`	#从变量开头，删除最长匹配的word
`${变量%word}`	#从变量结尾删除最短的word
`${变量%%word}`	#从变量结尾开始删除最长匹配的word（注意，这是反着匹配的，是先匹配你提供的结尾串，最后匹配你提供的开头串）
`${变量/pattern/string}`	#用string代替第一个匹配的pattern
`${变量//pattern/string}`	#用string代替所有的pattern
```



## 特殊shell扩展变量

```bash
#如果parameter变量值为空，返回word字符串（并不会赋值给parameter）
${parameter:-word}
#如果parameter变量为空，则word替代变量值，且返回其值
${parameter:=word}
#如果parameter变量为空，word当作stderr输出，否则输出变量值用于设置变量为空导致错误时，返回的错误信息
${parameter:?word}
#如果parameter变量为空，什么都不做，否则word返回
${parameter:+word}
```



# shell脚本开发

## 数值计算

![image-20260622153426716](C:\Users\Admin\AppData\Roaming\Typora\typora-user-images\image-20260622153426716.png)

### 双小括号

![image-20260622153602141](C:\Users\Admin\AppData\Roaming\Typora\typora-user-images\image-20260622153602141.png)

> tips:
>
> []里需要两个空格，=和这些运算符也需要空格，所以，最好经常性的加点空格，预防奇奇怪怪的报错