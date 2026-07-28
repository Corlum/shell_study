#!/bin/bash

# ================全局变量=====================
HTTP_PORT=80
HTTPS_PORT=443
MYSQL_PORT=3306
TIME_ZONE=Asia/Shanghai
TIME_TAG=$(date +%Y%m%d_%H%M%S)
BACKUP_ROOT="/data/backup"
BACK_FILE="${BACKUP_ROOT}/sys_config_back_${TIME_TAG}.tar.gz"
UBUNTU_CODENAME=$(lsb_release -c | awk '{print $2}')

# ============================================

if [ $(whoami) != "root" ]
then
    echo "This script must run by root"
    exit 1
fi

#检查特定端口是否被占用
check_port(){
    local port="$1"
    if netstat -ntlp | grep ":${port}" &>/dev/null
    then
        echo "Port ${port} was in used"
        exit 1
    fi
}

check_port $HTTP_PORT
check_port $HTTPS_PORT
check_port $MYSQL_PORT

#查询磁盘空间，可用空间小于10G则提示空间不足并退出
if [ $(df -P --block-size=1G | grep -w "/" | awk '{print $4}') -lt "10" ]
then
    echo "Insufficient disk space"
    exit 1
fi

#全量备份

mkdir -p "${BACKUP_ROOT}"

echo "[INFO] 开始执行系统配置前置备份"
tar -zcf "${BACK_FILE}" \
--exclude=/etc/mtab \
--exclude=/etc/selinux/targeted/cache \
--exclude=/tmp \
--exclude=/proc \
--exclude=/sys \
--exclude=/dev \
--exclude=/run \
--exclude="${BACKUP_ROOT}" \
/etc \
/var/spool/cron \
/root/.ssh \
/etc/systemd/system

# 判断tar是否执行成功
if [ $? -eq 0 ];then
    chmod 600 "${BACK_FILE}"
    echo "[INFO] 备份完成：${BACK_FILE}"
else
    echo "[ERROR] 配置备份失败！"
    exit 1
fi

# 追加源码软件配置
[ -d "/usr/local/nginx/conf" ] && tar -zrf "${BACK_FILE}" /usr/local/nginx/conf
[ -f "/usr/local/mysql/my.cnf" ] && tar -zrf "${BACK_FILE}" /usr/local/mysql/my.cnf

#备份官方源并更换阿里源
sudo cp /etc/apt/sources.list.d/ubuntu.sources /etc/apt/sources.list.d/ubuntu.sources.back

sudo tee /etc/apt/sources.list.d/ubuntu.sources >/dev/null <<EOF
Types: deb
URIs: https://mirrors.aliyun.com/ubuntu
Suites: $UBUNTU_CODENAME $UBUNTU_CODENAME-updates $UBUNTU_CODENAME-backports
Components: main universe restricted multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg

Types: deb
URIs: https://mirrors.aliyun.com/ubuntu
Suites: $UBUNTU_CODENAME-security
Components: main universe restricted multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg

EOF

#安装软件包（mysql和nginx所需的软件包并没有在这里安装，其单独的初始化脚本中会去安装）
sudo apt update
sudo apt install -y wget curl unzip zip lsof net-tools vim tree openssl chrony bzip2 libssl-dev

#设置时区
timedatectl set-timezone $TIME_ZONE

# 备份chrony原有配置
[ ! -f /etc/chrony.conf.bak ] && cp /etc/chrony.conf /etc/chrony.conf.bak

# 清空默认国外pool，写入国内阿里云NTP
sed -i '/^pool/d' /etc/chrony.conf
cat >> /etc/chrony.conf << EOF
server ntp.aliyun.com iburst
server ntp1.aliyun.com iburst
server ntp2.aliyun.com iburst
EOF

# 重启服务并开机自启
systemctl restart chrony
systemctl enable chrony

# 简单校验
if chronyc tracking &>/dev/null; then
    echo "[INFO] Chrony时间同步配置完成"
else
    echo "[ERROR] Chrony时间同步失败"
    exit 1
fi


apt install -y ufw

# 重置原有规则
ufw reset

# 设置默认策略
ufw default deny incoming
ufw default allow outgoing

# 放行必要端口
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
# 内网网段访问MySQL
# ufw allow from 192.168.1.0/24 to any port 3306 proto tcp
# 允许ping
ufw allow proto icmp

# 启用防火墙，自动确认yes
echo "y" | ufw enable
# 开机自启
systemctl enable ufw

echo "[INFO] UFW防火墙配置完成，规则如下："
ufw status

