ARG VERSION=v1.4.2

FROM alpine:3.12 as builder

# build variables
ARG SYNCTHING_RELEASE

RUN \
 echo "**** install build packages ****" && \
 apk add --no-cache \
	curl \
	g++ \
	gcc \
	git \
	go \
	tar

WORKDIR /tmp

RUN curl -o /tmp/syncthing-src.tar.gz -L "https://github.com/syncthing/syncthing/archive/${SYNCTHING_RELEASE}.tar.gz" && \
 tar xf /tmp/syncthing-src.tar.gz -C /tmp/src --strip-components=1 && \
 cd /tmp/src && \
 rm -f go.sum && \
 go clean -modcache && \
 CGO_ENABLED=0 go run build.go \
	-no-upgrade \
	-version=$VERSION \
	build syncthing

ARG COMMIT_ID
ARG UID=770
ARG GID=770

FROM alpine:3.12

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

COPY --from=builder /tmp/src/syncthing /usr/bin/
COPY entrypoint.sh /usr/local/bin

RUN addgroup -g $GID syncthing \
    && adduser -s /bin/false -D -H -G syncthing -u $UID syncthing \
    && apk add --no-cache \
    curl \
    shadow \
    su-exec \
    && chown -R syncthing:syncthing /usr/bin/syncthing /usr/local/bin/entrypoint.sh \
    && chmod 550 -R /usr/bin/syncthing /usr/local/bin/entrypoint.sh \
    && rm -rf /tmp/* /var/cache/apk/*

HEALTHCHECK --interval=30s --retries=3 CMD curl --fail -H \"X-API-Key: $(cat /root/.syncthing)\" http://127.0.0.1:8384/rest/system/ping || exit 1
VOLUME /config /data
EXPOSE 8384 22000 21027/UDP

ENTRYPOINT ["entrypoint.sh"]
CMD ["-home=/config", "-no-browser"]
