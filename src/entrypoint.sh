# syntax=docker/dockerfile:1

ARG PYTHON_VERSION=3.11.2
ARG WEEWX_UID=421
ARG WEEWX_VERSION=4.10.2
ARG WEEWX_HOME="/home/weewx"
ARG WDC_VERSION="v3.1.1"

FROM --platform=$BUILDPLATFORM tonistiigi/xx AS xx

FROM --platform=$BUILDPLATFORM python:${PYTHON_VERSION} as build-stage

ARG WEEWX_VERSION
ARG ARCHIVE="weewx-${WEEWX_VERSION}.tar.gz"
ARG WEEWX_HOME
ARG WDC_VERSION

COPY --from=xx / /
RUN apt-get update && apt-get install -y clang lld
ARG TARGETPLATFORM
RUN xx-apt install -y libc6-dev

# RUN apk --no-cache add cargo gcc libffi-dev make musl-dev openssl-dev python3-dev tar
RUN apt-get install -y wget

WORKDIR /tmp
RUN \
  --mount=type=cache,mode=0777,target=/var/cache/apt \
  --mount=type=cache,mode=0777,target=/root/.cache/pip <<EOF
apt-get update
python -m pip install --upgrade pip
pip install --upgrade virtualenv
virtualenv /opt/venv
EOF

COPY src/hashes README.md requirements.txt setup.py ./
COPY src/_version.py ./src/_version.py

# Download sources and verify hashes
RUN wget -O "${ARCHIVE}" "https://weewx.com/downloads/released_versions/${ARCHIVE}"
RUN wget -O weewx-mqtt.zip https://github.com/matthewwall/weewx-mqtt/archive/master.zip
RUN wget -O weewx-interceptor.zip https://github.com/matthewwall/weewx-interceptor/archive/master.zip
RUN sha256sum -c < hashes
RUN wget -nv -O "weewx-forecast.zip" "https://github.com/chaunceygardiner/weewx-forecast/archive/refs/heads/master.zip"
RUN wget -nv -O "weewx-wdc-${WDC_VERSION}.zip" "https://github.com/Daveiano/weewx-wdc/releases/download/${WDC_VERSION}/weewx-wdc-${WDC_VERSION}.zip"

RUN mkdir ${WEEWX_HOME}
# WeeWX setup
RUN tar --extract --gunzip --directory /home/weewx --strip-components=1 --file "${ARCHIVE}"

# Python setup
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
RUN pip install --no-cache --requirement requirements.txt

RUN pip install --no-cache wheel setuptools
RUN pip install --no-cache configobj paho-mqtt pyserial pyusb
RUN pip install --no-cache Cheetah3
RUN pip install --no-cache Pillow==9.4.0
RUN pip install --no-cache ephem

RUN mkdir /tmp/weewx-wdc/ &&\
    unzip /tmp/weewx-wdc-${WDC_VERSION}.zip -d /tmp/weewx-wdc/

WORKDIR ${WEEWX_HOME}

RUN bin/wee_extension --install /tmp/weewx-mqtt.zip
RUN bin/wee_extension --install /tmp/weewx-interceptor.zip
RUN bin/wee_extension --install /tmp/weewx-forecast.zip
RUN bin/wee_extension --install /tmp/weewx-wdc/
RUN bin/wee_config --reconfigure --driver=user.interceptor --no-prompt

RUN ls -l ./skins
RUN ls -l ./skins/weewx-wdc
RUN wget -nv -O ./skins/weewx-wdc/skin.conf https://raw.githubusercontent.com/Daveiano/weewx-wdc-interceptor-docker/main/src/skin.conf

COPY src/entrypoint.sh src/_version.py ./

FROM python:${PYTHON_VERSION}-slim-bullseye as final-stage

ARG TARGETPLATFORM
ARG WEEWX_HOME
ARG WEEWX_UID

# For a list of pre-defined annotation keys and value types see:
# https://github.com/opencontainers/image-spec/blob/master/annotations.md
# Note: Additional labels are added by the build workflow.
LABEL org.opencontainers.image.authors="markf+github@geekpad.com"
LABEL org.opencontainers.image.vendor="Geekpad"
LABEL com.weewx.version=${WEEWX_VERSION}

RUN addgroup --system --gid ${WEEWX_UID} weewx \
  && adduser --system --uid ${WEEWX_UID} --ingroup weewx weewx

RUN apt-get update && apt-get install -y libusb-1.0-0 gosu busybox-syslogd tzdata

WORKDIR ${WEEWX_HOME}

COPY --from=build-stage /opt/venv /opt/venv
COPY --from=build-stage ${WEEWX_HOME} ${WEEWX_HOME}

RUN mkdir /data && \
  cp weewx.conf /data && \
  chown -R weewx:weewx ${WEEWX_HOME}

VOLUME ["/data"]

ENV PATH="/opt/venv/bin:$PATH"
ENTRYPOINT ["./entrypoint.sh"]
CMD ["/data/weewx.conf"]
