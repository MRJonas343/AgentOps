FROM alpine:3.20

RUN apk add --no-cache curl bash docker-cli

WORKDIR /app

COPY crontab /etc/crontabs/root
COPY jobs/ ./jobs/
COPY notify.sh ./notify.sh

RUN chmod +x jobs/*.sh notify.sh

CMD ["crond", "-f", "-l", "2"]
