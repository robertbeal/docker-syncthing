FROM alpine:3.11

ARG VERSION
ARG VCS_REF
ARG ARCH=amd64
ARG UID=770
ARG GID=770

LABEL \
    org.opencontainers.image.authors="github.com/robertbeal" \
    org.opencontainers.image.revision=$VCS_REF \
    org.opencontainers.image.version=$VERSION \
    org.opencontainers.image.source="https://github.com/robertbeal/docker-syncthing"

WORKDIR /tmp

RUN addgroup -g $GID syncthing \
    && adduser -s /bin/false -D -H -G syncthing -u $UID syncthing \
    && apk add --no-cache \
    curl \
    shadow \
    su-exec \
    && curl -L https://github.com/syncthing/syncthing/releases/download/$VERSION/syncthing-linux-$ARCH-$VERSION.tar.gz | tar zx \
    && mkdir /app \
    && mv syncthing-linux-$ARCH-$VERSION/syncthing /app \
    && chown -R syncthing:syncthing /app \
    && chmod 550 -R /app \
    && rm -rf /tmp/* /var/cache/apk/*

HEALTHCHECK --interval=30s --retries=3 CMD curl --fail -H \"X-API-Key: $(cat /root/.syncthing)\" http://127.0.0.1:8384/rest/system/ping || exit 1
VOLUME /config /data
EXPOSE 8384 22000 21027/UDP

# disable upgrades
ENV STNOUPGRADE=1

COPY entrypoint.sh /usr/local/bin
RUN chmod 555 /usr/local/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]
CMD ["-home=/config", "-no-browser"]
