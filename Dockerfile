FROM alpine:3.20

ARG TARGETARCH

RUN apk add --no-cache bash ca-certificates curl tzdata

RUN case "${TARGETARCH}" in \
      "amd64") TOOLS_ARCH="x86_64" ;; \
      "arm64") TOOLS_ARCH="aarch64" ;; \
      *) echo "Unsupported arch: ${TARGETARCH}" && exit 1 ;; \
    esac \
 && curl -fsSL "https://fastdl.mongodb.org/tools/db/mongodb-database-tools-ubuntu2204-${TOOLS_ARCH}-100.13.0.tgz" -o /tmp/mongodb-tools.tgz \
 && tar -xzf /tmp/mongodb-tools.tgz -C /tmp \
 && cp /tmp/mongodb-database-tools-*/bin/mongodump /usr/local/bin/ \
 && rm -rf /tmp/mongodb-tools.tgz /tmp/mongodb-database-tools-*

RUN case "${TARGETARCH}" in \
      "amd64") SUPERCRONIC_ARCH="amd64" ;; \
      "arm64") SUPERCRONIC_ARCH="arm64" ;; \
      *) echo "Unsupported arch: ${TARGETARCH}" && exit 1 ;; \
    esac \
 && curl -fsSL "https://github.com/aptible/supercronic/releases/download/v0.2.39/supercronic-linux-${SUPERCRONIC_ARCH}" -o /usr/local/bin/supercronic \
 && chmod +x /usr/local/bin/supercronic

WORKDIR /app

COPY mongodb-backup.sh /app/mongodb-backup.sh
COPY crontab /app/crontab

RUN chmod +x /app/mongodb-backup.sh

CMD ["/usr/local/bin/supercronic", "/app/crontab"]