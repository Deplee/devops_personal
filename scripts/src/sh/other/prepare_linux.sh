#!/bin/bash

# example: sudo bash prepare_linux.sh user

HOMEDIR="/home/$1"
LOGFILE="/tmp/prepare_linux.log"


get-date(){
    date +%Y-%d-%m_%H:%M:%S.00 | tr -s "_" " " | tr -s "/" "-"
}

write-log(){
    echo "[$(get-date)]: $@" | tee -a ${LOGFILE} > /dev/null 2>&1
}


write-log "Installing packages"

sudo apt install -y openssh-server curl wget

write-log "Installing k8s tools"

curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" &&
    chmod +x kubectl &&
    mkdir -p ${HOMEDIR}/.local/bin &&
    mv ./kubectl ${HOMEDIR}/.local/bin/kubectl &&
    echo "deb [trusted=yes] http://ftp.de.debian.org/debian buster main" >>  /etc/apt/sources.list &&
    sudo apt update &&
    sudo apt install kubectx &&
    sudo chown -R $1:$1 ${LOGFILE}
