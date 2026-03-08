FROM debian:12-slim

ARG TARGETARCH

RUN apt-get update \
 && apt-get install -y --no-install-recommends bash ca-certificates curl tzdata \
 && rm -rf /var/lib/apt/lists/*

# Install MongoDB Database Tools
RUN case "${TARGETARCH}" in \
      "amd64") TOOLS_ARCH="x86_64" ;; \
      "arm64") TOOLS_ARCH="arm64" ;; \
      *) echo "Unsupported arch: ${TARGETARCH}" && exit 1 ;; \
    esac \
 && curl -fsSL "https://fastdl.mongodb.org/tools/db/mongodb-database-tools-debian12-${TOOLS_ARCH}-100.14.1.tgz" -o /tmp/mongodb-tools.tgz \
 && tar -xzf /tmp/mongodb-tools.tgz -C /tmp \
 && cp /tmp/mongodb-database-tools-*/bin/mongodump /usr/local/bin/ \
 && cp /tmp/mongodb-database-tools-*/bin/mongorestore /usr/local/bin/ \
 && rm -rf /tmp/mongodb-tools.tgz /tmp/mongodb-database-tools-*

# Install Supercronic
RUN case "${TARGETARCH}" in \
      "amd64") SUPERCRONIC_ARCH="amd64" ;; \
      "arm64") SUPERCRONIC_ARCH="arm64" ;; \
      *) echo "Unsupported arch: ${TARGETARCH}" && exit 1 ;; \
    esac \
 && curl -fsSL "https://github.com/aptible/supercronic/releases/download/v0.2.39/supercronic-linux-${SUPERCRONIC_ARCH}" \
      -o /usr/local/bin/supercronic \
 && chmod +x /usr/local/bin/supercronic

WORKDIR /app

COPY mongodb-backup.sh /app/mongodb-backup.sh
COPY crontab /app/crontab

RUN chmod +x /app/mongodb-backup.sh

CMD ["/usr/local/bin/supercronic", "/app/crontab"]