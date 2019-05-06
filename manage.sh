#!/bin/bash

cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [[ ! -f ./.env ]]
then
    printf "\e[31mPlease create .env file.\e[0m\n"
    exit 1
fi

source ./.env

if [[ -z ${COMPOSE_PROJECT_NAME+x} ]]; then printf "\e[31mThe 'COMPOSE_PROJECT_NAME' variable is not defined.\e[0m\n"; exit 1; fi
if [[ -z ${PORT+x} ]]; then printf "\e[31mThe 'PORT' variable is not defined.\e[0m\n"; exit 1; fi
if [[ -z ${READ_ONLY+x} ]]; then printf "\e[31mThe 'READ_ONLY' variable is not defined.\e[0m\n"; exit 1; fi
if [[ -z ${CHROOT+x} ]]; then printf "\e[31mThe 'CHROOT' variable is not defined.\e[0m\n"; exit 1; fi
if [[ -z ${VOLUME_NAME+x} ]]; then printf "\e[31mThe 'VOLUME_NAME' variable is not defined.\e[0m\n"; exit 1; fi
if [[ -z ${HOSTS_ALLOW+x} ]]; then printf "\e[31mThe 'HOSTS_ALLOW' variable is not defined.\e[0m\n"; exit 1; fi
if [[ -z ${USER+x} ]]; then printf "\e[31mThe 'USER' variable is not defined.\e[0m\n"; exit 1; fi
if [[ -z ${USER_ID+x} ]]; then printf "\e[31mThe 'USER_ID' variable is not defined.\e[0m\n"; exit 1; fi
if [[ -z ${GROUP+x} ]]; then printf "\e[31mThe 'GROUP' variable is not defined.\e[0m\n"; exit 1; fi
if [[ -z ${GROUP_ID+x} ]]; then printf "\e[31mThe 'GROUP_ID' variable is not defined.\e[0m\n"; exit 1; fi

LOG_PATH=log.txt

# Clear logs
echo "" > ${LOG_PATH}

# ----------------------------- HEADER -----------------------------

Title() {
    printf "\n\e[1;46m --------- $1 --------- \e[0m\n\n"
}

Warning() {
    printf "\e[31;43m$1\e[0m\n"
}

Help() {
    printf "\e[2m$1\e[0m\n";
}

Confirm () {
    printf "\n"
    choice=""
    while [[ "$choice" != "n" ]] && [[ "$choice" != "y" ]]
    do
        printf "Do you want to continue ? (N/Y)"
        read choice
        choice=$(echo ${choice} | tr '[:upper:]' '[:lower:]')
    done
    if [[ "$choice" = "n" ]]; then
        printf "\nAbort by user.\n"
        exit 0
    fi
    printf "\n"
}

ClearLogs() {
    echo "" > ${LOG_PATH}
}

# ----------------------------- COMPOSE -----------------------------

IsUpAndRunning() {
    if [[ "$(docker ps --format '{{.Names}}' | grep ${COMPOSE_PROJECT_NAME}_$1\$)" ]]
    then
        return 1
    fi
    return 0
}

ComposeUp() {
    IsUpAndRunning "${COMPOSE_PROJECT_NAME}_rsync"
    if [[ $? -eq 1 ]]
    then
        printf "\e[31mAlready up and running.\e[0m\n"
        exit 1
    fi

    printf "Composing up ... "
    docker-compose -f compose.yml up -d >> ${LOG_PATH} 2>&1 \
        && printf "\e[32mdone\e[0m\n" \
        || (printf "\e[31merror\e[0m\n" && exit 1)
}

ComposeDown() {
    printf "Composing down ... "
    docker-compose -f compose.yml down -v --remove-orphans >> ${LOG_PATH} 2>&1 \
        && printf "\e[32mdone\e[0m\n" \
        || (printf "\e[31merror\e[0m\n" && exit 1)
}

ComposeBuild() {
    printf "Building ... "

    docker-compose -f compose.yml build >> ${LOG_PATH} 2>&1 \
        && printf "\e[32mdone\e[0m\n" \
        || (printf "\e[31merror\e[0m\n" && exit 1)
}

# ----------------------------- EXEC -----------------------------

case $1 in
    # -------------- UP --------------
    up)
        ComposeUp
    ;;
    # ------------- DOWN -------------
    down)
        ComposeDown
    ;;
    # ------------- BUILD -------------
    build)
        ComposeBuild
    ;;
    # ------------- HELP --------------
    *)
        Help "Usage:  ./manage.sh [action]

\t\e[0mup\e[2m\t\t\t Create and start container.
\t\e[0mdown\e[2m\t\t Stop and remove container.
\t\e[0mbuild\e[2m\t\t Build the service image."
    ;;
esac

printf "\n"
