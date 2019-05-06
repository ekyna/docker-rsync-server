#!/bin/bash
set -e

if [[ "$1" == '/usr/bin/rsync' ]]; then

  if [[ -n ${TZ} ]] && [[ -f /usr/share/zoneinfo/${TZ} ]]; then
    ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime
    echo ${TZ} > /etc/timezone
  fi

  # Volume
  if [[ ! -d /data ]]
  then
    mkdir /data
  fi

  # Group
  if [[ 1 -eq $(id -g ${GROUP} > /dev/null 2>&1; echo $?) ]]
  then
    addgroup ${GROUP} -g ${GROUP_ID}
  fi

  # User
  if [[ 1 -eq $(id -u ${USER} > /dev/null 2>&1; echo $?) ]]
  then
    adduser -D -u ${USER_ID} -h /data -s /bin/bash -G ${GROUP} ${USER}
  fi

  # Permissions
  chown -R ${USER}:${GROUP} /data
  chmod -R 775 /data

  eval "echo \"$(cat /rsyncd.tpl.conf)\"" > /etc/rsyncd.conf

fi

exec "$@"
