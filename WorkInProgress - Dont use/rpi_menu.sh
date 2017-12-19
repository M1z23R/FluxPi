#!/bin/bash
clear
readonly CRed="\e[0;31m"
readonly CGrn="\e[0;32m"
readonly CYel="\e[0;33m"
readonly CBlu="\e[0;34m"
readonly CPrp="\e[0;35m"
readonly CCyn="\e[0;36m"
readonly CGry="\e[0;37m"
readonly CWht="\e[0;37m"
readonly CClr="\e[0m"
currentmenu=1;


while [ "$currentmenu" != "0" ];
do

case $currentmenu in
	1)
	clear
	echo -e "${CWht}F$CClr${CRed}lux$CClr${CWht}P$CClr${CRed}i$CClr"
	printf '\n'
	echo -e 'What would you like to do first ?'
	printf '\n'
	echo -e "${CRed}[$CClr${CWht}1$CClr${CRed}]$CClr ${CWht}Start the Captive Portal on$CClr ${CRed}Pi$CClr"
	echo -e "${CRed}[$CClr${CWht}2$CClr${CRed}]$CClr ${CWht}Capture Handshake on$CClr ${CRed}Pi$CClr"
	echo -e "${CRed}[$CClr${CWht}3$CClr${CRed}]$CClr ${CWht}Run dependency installer on$CClr ${CRed}Pi$CClr"
	echo -e "${CRed}[$CClr${CWht}4$CClr${CRed}]$CClr ${CWht}Create re4son-kernel installer on$CClr ${CRed}Pi$CClr"
	echo -e "${CRed}[$CClr${CWht}5$CClr${CRed}]$CClr ${CWht}Read the README file$CClr"
	printf '\n'
	echo -e "${CRed}[$CClr${CWht}0$CClr${CRed}]$CClr ${CRed}Exit$CClr"
	read -e -n 1 currentmenu
	printf "\n"
	;;
	2)
	clear
	echo -e "Starting Captive Portal Attack"
	currentmenu=2
	;;
	3)
	clear
	echo "Capturing Handshake"
	currentmenu=3
	;;
	4) 
	clear
	echo "Installing dependencies"
	currentmenu=4
	;;
	5)
	clear
	echo "Installing re4son-kernel"
	currentmenu=5
	;;
	6)
	clear
	echo "README"
	currentmenu=6
	;;
	0)
	currentmenu=0
	;;
esac

	FILE=1
	while [ "$currentmenu" == "2" ];
	do
	clear
	
	if [ -f "./dump-01.cap" ]; then
	echo -e "Continue"
	read new
	elif [ "$FILE" == "0" ]; then
	currentmenu=1
	break
	
	elif [ -f $FILE ]; then
	echo -e "Continue"
	read new
	else
	echo -e "${CRed}E$CClr""nter path of .cap file with ${CRed}valid$CClr handshake:"
	printf "\nPath to file: "
	read FILE
	
	fi
	
	done
	
	
	while [ "$currentmenu" == "3" ];
	do
	
	read -e -n 1 opt
	case $opt in
		0)
		currentmenu=1
		;;
		1)
		echo -e "some settings"
		;;
	esac
	done
	
done
printf "Exited"
