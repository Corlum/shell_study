#!/bin/bash

MYSQL_BACKAGE_NAME=mysql-5.7.44-linux-glibc2.12-x86_64.tar.gz
MYSQL_BACKAGE_URL=https://downloads.mysql.com/archives/get/p/23/file/mysql-5.7.44-linux-glibc2.12-x86_64.tar.gz
MYSQL_BACKAGE_MD5=d7c8436bbf456e9a4398011a0c52bc40
MYSQL_ROOT_PWD=Root@123456

WAIT_TIME=0
MAX_WAIT=20

sudo apt update

#检查libaio1t64包是否安装
if dpkg -l | grep -qw libaio1t64
then
	echo "Installed package libaio1t64"
else
	echo "Installing package libaio1t64..."
	sudo apt install libaio1t64 -y
fi

#检查libnuma-dev包是否安装
if dpkg -l | grep -qw libnuma-dev
then
	echo "Installed package libnuma-dev"
else
	echo "Installing package libnuma-dev..."
	sudo apt install libnuma-dev -y
fi

#检查组/用户是否存在，不存在则创建
if getent group mysql > /dev/null
then
	echo "Group 'mysql' exists"
	if getent passwd mysql 
	then
		echo "User 'mysql' exists"
	else
		echo "User 'mysql' not exists"
		echo "Adding user 'mysql'"
		sudo useradd -r -g mysql -s /bin/false mysql

		if getent passwd mysql > /dev/null
		then
			echo "User 'mysql' add success"
			
		else
			echo "User add error"
			exit 1
		fi			

	fi
else
	echo "Group 'mysql' not exists"
	echo "Adding group 'mysql'"
	sudo groupadd mysql

	if getent group mysql > /dev/null
	then
		echo "Group 'mysql' add success"
		echo "Adding user 'mysql'"
		sudo useradd -r -g mysql -s /bin/false mysql
		
		if getent passwd mysql > /dev/null
		then
			echo "User 'mysql' add success"
			
		else
			echo "User add error"
			exit 1
		fi	
	else
		echo "Group add error"
		exit 1
	fi
fi 

#下载mysql的二进制文件并验证md5值
if [ ! -f "$MYSQL_BACKAGE_NAME" ]
then
	wget "$MYSQL_BACKAGE_URL"
	if [ $? -eq 0 ]
	then
		echo "download success"
		if [ "$(md5sum "$MYSQL_BACKAGE_NAME" | awk '{print $1}')" = "$MYSQL_BACKAGE_MD5" ]
		then 
			echo "MD5 verification passed"
		else
			echo "MD5 verification failed"
			rm "$MYSQL_BACKAGE_NAME"
			exit 2
		fi
	else
		echo "download failed"
		exit 1
	fi
else
	if [ "$(md5sum "$MYSQL_BACKAGE_NAME" | awk '{print $1}')" = "$MYSQL_BACKAGE_MD5" ]
	then 
		echo "MD5 verification passed"
	else
		echo "MD5 verification failed"
		rm "$MYSQL_BACKAGE_NAME"
		exit 2
	fi
fi

#验证mysql的文件路径是否存在，不存在则创建，存在则将mysql压缩包解压到其中
if [ -d "/usr/local/mysql" ] 
then
	echo "'mysql' directory exists"
	sudo tar -xvf ./"$MYSQL_BACKAGE_NAME" -C /usr/local/mysql/ --strip-components=1
else
	echo "'mysql' directory not exists"
	echo "Creating 'mysql' directory..."
	sudo mkdir -p /usr/local/mysql/
	if [ -d "/usr/local/mysql" ] 
	then
		echo "'mysql' directory created"
		sudo tar -xvf ./"$MYSQL_BACKAGE_NAME" -C /usr/local/mysql/ --strip-components=1
	else
		echo "'mysql' directory create failed"
		exit 3
	fi
fi

if ! grep 'export PATH=/usr/local/mysql/bin:$PATH' /etc/profile >/dev/null
then
	echo 'export PATH=/usr/local/mysql/bin:$PATH' | sudo tee -a /etc/profile
fi

source /etc/profile

sudo mkdir -p /data/mysql
sudo chown -R mysql:mysql /data/mysql
sudo chmod 750 /data/mysql

#创建my.cnf文件
sudo tee /etc/my.cnf >/dev/null <<EOF
[mysqld]
basedir = /usr/local/mysql
datadir = /data/mysql
socket = /tmp/mysql.sock
port = 3306
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci
max_connections = 1000
innodb_buffer_pool_size = 512M
log_error = /data/mysql/mysql-error.log
pid-file = /data/mysql/mysql.pid
slow_query_log = 1
slow_query_log_file = /data/mysql/slow.log
long_query_time = 2

skip-name-resolve = 1
symbolic-links = 0
explicit_defaults_for_timestamp = 1

key_buffer_size = 256M
max_allowed_packet = 64M

EOF
echo "The configuration file /etc/my.cnf has been generated"

#创建Systemd服务文件
sudo tee /etc/systemd/system/mysql.service <<EOF
[Unit]
Description = MySQL Server
After = network.target
[Service]
User = mysql
Group = mysql
ExecStart=/usr/local/mysql/bin/mysqld --defaults-file = /etc/my.cnf
Restart = on-failure
[Install]
WantedBy = multi-user.target
EOF

# 无密码初始化
if sudo "/usr/local/mysql/bin/mysqld" --initialize-insecure --user=mysql --basedir=/usr/local/mysql --datadir=/data/mysql
then
    echo "mysql init success"

# 后台启动mysql
	sudo /usr/local/mysql/bin/mysqld_safe --user=mysql >/dev/null 2>&1 & 
	sleep 3 # 等待服务启动
	while ! sudo ss -ltnp | grep :3306 >/dev/null 2>&1
	do
    sleep 1
    WAIT_TIME=$((WAIT_TIME + 1))
    if [ $WAIT_TIME -ge $MAX_WAIT ]
	then
        echo "MySQL startup timed out, didn't listen on port 3306 within $MAX_WAIT seconds"
        exit 1
    fi
	done

# 免密登录，直接设置root密码
	if sudo /usr/local/mysql/bin/mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '$MYSQL_ROOT_PWD';FLUSH PRIVILEGES;"
	then
		echo "The temporary password has been set, you can find it in file 'MySQL_temporary_passwd.txt'"
		echo "$MYSQL_ROOT_PWD" > MySQL_temporary_passwd.txt
	else
		echo "Failed to set temporary password"
		exit 1
	fi
else
    echo "MySQL init failed"
    exit 1
fi

sudo systemctl daemon-reload
sudo systemctl start mysql
sudo systemctl enable mysql

echo "MySQL is up and set to start on boot "