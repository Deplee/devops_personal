#!/bin/bash

#set -x

usage(){
        cat << EOF

        Usage: "${BASH_SOURCE[0]}"

        -h | --help     Print help
        -c | --channel  channel name
        -d | --days     days count for cleanup chat data

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
                        shift ;;
                -d | --days)
                        daysCount=$(echo $2)
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

        testDate=$(date +"%Y-%m-%d")
		latestDate=$(date +"%Y-%m-%d" -d  "- $daysCount days") # The end of time range of messages
        oldestDate=$(date +"%Y-%m-%d" -d "$latestDate -365 days") # The start of the time range of messages
        


        echo "CD (Current Date) : $(date +"%Y-%m-%d")"

        echo "OD (Start of Timerange) : $oldestDate"
        echo "LD (End of Timerange) : $latestDate"

        #echo "TD: $testDate"
        # post request to delete msgs in channel/room

        curl -H "X-Auth-Token: *" \
        -H "X-User-Id: *" \
        -H "Content-type: application/json" \
        https://url:port/api/v1/rooms.cleanHistory \
        -d '{ "roomName": "'"$channelName"'","latest": "'"$latestDate"'", "oldest": "'"$oldestDate"'"}'
}

parse_params "$@"


