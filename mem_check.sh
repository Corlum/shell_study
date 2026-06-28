#!/bin/bash

mem_avaliable=`free -m | awk '/Mem/{print $7}'`

if [ "$mem_avaliable" -lt "6000" ]
then
	echo "内存不足"
fi

