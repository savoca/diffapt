#!/bin/bash
## Alex Deddo <alex.deddo@daqri.com>
[[ -z $1 ]] && echo "Usage: $0 <apt-list>" && exit 1

RED=`tput setaf 1`
GRN=`tput setaf 2`
RST=`tput sgr0`

tput sgr0

F_CREATE=0
[[ "$1" == "--create" ]] && F_CREATE=1

function create_new_list() {
	dpkg --list | tail -n+6 | while read i; do
		PKG_STR=`echo $i | cut -f 2 -d ' '`
		PKG_VER=`echo $i | cut -f 3 -d ' '`
		echo $PKG_STR $PKG_VER >> $1
	done
}

## Establish as empty tempfile
PKG_TMP=/tmp/.diffapt_tmp
>$PKG_TMP

function compare_apt_list() {
	cat $1 | while read i; do
		PKG_STR=`echo $i | cut -f 1 -d ' '`
		PKG_VER=`echo $i | cut -f 2 -d ' '`
		if [[ -n `dpkg --list $PKG_STR 2>/dev/null` ]]; then
			## Create the installed list beforehand, like --create it,
			## if any occurances of pkg_str are found, remove it
			## from the list, at the end, this becomes the list of
			## extra packages!!! :D
			sed -i '/'$PKG_STR'\ /d' $PKG_TMP
			USR_VER=`dpkg --list $PKG_STR | tail -n+6 | awk '{print $3}'`
			if [[ "$PKG_VER" == "$USR_VER" ]]; then
				## TODO: Use or remove this!
				PKG_CNT=`expr $PKG_CNT + 1`
			else
				echo "Bad version: $PKG_STR ${RED}$USR_VER${RST} -> ${GRN}$PKG_VER${RST}"
			fi
		else
			echo "Missing package: ${RED}$PKG_STR $PKG_VER${RST}"
		fi
	done
	cat $PKG_TMP > final.txt
	rm $PKG_TMP
	EXTRA=`cat final.txt | wc -l`
	if [[ $EXTRA -gt 0 ]]; then
		echo "${RED}$EXTRA extra packages installed${RST}"
		cat final.txt
		rm final.txt
	else
		echo "No extra packages found"
	fi
}

echo start
if [[ $F_CREATE -eq 1 ]]; then
	printf "creating new apt list... "
	create_new_list new_apt_list.txt
	printf "done\n"
else
	printf "creating new apt list..."
	create_new_list $PKG_TMP
	printf "done\n"
	compare_apt_list $1 $2
fi

exit
