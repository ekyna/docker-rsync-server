#!/bin/bash
set -e

if [[ "$1" == '/usr/bin/rsync' ]]; then

  if [[ -n ${TZ} ]] && [[ -f /usr/share/zoneinfo/${TZ} ]]; then
    ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime
    echo ${TZ} > /etc/timezone
  fi

  # Create user
  addgroup ${GROUP} -g ${GROUP_ID}
  adduser -D -u ${USER_ID} -h /data -s /bin/bash -G ${GROUP} ${USER}

  # Create volume
  chown -R ${USER}:${GROUP} /data
  chmod -R 775 /data

  eval "echo \"$(cat /rsyncd.tpl.conf)\"" > /etc/rsyncd.conf

fi

exec "$@"
