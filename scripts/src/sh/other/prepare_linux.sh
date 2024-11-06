#!/bin/bash

LOGFILE="/tmp/prepare_linux.log"

get-date(){
    date +%Y-%d-%m_%H:%M:%S.00 | tr -s "_" " " | tr -s "/" "-"
}

write-log(){
    echo "[$(get-date)]: $@" | tee -a ${LOGFILE} > /dev/null 2>&1
}

usage(){
        cat << EOF
        Usage: "${BASH_SOURCE[0]}"

        -p | --packages       Install packages only
        -k | --k8s            Install k8s tools
        -a | --all            Install packages & k8s tools
        -h | --help           Print help

        Examples:

        Help: ${BASH_SOURCE[0]} -h || ${BASH_SOURCE[0]} --help

        Run script: ${BASH_SOURCE[0]} -a || ${BASH_SOURCE[0]} --all

EOF
}


__install_packages(){

write-log "Installing packages"
sudo apt install -y openssh-server \
                    ufw \
                    vim \
                    curl \
                    wget \
                    htop \
                    git \
                    docker.io \
                    build-essential
write-log "Installing packages"
}

__install_k8s_tools(){

write-log "Installing k8s tools"

curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" &&
    chmod +x kubectl &&
    mkdir -p ${HOME}/.local/bin &&
    mv ./kubectl ${HOME}/.local/bin/kubectl &&
    echo "deb [trusted=yes] http://ftp.de.debian.org/debian buster main" >>  /etc/apt/sources.list &&
    sudo apt update &&
    sudo apt install kubectx &&
    sudo chown $USER:$USER ${LOGFILE}
}

parse_params(){
        while [ -n "${1-}" ]
        #while :
        do
                case "${1-}" in
                -p | --packages)
                        __install_packages
                        shift ;;
                -k | --k8s)
                        __install_k8s_tools
                        shift ;;
                -a | --all)
                        __install_packages
                        __install_k8s_tools
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
#return 0
}

parse_params "$@"
