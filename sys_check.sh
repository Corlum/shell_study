#!/bin/bash
host_name=$(uname -n)
echo "主机名：$host_name"

core_ver=$(uname -r)
echo "内核版本：$core_ver"

Date=$(date +"%F")
echo "日期：$Date"

disk_usage=$(df -h | grep sda2 | awk '{print $5}')
echo "磁盘使用率：$disk_usage"

mem_total=$(free -m | awk '/Mem/{print $2}')
echo "总内存：$mem_total"

mem_used=$(free -m | awk '/Mem/{print $3}')
echo "已用内存：$mem_used"

