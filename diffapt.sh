#!/bin/bash
## Alex Deddo <alex.deddo@daqri.com>
[[ -z $1 ]] && echo "Usage: $0 <apt-list>" && exit 1

RED=`tput setaf 1`
GRN=`tput setaf 2`
YLW=`tput setaf 3`
RST=`tput sgr0`

tput sgr0

F_CREATE=0
[[ "$1" == "--create" ]] && F_CREATE=1

PKG_LOG=/tmp/.diffapt_log
PKG_TMP=/tmp/.diffapt_tmp
>$PKG_LOG
>$PKG_TMP

function cancel() {
	printf "\r"
	cat $PKG_LOG
	[[ -f $PKG_LOG ]] && rm $PKG_LOG
	[[ -f $PKG_TMP ]] && rm $PKG_TMP
	exit
}
trap cancel INT

function show_progress() {
	[[ -z $1 || -z $2 || -z $3 ]] && return
	PROG=`echo $2 $3 | awk '{print $1 / $2 * 100}' | cut -f 1 -d '.'`
	[[ -n $4 && $4 -ne 0 ]] && printf "\033[1A\033[K"
	printf "$1$PROG%%\n\r"
}

function create_new_list() {
	PKG_CNT=0
	PKG_MAX=`dpkg --list | tail -n+6 | wc -l`
	dpkg --list | tail -n+6 | while read i; do
		PKG_STR=`echo $i | cut -f 2 -d ' '`
		PKG_VER=`echo $i | cut -f 3 -d ' '`
		echo $PKG_STR $PKG_VER >> $1
		[[ $PKG_CNT -eq 0 ]] && PKG_RST=0
		PKG_CNT=`expr $PKG_CNT + 1`
		show_progress "Creating debian list... " $PKG_CNT $PKG_MAX $PKG_RST
		PKG_RST=1
	done
}

function compare_apt_list() {
	PKG_CNT=0
	PKG_MAX=`cat $1 | wc -l`
	cat $1 | while read i; do
		PKG_STR=`echo $i | cut -f 1 -d ' '`
		PKG_VER=`echo $i | cut -f 2 -d ' '`
		if [[ -n `dpkg --list $PKG_STR 2>/dev/null` ]]; then
			## Update list of 'extra' packages
			sed -i '/'$PKG_STR'\ /d' $PKG_TMP
			USR_VER=`dpkg --list $PKG_STR | tail -n+6 | awk '{print $3}'`
			if [[ "$PKG_VER" != "$USR_VER" ]]; then
				echo "Bad version: $PKG_STR ${RED}$USR_VER${RST} -> ${GRN}$PKG_VER${RST}" >> $PKG_LOG
			fi
		else
			echo "Missing package: ${RED}$PKG_STR $PKG_VER${RST}" >> $PKG_LOG
		fi
		[[ $PKG_CNT -eq 0 ]] && PKG_RST=0
		PKG_CNT=`expr $PKG_CNT + 1`
		show_progress "Comparing debian packages... " $PKG_CNT $PKG_MAX $PKG_RST
		PKG_RST=1
	done

	## Show extra packages
	PKG_EXT=`cat $PKG_TMP | wc -l`
	if [[ $PKG_EXT -gt 0 ]]; then
		echo "$PKG_EXT ${YLW}extra packages${RST} installed:" >> $PKG_LOG
		cat $PKG_TMP >> $PKG_LOG
	fi
	cat $PKG_LOG
	rm $PKG_LOG
	rm $PKG_TMP
}

if [[ $F_CREATE -eq 1 ]]; then
	create_new_list new_apt_list.txt
else
	create_new_list $PKG_TMP
	compare_apt_list $1
fi

exit
