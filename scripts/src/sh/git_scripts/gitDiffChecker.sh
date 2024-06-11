#!/bin/bash

# git diff --name-only release/RC-123.5  main | egrep '1|2|3' -o | sort -u

APP_PART_NAME=('src-services-1' 'src-services-2' 'src-services-3'
                'src-services-4' 'src-services-5')


read -p "Enter RC/HF Branch: " RC_BRANCH
read -p "Enter MAIN/MASTER Branch: " MAIN_BRANCH

IFS="|"
DIFFERENCE=$(git diff --name-only $RC_BRANCH $MAIN_BRANCH | egrep -w "${APP_PART_NAME[*]}" -o |  sort -u)

echo -e "===DIFFERENCE==="
echo -e " "
echo  "${DIFFERENCE[*]}"

