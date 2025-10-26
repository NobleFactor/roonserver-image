#################################################
# Copyright (c) 2024 Noble Factor
# SPDX Document reference
#################################################

# TODO (DANOBLE) Reference SPDX document that references MIT and Roon software terms and conditions.
# TODO (david-noble) Contact original author about his license and on how to credit/collaborate with him.
# TODO (david-noble) Ensure that we comply with the OCI Image Format Specification at https://github.com/opencontainers/image-spec.
# TODO (david-noble) Ensure that the license expression specifies MIT AND the Roon license at https://roon.app/en/termsandconditions.

FROM debian:trixie-slim

LABEL org.opencontainers.image.vendor="Noble Factor"
LABEL org.opencontainers.image.authors="David-Noble@noblefactor.com"
LABEL org.opencontainers.image.licenses="MIT AND LicenseRef:Roon-software-terms-and-conditions https://roon.app/en/termsandconditions"

# Default values are shared with makefile as a convenience for those who might build from docker command line

ARG prefix=/opt/local

ARG roon_serverroot=${prefix}/share/roon/roonserver
ARG roon_dataprefix=${prefix}/var/roon
ARG roon_user=roon

# Environment variables are used by Install-RoonServer which is invoked by docker-entrypoint

ENV ROON_SERVERROOT=${roon_serverroot}
ENV ROON_DATAPREFIX=${roon_dataprefix}
ENV ROON_USER=${roon_user}

RUN <<EOF
set | grep ROON_ ;# print environment for diagnostic purposes
set -o errexit -o nounset -o pipefail -o xtrace

mkdir -p "${ROON_SERVERROOT}" "${ROON_DATAPREFIX}" /lib/systemd/system /run/systemd/system
ln --force --symbolic /usr/share/zoneinfo/Etc/UTC /etc/localtime

apt-get --yes update
apt-get --yes upgrade
apt-get --yes install bash bzip2 curl ffmpeg cifs-utils libasound2 libicu76
apt-get --yes install --no-install-recommends dbus avahi-daemon avahi-utils libnss-mdns ca-certificates procps
apt-get autoremove
apt-get clean
rm -rf /var/lib/apt/lists/*
EOF

# Setup environment (we switch to the Roon user when the container starts after we're up and running)

HEALTHCHECK --interval=30s --timeout=3s CMD avahi-browse -t -a || exit 1
VOLUME [\
 "${roon_dataprefix}/backup",\
 "${roon_dataprefix}/data",\
 "${roon_dataprefix}/music" ]
WORKDIR /app
COPY assets/roonserver-service assets/Start-AvahiDaemon assets/Install-RoonServerService ./
RUN <<EOF
chmod -R u=rwx,g=rx,o=r /app
EOF

ENTRYPOINT [ "/app/roonserver-service" ]
