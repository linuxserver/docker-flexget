# syntax=docker/dockerfile:1

FROM ghcr.io/linuxserver/unrar:latest as unrar

FROM ghcr.io/by275/libtorrent:2-alpine3.19 as libtorrent

FROM ghcr.io/linuxserver/baseimage-alpine:3.19

# set version label
ARG BUILD_DATE
ARG VERSION
ARG FLEXGET_VERSION
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="thespad"

# environment settings
ENV HOME="/config" \
  PYTHONIOENCODING=utf-8

RUN \
  echo "**** install packages ****" && \
  apk add -U --update --no-cache --virtual=build-dependencies \
    build-base \
    libffi-dev \
    python3-dev && \
  apk add  -U --update --no-cache \
    7zip \
    boost1.82-system \
    boost1.82-python3 \
    libstdc++ \
    nodejs \
    python3 && \
  echo "**** install flexget ****" && \
  if [ -z ${FLEXGET_VERSION+x} ]; then \
    FLEXGET_VERSION=$(curl -s https://api.github.com/repos/flexget/flexget/releases/latest \
    | awk '/tag_name/{print $4;exit}' FS='[""]'); \
  fi && \
  mkdir -p /tmp/flexget && \
  curl -o \
    /tmp/flexget.tar.gz -L \
    "https://github.com/flexget/flexget/releases/download/${FLEXGET_VERSION}/FlexGet-${FLEXGET_VERSION#v}.tar.gz" && \
  tar xf \
    /tmp/flexget.tar.gz -C \
    /tmp/flexget --strip-components=1 && \
  cd /tmp/flexget && \
  python3 -m venv /lsiopy && \
  pip install -U --no-cache-dir \
    pip \
    wheel && \
  pip install -U --no-cache --find-links https://wheel-index.linuxserver.io/alpine-3.19/ \
    click \
    flexget==${FLEXGET_VERSION#v} \
    requests \
    -r requirements-docker.txt && \
  echo "**** cleanup ****" && \
  apk del --purge \
    build-dependencies && \
  rm -rf \
    /tmp/* \
    $HOME/.cache

COPY --from=libtorrent /libtorrent-build/usr/lib/libtorrent-rasterbar.* /usr/lib/

COPY --from=libtorrent /libtorrent-build/usr/lib/python3.11 /lsiopy/lib/python3.11

# add local files
COPY root/ /

# add unrar
COPY --from=unrar /usr/bin/unrar-alpine /usr/bin/unrar

# ports and volumes
EXPOSE 5050
VOLUME /config
