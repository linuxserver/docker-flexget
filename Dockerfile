# syntax=docker/dockerfile:1

FROM ghcr.io/linuxserver/unrar:latest AS unrar

FROM ghcr.io/by275/libtorrent:2-alpine3.19 AS libtorrent

FROM ghcr.io/linuxserver/baseimage-alpine:3.19

COPY --from=ghcr.io/astral-sh/uv:0.5.26 /uv /uvx /bin/

# set version label
ARG BUILD_DATE
ARG VERSION
ARG FLEXGET_VERSION
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="thespad"

# environment settings
ENV HOME="/config" \
  PYTHONIOENCODING=utf-8 \
  TMPDIR=/run/flexget-temp \
  UV_PROJECT_ENVIRONMENT=/lsiopy \
  UV_COMPILE_BYTECODE=1 \
  UV_LINK_MODE=copy

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
  mkdir -p /run/flexget-temp /data && \
  mkdir -p /app/flexget && \
  curl -o \
    /tmp/flexget.tar.gz -L \
    "https://github.com/Flexget/Flexget/archive/refs/tags/${FLEXGET_VERSION}.tar.gz" && \
  tar xf \
    /tmp/flexget.tar.gz -C \
    /app/flexget --strip-components=1 && \
  cd /app/flexget && \
  uv venv /lsiopy && \
  uv run scripts/bundle_webui.py && \
  uv sync --frozen --no-dev --no-cache --group=all && \
  uv pip install pip && \
  printf "Linuxserver.io version: ${VERSION}\nBuild-date: ${BUILD_DATE}" > /build_version && \
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
