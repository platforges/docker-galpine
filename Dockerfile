# syntax=docker/dockerfile:1
ARG ALPINE_VERSION=latest
ARG DEBIAN_VERSION=trixie
ARG GLIBC_VERSION=2.44

# Cross-compile glibc from verified GNU sources on the build host, so only the
# cheap packaging steps below need emulation
FROM --platform=$BUILDPLATFORM debian:${DEBIAN_VERSION}-slim AS builder-glibc
ARG GLIBC_VERSION
ARG TARGETARCH
ARG TARGETVARIANT
RUN case "$TARGETARCH$TARGETVARIANT" in \
        amd64)   triplet=x86_64-linux-gnu ;; \
        arm64*)  triplet=aarch64-linux-gnu ;; \
        *) echo "unsupported platform: $TARGETARCH$TARGETVARIANT" >&2; exit 1 ;; \
    esac && \
    echo "$triplet" > /triplet && echo "-O2 ${cflags:-}" > /cflags && \
    apt-get update && apt-get install -y --no-install-recommends \
        bison build-essential ca-certificates gawk gpgv python3 wget xz-utils \
        "gcc-$(echo "$triplet" | tr _ -)" "g++-$(echo "$triplet" | tr _ -)" && \
    rm -rf /var/lib/apt/lists/*
WORKDIR /usr/src/glibc
RUN wget -q https://ftp.gnu.org/gnu/gnu-keyring.gpg \
        https://ftp.gnu.org/gnu/glibc/glibc-$GLIBC_VERSION.tar.xz \
        https://ftp.gnu.org/gnu/glibc/glibc-$GLIBC_VERSION.tar.xz.sig && \
    gpgv --keyring ./gnu-keyring.gpg glibc-$GLIBC_VERSION.tar.xz.sig glibc-$GLIBC_VERSION.tar.xz && \
    tar --extract --xz --strip-components=1 --file=glibc-$GLIBC_VERSION.tar.xz && \
    rm glibc-$GLIBC_VERSION.tar.xz*
WORKDIR /usr/src/glibc-build
RUN triplet="$(cat /triplet)" && \
    /usr/src/glibc/configure \
        --build="$(gcc -dumpmachine)" \
        --host="$triplet" \
        CC="$triplet-gcc" CXX="$triplet-g++" \
        CFLAGS="$(cat /cflags)" \
        --prefix=/usr/glibc \
        --libdir=/usr/glibc/lib \
        --libexecdir=/usr/glibc/lib \
        --enable-stack-protector=strong \
        --disable-werror && \
    make -j"$(nproc)" && make install && \
    tar --create --xz --dereference --hard-dereference --file=/glibc-bin.tar.xz /usr/glibc/*

# Package glibc as .apk files for the target Alpine version
FROM alpine:${ALPINE_VERSION} AS builder-apk
ARG GLIBC_VERSION
RUN apk add --no-cache alpine-sdk && \
    adduser -D builder -G abuild && \
    mkdir -p /packages && chown builder:abuild /packages
USER builder
# NOTE packages are signed with an ephemeral build-time key
RUN abuild-keygen -an
USER root
RUN cp /home/builder/.abuild/*.rsa.pub /etc/apk/keys/
USER builder
WORKDIR /home/builder/glibc
COPY --chown=builder:abuild APKBUILD .
COPY --from=builder-glibc --chown=builder:abuild /glibc-bin.tar.xz .
RUN printf '%s\n' /usr/local/lib /usr/glibc/lib /usr/lib /lib > ld.so.conf && \
    printf '#!/bin/sh\n/usr/glibc/sbin/ldconfig\n' > glibc-bin.trigger && \
    chmod 775 glibc-bin.trigger && \
    abuild checksum && \
    abuild -P /packages && \
    mkdir /home/builder/out && \
    cp /packages/*/*/glibc-$GLIBC_VERSION-r0.apk /home/builder/out/glibc.apk && \
    cp /packages/*/*/glibc-bin-*.apk /home/builder/out/glibc-bin.apk && \
    cp /packages/*/*/glibc-i18n-*.apk /home/builder/out/glibc-i18n.apk

# Final image
FROM alpine:${ALPINE_VERSION}
ARG LANG=C.UTF-8
ARG LC_ALL=C.UTF-8
ENV LANG=$LANG LC_ALL=$LC_ALL
RUN --mount=type=bind,from=builder-apk,source=/home/builder/out,target=/tmp/apk \
    apk add --no-cache --allow-untrusted /tmp/apk/glibc.apk /tmp/apk/glibc-bin.apk /tmp/apk/glibc-i18n.apk && \
    (/usr/glibc/bin/localedef --force --inputfile POSIX --charmap UTF-8 "$LC_ALL" || true) && \
    apk del --no-cache glibc-i18n
