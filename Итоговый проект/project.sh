#!/bin/bash

ROOTUSER="root"
LOG_FILE_DIR="/etc/monitor/logs"
LOG_FILE="$LOG_FILE_DIR/$(date +"%Y-%m-%d_%H-%M-%S").log"
KNOWN_PIDS_FILE="/etc/monitor/pids"

# Проверка наличия рут-привелегий
username=$(id -nu)
[[ "$username" == "$ROOTUSER" ]] || { echo "Must be root to run $(basename $0)."; exit 1; }

# Фукнция для вывода usage-текста
function printUsage(){
	echo "$(basename $0) args: [cmdline environ limits mounts status cwd fd fdinfo root]. Select at least 4 without repetitions."
}


#Валидация аргументов
mapfile -t args < <(printf '%s\n' "$@" | sort -u)
[[ ${#args[@]} -lt 4 ]] && { printUsage; exit 1; }
for arg in "${args[@]}"
do
	[[ "$arg" =~ ^(cmdline|environ|limits|mounts|status|cwd|fd|fdinfo|root)$ ]] || { printUsage; exit 1; }
done

mkdir -p "$LOG_FILE_DIR"
touch "$LOG_FILE"
touch "$KNOWN_PIDS_FILE"

# Делаю заголовок таблицы
table_header=("PID" "Process name" "${args[@]}")
table_format="%-10s %-30s "
for arg in ${args[@]}; do
	table_format+="%-30s "
done
table_format+="\n"

printf "$table_format" "${table_header[@]}"
printf "\n"

# Прохожу по всем папкам /proc/N
mapfile -t PIDS < <(ls /proc | grep -E "^[[:digit:]]*$")
for PID in "${PIDS[@]}"; do
	result=()

	# Поиск PID в файле с уже известными PID'ами
	# grep -q - поиск в тихом режиме, не выводит на экран найденную строку
	grep -q "$PID" "$KNOWN_PIDS_FILE" || {
		echo "$PID" >> "$LOG_FILE"
		echo "$PID" >> "$KNOWN_PIDS_FILE"
	}

	# Вложенный цикл для сбора данных
	for arg_index in "${!args[@]}"; do
		_temp=
		case "${args[$arg_index]}" in
			cmdline)
				{ _temp=$(basename "$(cat "/proc/$PID/cmdline")"); } 2> /dev/null
				;;
			environ)
				_temp=$(cat "/proc/$PID/environe" 2> /dev/null)
				;;
			limits)
				_temp=$(cat "/proc/$PID/limits" 2> /dev/null | awk '/Max stack size/ {print $4 " " $6}')
				;;
			mounts)
				_temp=$(cat "/proc/$PID/mounts" 2> /dev/null | head -n 1)
				;;
			status)
				_temp=$(cat "/proc/$PID/status" 2> /dev/null | awk '/State/ {print $2 " " $3}')
				;;
			cwd)
				_temp=$(basename "$(readlink "/proc/$PID/cwd" 2> /dev/null)" 2> /dev/null)
				;;
			fd)
				[[ -d "/proc/$PID/fd" ]] && { _temp=$(ls -l "/proc/$PID/fd" | head -n -1); } 
				;;
			fdinfo)
				[[ -d "/proc/$PID/fdinfo" ]] && { _temp=$(ls -l "/proc/$PID/fdinfo" | head -n -1); } 
				;;
			root)
				_temp=$(basename "$(readlink "/proc/$PID/root")" 2> /dev/null)
				;;
			*)
				printUsage; exit 1
				;;
		esac
	
		_temp=${_temp:--}
		result[$arg_index]="$_temp"

	done
	_name="$(basename "$(readlink -f /proc/$PID/exe)")"
	_name="${_name:--}"

	printf "$table_format" "$PID " "$_name" "${result[@]}"

done
