FROM alpine:3.11

ARG VERSION=v1.4.2
ARG ARCH=amd6
ARG COMMIT_ID
ARG UID=770
ARG GID=770

LABEL maintainer="github.com/robertbeal" \
      org.label-schema.name="Syncthing" \
      org.label-schema.description="Enhanced Docker image for Syncthing" \
      org.label-schema.url="https://github.com/syncthing/syncthing" \
      org.label-schema.version=$VERSION \
      org.label-schema.vcs-ref=$COMMIT_ID \
      org.label-schema.vcs-url="https://github.com/robertbeal/docker-syncthing" \
      org.label-schema.schema-version="1.0"

WORKDIR /tmp

# disable upgrades
ENV STNOUPGRADE=1

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

HEALTHCHECK --interval=30s --retries=3 CMD curl --fail -H \"X-API-Key: $(cat /root/.syncthing)\" http://127.0.0.1:8384/rest/system/ping || exit 1
VOLUME /config /data
EXPOSE 8384 22000 21027/UDP

ENTRYPOINT ["entrypoint.sh"]
CMD ["-home=/config", "-no-browser"]
