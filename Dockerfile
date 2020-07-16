FROM alpine

ADD "entrypoint.sh" "/entrypoint.sh"
RUN sed -i "s@dl-cdn.alpinelinux.org@mirrors.aliyun.com@g" /etc/apk/repositories && \
 apk -Uuv --no-cache add curl jq bash ca-certificates && chmod +x entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]