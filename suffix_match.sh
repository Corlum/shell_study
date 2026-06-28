#!/bin/bash

if expr "$1" ":" ".*\.jpg" &> /dev/null
then
	echo "这是一个.jpg格式的文件"
else
	echo "这不是一个.jpg格式的文件"
fi
