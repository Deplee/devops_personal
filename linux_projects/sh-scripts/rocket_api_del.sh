#!/bin/bash

#set -x

# date diffirence
#let DIFF=($(date +%s)-`date +%s -d 20230405`)/86400

usage(){
	cat << EOF

	Usage: "${BASH_SOURCE[0]}"

	-h | --help	Print help
	-c | --channel	channel name
	-d | --days	days count for cleanup chat data

	Examples:

	Help: "${BASH_SOURCE[0]}" -h || "${BASH_SOURCE[0]}" --help

	Clean chat data: "${BASH_SOURCE[0]}" -c dev-tst -d 30 || "${BASH_SOURCE[0]}" --channel dev-tst --days 30

EOF
}

# parse input parameters

parse_params(){
	while [ -n "${1-}" ]
	#while :
	do
		case "${1-}" in
		-c | --channel)
			channelName=$(echo $2)
			#echo "$channelName"
			shift ;;
		-d | --days)
			daysCount=$(echo $2)
			#echo "$daysCount" #;;
			shift ;;
		-h | --help)
			usage
			exit 0 ;;
		*)
			echo "Unknown option: $1"
			break ;;
		esac
			shift
	done
main
#return 0
}

# main func

main(){

	if [[ $daysCount -lt 30 ]]; then
		echo "Days can't be less than 30!"
		exit 1;
	fi

	#latestDate=$(date +"%Y-
	latestDate=$(date +"%Y-%m-%d" -d "-$daysCount days")
	#latestDate=2023-04-07
	#oldestDate=$(date +"%Y-%m-%d" -d "-$daysCount days")
	oldestDate=$(date +"%Y-%m-%d" -d "$latestDate -720 days")
	#echo $((($(date -d "$curDate" +%s) - $(date -d 2023-04-03 +%s)) / 86400))
	#echo "curdate: $latestDate"
	#echo "oldestDate: $oldestDate"

	# post request to delete msgs in channel/room

	curl -H "X-Auth-Token: *" \
	-H "X-User-Id: *" \
	-H "Content-type: application/json" \
	https://ip:portapi/v1/rooms.cleanHistory \
	-d '{ "roomName": "'"$channelName"'","latest": "'"$latestDate"'", "oldest": "'"$oldestDate"'"}'
	#-d '{ "roomName": "'"$channelName"'","latest": "'"$latestDate"'", "oldest": "2023-01-01"}'

	#-d '{ "roomName": "dev-tst","latest": "'"$curDate"'", "oldest": "'"$budDate"'"}'
}


parse_params "$@"
