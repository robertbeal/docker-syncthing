FROM alpine:3.11 AS builder

ARG VERSION="v1.4.2"
ARG ARCH=amd64

RUN apk add curl jq
RUN curl -L "https://github.com/syncthing/syncthing/releases/download/$VERSION/syncthing-linux-$ARCH-$VERSION.tar.gz" | tar zx \
    && mv syncthing-linux-$ARCH-$VERSION/syncthing .

FROM alpine:3.11

ARG VCS_REF
ARG UID=770
ARG GID=770

LABEL \
    org.opencontainers.image.authors="github.com/robertbeal" \
    org.opencontainers.image.revision=$VCS_REF \
    org.opencontainers.image.source="https://github.com/robertbeal/docker-syncthing"

# disable upgrades
ENV STNOUPGRADE=1

EXPOSE 8384 22000 21027/UDP
VOLUME /config /data

RUN addgroup -g $GID syncthing \
    && adduser -s /bin/false -D -H -G syncthing -u $UID syncthing \
    && apk add --no-cache \
    curl \
    shadow \
    su-exec \
    && rm -rf /tmp/* /var/cache/apk/*

COPY --chown=syncthing:syncthing --from=builder /syncthing /usr/local/bin
COPY --chown=syncthing:syncthing entrypoint.sh /usr/local/bin

HEALTHCHECK --interval=30s --retries=3 CMD curl --fail -H \"X-API-Key: $(cat /root/.syncthing)\" http://127.0.0.1:8384/rest/system/ping || exit 1

ENTRYPOINT ["entrypoint.sh"]
CMD ["-home=/config", "-no-browser"]
