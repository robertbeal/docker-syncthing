FROM golang:1.17-alpine3.15 as builder

ARG VERSION=v1.8.0

RUN apk add --no-cache \
	curl \
	g++ \
	gcc \
	git \
	tar

RUN curl -o /tmp/src.tar.gz -L "https://github.com/syncthing/syncthing/archive/$VERSION.tar.gz"
RUN mkdir -p /tmp/src
RUN tar xvf /tmp/src.tar.gz -C /tmp/src --strip=1

WORKDIR /tmp/src
RUN rm -f go.sum
RUN go clean -modcache
RUN CGO_ENABLED=0 go run build.go \
	-no-upgrade \
	-version=$VERSION \
	build syncthing

COPY entrypoint.sh /tmp

FROM alpine:3.15.0

ARG VERSION
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

COPY --from=builder /tmp/src/syncthing /tmp/entrypoint.sh /usr/bin/

RUN addgroup -g $GID syncthing \
    && adduser -s /bin/false -D -H -G syncthing -u $UID syncthing \
    && apk add --no-cache \
    curl \
    shadow \
    su-exec \
    && chown -R syncthing:syncthing /usr/bin/syncthing /usr/bin/entrypoint.sh \
    && chmod 550 -R /usr/bin/syncthing /usr/bin/entrypoint.sh \
    && rm -rf /tmp/* /var/cache/apk/*

HEALTHCHECK --interval=30s --retries=3 CMD curl --fail -H \"X-API-Key: $(cat /root/.syncthing)\" http://127.0.0.1:8384/rest/system/ping || exit 1
VOLUME /config /data
EXPOSE 8384 22000 21027/UDP

ENTRYPOINT ["/usr/bin/entrypoint.sh"]
CMD ["-home=/config", "-no-browser"]
