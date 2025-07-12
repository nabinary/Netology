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

# Фукнция валидации аргумента на основе переданного
# Принимает 3 аргумента: проверяемый параметр, регулярка, сообщение об ошибке
function validateByRegexp() {

     	[[ $# -ne 3 ]] && { echo "Error in 'validateByRegext' func. Must be 3 args."; exit 1;  }

	local value="$1"	
	local pattern="$2"
	local errorMsg="$3"

	[[ "$value" =~ $pattern ]] || { echo $errorMsg; exit 1;  }

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
validateByRegexp "$PREFIX" '^(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])$' "PREFIX arg must be IPv4 type"
[[ "$SUBNET_ARG" != "NOT_SET" ]] && { validateByRegexp "$SUBNET_ARG" '^(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])$' "SUBNET arg must be in 0..255"; }
[[ "$HOST_ARG" != "NOT_SET" ]] && { validateByRegexp "$HOST_ARG" '^(25[0-4]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])$' "HOST arg must be in 1..254"; }

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
