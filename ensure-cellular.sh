#!/bin/bash

SUDO=$(test ${EUID} -ne 0 && which sudo)
SYSCFG=/etc/systemd
UDEV_RULESD=/etc/udev/rules.d

APN="teal"

opstr+="a:-:";
while getopts "${opstr}" OPTION; do
	case $OPTION in
	-) case ${OPTARG} in
		apn)
		APN="${!OPTIND}";
		OPTIND=$(($OPTIND + 1));
		;;
		esac;;
	esac;
done

if [ ! -z "$APN" ] ; then
	echo "Removing existing network manager profile for Cellular..."
	$SUDO nmcli con delete 'Cellular'
	echo "Adding network manager profile for Cellular..."
	$SUDO nmcli connection add type gsm ifname cdc-wdm0 con-name "Cellular" apn "$APN" connection.autoconnect yes	
	echo "Waiting for conneciton to come up..."
	sleep 5
	$SUDO nmcli con show
else
	echo "APN cannot be blank, doing nothing!"
fi


