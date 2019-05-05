#!/bin/bash

cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [[ ! -f .env ]]
then
    printf "\e[31mPlease create .env file.\e[0m\n"
    exit 1
fi

source .env

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

# ----------------------------- VOLUME -----------------------------

VolumeCreate() {
    printf "Creating volume \e[1;33m$1\e[0m ... "
    if [[ "$(docker volume ls --format '{{.Name}}' | grep $1\$)" ]]
    then
        printf "\e[36mexists\e[0m\n"
    else
        docker volume create --name $1 >> ${LOG_PATH} 2>&1 \
            && printf "\e[32mcreated\e[0m\n" \
            || (printf "\e[31merror\e[0m\n" && exit 1)
    fi
}

VolumeRemove() {
    printf "Removing volume \e[1;33m$1\e[0m ... "
    if [[ "$(docker volume ls --format '{{.Name}}' | grep $1\$)" ]]
    then
        docker volume rm $1 >> ${LOG_PATH} 2>&1 \
            && printf "\e[32mremoved\e[0m\n" \
            || (printf "\e[31merror\e[0m\n" && exit 1)
    else
        printf "\e[35munknown\e[0m\n"
    fi
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

# ----------------------------- INTERNAL -----------------------------

CreateNetworkAndVolumes() {
    VolumeCreate "${COMPOSE_PROJECT_NAME}-data"
}

RemoveNetworkAndVolumes() {
    VolumeRemove "${COMPOSE_PROJECT_NAME}-data"
}

Reset() {
    ComposeDown
    RemoveNetworkAndVolumes

    sleep 3

    CreateNetworkAndVolumes
    ComposeUp
}

# ----------------------------- EXEC -----------------------------

case $1 in
    # -------------- UP --------------
    up)
        CreateNetworkAndVolumes

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
    # ------------- RESET ------------
    reset)
        Title "Resetting stack"
        Warning "All data will be lost !"
        Confirm

        Reset
    ;;
    # ------------- HELP --------------
    *)
        Help "Usage:  ./manage.sh [action]

\t\e[0mup\e[2m\t\t\t Create and start container.
\t\e[0mdown\e[2m\t\t Stop and remove container.
\t\e[0mbuild\e[2m\t\t Build the service image.
\t\e[0mreset\e[2m\t\t Reset the stack and data volume."
    ;;
esac

printf "\n"
