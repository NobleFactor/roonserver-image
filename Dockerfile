#################################################
# Copyright (c) 2024 Noble Factor
# SPDX Document reference
#############################################

# TODO (DANOBLE) Reference SPDX document that references MIT and Roon software terms and conditions.
# TODO (david-noble) Contact original author about his license and on how to credit/collaborate with him.
# TODO (david-noble) Ensure that we comply with the OCI Image Format Specification at https://github.com/opencontainers/image-spec.
# TODO (david-noble) Ensure that the license expression specifies MIT AND the Roon license at https://roon.app/en/termsandconditions.

FROM ubuntu:latest

LABEL org.opencontainers.image.vendor="Noble Factor"
LABEL org.opencontainers.image.authors="David-Noble@noblefactor.com"
LABEL org.opencontainers.image.licenses="MIT AND LicenseRef:Roon-software-terms-and-conditions https://roon.app/en/termsandconditions"

ARG prefix=/opt/local

ENV ROON_SERVERROOT=${prefix}/share/roon/roonserver
ENV ROON_DATAROOT=${prefix/var/roon}

RUN <<EOF
ln --force --symbolic /usr/share/zoneinfo/Etc/UTC /etc/localtime
mkdir -p "${ROON_SERVERROOT}"
apt-get update
apt-get -y upgrade
apt-get -y install bash curl bzip2 ffmpeg cifs-utils alsa-utils libicu74
EOF

ADD deploy-roonserver /

VOLUME [\
 "${ROON_DATAROOT}/data",\
 "${ROON_DATAROOT}}/music",\
 "${ROON_DATAROOT}}/backup" ]

ENTRYPOINT [ "/deploy-roonserver" ]
