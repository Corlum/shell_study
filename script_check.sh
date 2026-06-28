#!/bin/bash

path=/home/cofcat/script/

[ ! -d "$path" ] && mkdir $path -p


cat <<END
	1.[install nmap]
	2.[install wireshark]
	3.[exit]
	please input num:
END

read num

[[ ! "$num" =~ [1-3] ]] &&{
	echo "the num you input must in (1,2,3)"
	exit 4
}

[ "$num" -eq "1" ] && {
	echo "installing nmap...."
	sleep 2;
	
	[ -x "$path/nmap.sh" ] || {
		echo "script not exist or can't exec."
		exit 1
	}
	$path/nmap.sh
	exit $?

}

[ "$num" -eq "2" ] && {
	echo "installing wireshark...."
	sleep 2;

	[ -x "$path/wireshark.sh" ] || {
		echo "script not exist or can't exec."
		exit 1
	}
	$path/wireshark.sh
	exit $?

}

[ "$num" -eq "3" ] && {
	echo "install script exited"
	exit 3

}




