#!/bin/bash

ROOTUSER="root"
LOG_FILE_DIR="/etc/busreader/logs"
LOG_FILE="$LOG_FILE_DIR/$(date +"%Y-%m-%d_%H-%M-%S").log"
KNOWN_DEVICES_FILE="/etc/busreader/devices"

username=$(id -nu)
[[ "$username" == "$ROOTUSER" ]] || { echo "You must be root to start $(basename $0)."; exit 1; }

devices=$(cat "/proc/bus/input/devices")
handlers=$(cat "/proc/bus/input/handlers")

mkdir -p "$LOG_FILE_DIR"
touch "$LOG_FILE"
touch "$KNOWN_DEVICES_FILE"

header=("Identifier" "Name" "Phys" "Uniq")
table_format="%-40s %-40s %-40s %-40s\n"
printf "$table_format" "${header[@]}"

data=()
while IFS= read -r line; do

	[[ -n "$line" ]] || {
		raw="$data[*]"
		grep -qxF "$raw" "$KNOWN_DEVICES_FILE" || {
			echo "$raw" >> "$KNOWN_DEVICES_FILE"
			echo "$raw" >> "$LOG_FILE"
		}
		printf "$table_format" "${data[@]}"
		data=()
		continue
	}
	case "$(echo "$line" | cut -c1)" in
		I)
			data[0]="|$(echo "$line" | sed 's/I: //') ||"
			;;
		N)
			data[1]="$(echo "$line" | sed -E 's/N: [Nn]ame=//') ||"
			;;
		P)
			data[2]="$(echo "$line" | sed -E 's/P: [Pp]hys=//') ||"
			;;
		U)
			value="$(echo "$line" | sed -E 's/U: [Uu]niq=//') |"
			data[3]=${value:--}
			;;
	esac

done <<< $devices
