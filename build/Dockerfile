FROM alpine
MAINTAINER Etienne Dauvergne <contact@ekyna.com>

RUN apk add --update --no-cache rsync bash tzdata

COPY entrypoint.sh /
COPY rsyncd.tpl.conf /
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

RUN chmod +x /entrypoint.sh

ENV TZ="Europe/Paris" \
    LANG="C.UTF-8"

EXPOSE 873

ENTRYPOINT [ "/entrypoint.sh" ]

CMD [ "/usr/bin/rsync", "--no-detach", "--daemon", "--log-file=/dev/stdout" ]
