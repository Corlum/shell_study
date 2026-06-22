#!/bin/bash
#批量修改文件名

for filename in `ls *ture*`
do 
	mv $filename `echo ${filename//picture_/pic_}`
done
