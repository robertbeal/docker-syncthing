FROM alpine:3.11
LABEL maintainer="github.com/robertbeal"

ARG VERSION=v1.4.2
ARG ARCH=amd64
ARG UID=770
ARG GID=770

WORKDIR /tmp

# disable upgrades
ENV STNOUPGRADE=1

#HEALTHCHECK --interval=30s --retries=3 CMD curl --fail -H \"X-API-Key: $(cat /root/.syncthing)\" http://127.0.0.1:8384/rest/system/ping || exit 1
VOLUME /config /data
EXPOSE 8384 22000 21027/UDP

COPY entrypoint.sh /usr/local/bin

RUN addgroup -g $GID syncthing \
    && adduser -s /bin/false -D -H -G syncthing -u $UID syncthing \
    && apk add --no-cache \
    curl \
    shadow \
    su-exec \
    && curl -L https://github.com/syncthing/syncthing/releases/download/$VERSION/syncthing-linux-$ARCH-$VERSION.tar.gz | tar zx \
    && mv syncthing-linux-$ARCH-$VERSION/syncthing /usr/local/bin \
    && chown -R syncthing:syncthing /usr/local/bin/syncthing /usr/local/bin/entrypoint.sh \
    && chmod 550 -R /usr/local/bin/syncthing /usr/local/bin/entrypoint.sh \
    && rm -rf /tmp/* /var/cache/apk/*

ENTRYPOINT ["entrypoint.sh"]
CMD ["-home=/config", "-no-browser"]
