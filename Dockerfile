FROM alpine:3.11
ARG VERSION=v0.1.0
ARG APK_URL=https://github.com/3778/docker-galpine/releases/download/$VERSION
ARG LANG=C.UTF-8
ARG LC_ALL=C.UTF-8
ENV LANG=$LANG LC_ALL=$LC_ALL

# TODO can we parametrize UTF-8 with build ARG? can we run `localedef` in a previous build step?
RUN apk add --no-cache --virtual=.build-dependencies wget ca-certificates && \
    wget $APK_URL/glibc.apk $APK_URL/glibc-bin.apk $APK_URL/glibc-i18n.apk && \
    apk add --allow-untrusted --no-cache /glibc.apk /glibc-bin.apk /glibc-i18n.apk && \
    /usr/glibc/bin/localedef --force --inputfile POSIX --charmap UTF-8 $LC_ALL || true && \
    apk del glibc-i18n && apk del .build-dependencies && rm /*.apk

