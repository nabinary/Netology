#!/bin/bash
ROOTUSER=root
PREFIX="${1:-NOT_SET}"
INTERFACE="${2:-NOT_SET}"
SUBNET_ARG="${3:-NOT_SET}"
HOST_ARG="${4:-NOT_SET}"

trap 'echo "arping exit (Ctrl-C)"; exit 1' 2

# Функция выводящая usage скрипта
function printUsage() {
	echo "usage: `basename $0` PREFIX INTERFACE SUBNET* HOST*."
	echo "* - means OPTIONAL arg."
}


# Проверка, что скрипт запущен от рута
username=`id -nu`
if [ "$username" != "$ROOTUSER" ] ; then
	echo "Must be root to run \"`basename $0`\"."
	exit 1
fi

# Валидация аргументов
[[ "$PREFIX" = "NOT_SET" ]] && { printUsage; exit 1; }
[[ ! -e /sys/class/net/$INTERFACE ]] && { echo "Interface $INTERFACE is not exists."; printUsage; exit 1; }
[[ "$SUBNET_ARG" != "NOT_SET" ]] && [[ ! "$SUBNET_ARG" =~ ^(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])$ ]] && { echo "SUBNET arg must be in 0..255"; printUsage; exit 1; }
[[ "$HOST_ARG" != "NOT_SET" ]] && [[ ! "$HOST_ARG" =~ ^(25[0-4]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[1-9])$ ]] && { echo "HOST arg must be in 1..254"; printUsage; exit 1; }

# Выставление значений по умолчанию для SUBNET в случае, если аргумент не задан явно
SUBNET_START=$SUBNET_ARG
SUBNET_END=$SUBNET_ARG
[[ "$SUBNET_ARG" = "NOT_SET" ]] && { SUBNET_START=0; SUBNET_END=255; }

# Выставление значений по умолчанию для HOST в случае, если аргумент не задан явно
HOST_START=$HOST_ARG
HOST_END=$HOST_ARG
[[ "$HOST_ARG" = "NOT_SET" ]] && { HOST_START=1; HOST_END=254; }


for ((SUBNET=$SUBNET_START; SUBNET<=SUBNET_END; SUBNET++))
do
	for ((HOST=$HOST_START; HOST<=HOST_END; HOST++))
	do
		echo "[*] IP : ${PREFIX}.${SUBNET}.${HOST}"
		arping -c 3 -i "$INTERFACE" "${PREFIX}.${SUBNET}.${HOST}" 2> /dev/null
	done
done
