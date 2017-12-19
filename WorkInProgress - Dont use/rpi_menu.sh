#!/bin/bash
clear
COLUMNS=$(tput cols) 
readonly CRed="\e[0;31m"
readonly CGrn="\e[0;32m"
readonly CYel="\e[0;33m"
readonly CBlu="\e[0;34m"
readonly CPrp="\e[0;35m"
readonly CCyn="\e[0;36m"
readonly CGry="\e[0;37m"
readonly CWht="\e[0;37m"
readonly CClr="\e[0m"
echo -e "${CWht}F$CClr${CRed}lux$CClr${CWht}P$CClr${CRed}i$CClr"
printf '\n'



while [ "$opt" != "1" ] && [ "$opt" != "2" ] && [ "$opt" != "3" ] && [ "$opt" != "4" ] && [ "$opt" != "5" ] && [ "$opt" != "0" ];
do
echo -e 'What would you like to do first ?'
printf '\n'
echo -e "${CRed}[$CClr${CWht}1$CClr${CRed}]$CClr ${CWht}Start the Captive Portal on$CClr ${CRed}Pi$CClr"
echo -e "${CRed}[$CClr${CWht}2$CClr${CRed}]$CClr ${CWht}Capture Handshake on$CClr ${CRed}Pi$CClr"
echo -e "${CRed}[$CClr${CWht}3$CClr${CRed}]$CClr ${CWht}Run dependency installer on$CClr ${CRed}Pi$CClr"
echo -e "${CRed}[$CClr${CWht}4$CClr${CRed}]$CClr ${CWht}Create re4son-kernel installer on$CClr ${CRed}Pi$CClr"
echo -e "${CRed}[$CClr${CWht}5$CClr${CRed}]$CClr ${CWht}Read the README file$CClr"
printf '\n'
echo -e "${CRed}[$CClr${CWht}0$CClr${CRed}]$CClr ${CRed}Exit$CClr"
read -e -n 1 opt
printf "\n"
clear
case $opt in
	1) echo "Starting Captive Portal Attack"
	;;
	2) echo "Capturing Handshake"
	;;
	3) echo "Installing dependencies"
	;;
	4) echo "Installing re4son-kernel"
	echo "\
	sudo bash
	mount /dev/mmcblk0p1 /boot
	cd /usr/local/src
	## For current stable
	wget  -O re4son-kernel_current.tar.xz https://whitedome.com.au/re4son/downloads/11299/
	tar -xJf re4son-kernel_current.tar.xz
	cd re4son-kernel_4*
	./install.sh" >> install-re4son.sh
	chmod +x install-re4son.sh
	;;
	5) "README"
	clear
	cat ./README
	;;
esac
done
printf "Exited"
