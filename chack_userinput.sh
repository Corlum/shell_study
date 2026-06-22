#!/bin/bash

print_usage(){
	printf "请输入数字！\n"
	exit 1
}



read -p "请输入数字:"  firstnum

if [ -n "`echo $firstnum|sed 's/[0-9]//g'`" ]
then
	print_usage
fi

read -p "请输入运算符:" operator

if [ "${operator}" != "+" ] && [ "${operator}" != "-" ] && [ "${operator}" != "*" ] && [ "${operator}" != "/" ]
then
	print '只能输入 + - * /'
	exit 2
fi

read -p "请输入第二个数字:" secondnum

if [ -n "`echo $secondnum|sed 's/[0-9]//g'`" ]
then
	print_usage
fi

echo "结果是:$((${firstnum}${operator}${secondnum}))"

