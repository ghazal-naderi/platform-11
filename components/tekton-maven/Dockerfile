
FROM docker:19.03.6

RUN apk add --no-cache openjdk11 maven

COPY entrypoint.sh /

RUN chmod 755 /entrypoint.sh

ENTRYPOINT [ "/entrypoint.sh" ]
