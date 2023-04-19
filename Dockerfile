FROM python:3.10-buster
# docker build . -t "weewx-wdc:4.10.2"
# mkdir -p /opt/weewx-wdc/data/duplicati
# mkdir -p /opt/weewx-wdc/data/weewx/data
# mkdir -p /opt/weewx-wdc/data/weewx/public_html
# mkdir -p /opt/weewx-wdc/data/weewx/archive
# mkdir -p /opt/weewx-wdc/duplicati-backup
# chown root:dialout /opt/weewx-wdc/data/weewx/data
# chown root:dialout /opt/weewx-wdc/data/weewx/public_html
# chown root:dialout /opt/weewx-wdc/data/weewx/archive
# chmod g+w /opt/weewx-wdc/data/weewx/data
# chmod g+w /opt/weewx-wdc/data/weewx/public_html
# chmod g+w /opt/weewx-wdc/data/weewx/archive
# docker run -it --rm -v $(readlink -f ./data/weewx/archive):/home/weewx/archive -v $(readlink -f ./data/weewx/public_html):/home/weewx/public_html -v $(readlink -f ./data/weewx/data):/data              weewx-wdc:4.10.2 --gen-test-config
# docker run -it --rm -v $(shell readlink -f ./data/weewx/archive):/home/weewx/archive -v $(shell readlink -f ./data/weewx/public_html):/home/weewx/public_html -v $(shell readlink -f ./data/weewx/data):/data              weewx-wdc --gen-test-config
# docker run -it --rm -v $(shell readlink -f ./archive):/home/weewx/archive -v $(shell readlink -f ./public_html):/home/weewx/public_html -v $(shell readlink -f ./data):/data -p 9877:9877 weewx-wdc

LABEL org.opencontainers.image.authors="David Baetge <david.baetge@gmail.com>"

ARG WEEWX_VERSION="4.10.2"
ARG WDC_VERSION="v3.1.1"
ARG WEEWX_UID=421
ENV WEEWX_HOME="/home/weewx"
ARG ARCHIVE="weewx-${WEEWX_VERSION}.tar.gz"

EXPOSE 9877

COPY src/install-input.txt /tmp/
COPY src/start.sh /start.sh
COPY src/entrypoint.sh /entrypoint.sh
COPY src/weewx-dwd.conf /tmp/weewx-dwd.conf
RUN chmod +x /start.sh
RUN chmod +x /entrypoint.sh

# @see https://blog.nuvotex.de/running-syslog-in-a-container/
# RUN apt-get update && apt-get install -q -y --no-install-recommends rsyslog=8.1901.0-1+deb10u2 cron=3.0pl1-134+deb10u1 python3-configobj=5.0.6-3 python3-requests=2.21.0-1 python3-paho-mqtt=1.4.0-1 && apt-get clean && rm -rf /var/lib/apt/lists/*
RUN apt-get update && apt-get install -y libusb-1.0-0 gosu busybox-syslogd tzdata cron=3.0pl1-134+deb10u1 python3-configobj=5.0.6-3 python3-requests=2.21.0-1 python3-paho-mqtt=1.4.0-1


RUN addgroup --system --gid ${WEEWX_UID} weewx &&\
    adduser --system --uid ${WEEWX_UID} --ingroup weewx weewx

# Configure timezone.
RUN ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime

WORKDIR /tmp

# wget -nv -O "weewx-${WEEWX_VERSION}.tar.gz" "https://github.com/weewx/weewx/archive/refs/tags/v${WEEWX_VERSION}.tar.gz" &&\ # RUN wget -O "${ARCHIVE}" "https://weewx.com/downloads/released_versions/${ARCHIVE}"
RUN wget -nv -O "weewx-${WEEWX_VERSION}.tar.gz" "https://weewx.com/downloads/released_versions/${ARCHIVE}" &&\
    wget -nv -O "weewx-interceptor.zip" "https://github.com/matthewwall/weewx-interceptor/archive/master.zip" &&\
    wget -nv -O "weewx-wdc-${WDC_VERSION}.zip" "https://github.com/Daveiano/weewx-wdc/releases/download/${WDC_VERSION}/weewx-wdc-${WDC_VERSION}.zip" &&\
    wget -nv -O "weewx-dwd.zip" "https://github.com/roe-dl/weewx-DWD/archive/refs/heads/master.zip" &&\
    wget -nv -O "weewx-forecast.zip" "https://github.com/chaunceygardiner/weewx-forecast/archive/refs/heads/master.zip" &&\
    wget -nv -O "weewx-mqtt.zip" https://github.com/matthewwall/weewx-mqtt/archive/master.zip &&\
    tar xvfz "weewx-${WEEWX_VERSION}.tar.gz"

RUN mkdir /tmp/weewx-wdc/ &&\
    unzip /tmp/weewx-wdc-${WDC_VERSION}.zip -d /tmp/weewx-wdc/

# weewx-dwd
RUN mkdir /tmp/weewx-dwd/ &&\
    unzip /tmp/weewx-dwd.zip -d /tmp/weewx-dwd/ &&\
    cp -R /tmp/weewx-dwd/weewx-DWD-master/usr/ / &&\
    cp -R /tmp/weewx-dwd/weewx-DWD-master/etc/ / &&\
    sed -i -z -e "s|PTH=\"/etc/weewx/skins/Belchertown/dwd\"|PTH=\"/home/weewx/skins/weewx-wdc/dwd\"|g" /usr/local/bin/wget-dwd &&\
    sed -i -z -e "s|config = configobj.ConfigObj(\"/etc/weewx/weewx.conf\")|config = configobj.ConfigObj(\"/home/weewx/weewx.conf\")|g" /usr/local/bin/dwd-warnings &&\
    sed -i -z -e "s|#/usr/local/bin/dwd-cap-warnings --weewx --resolution=city 2>/dev/null >/dev/null|/usr/local/bin/dwd-cap-warnings --weewx --resolution=city 2>/dev/null >/dev/null|g" /etc/cron.hourly/dwd &&\
    sed -i -z -e "s|#/usr/local/bin/dwd-mosmix --weewx --daily --hourly XXXXX 2>/dev/null >/dev/null|/usr/local/bin/dwd-mosmix --weewx --daily --hourly O461 2>/dev/null >/dev/null|g" /etc/cron.hourly/dwd

# Icons
RUN wget -nv -O "icons-dwd.zip" "https://www.dwd.de/DE/wetter/warnungen_aktuell/objekt_einbindung/icons/wettericons_zip.zip?__blob=publicationFile&v=3" &&\
    wget -nv -O "warnicons-dwd.zip" "https://www.dwd.de/DE/wetter/warnungen_aktuell/objekt_einbindung/icons/warnicons_nach_stufen_50x50_zip.zip?__blob=publicationFile&v=2" &&\
    wget -nv -O "icons-carbon.zip" "https://public-images-social.s3.eu-west-1.amazonaws.com/weewx-wdc-carbon-icons.zip" &&\
    mkdir -p /home/weewx/public_html/dwd/icons && mkdir -p /home/weewx/public_html/dwd/warn_icons &&\
    unzip /tmp/icons-dwd.zip -d /home/weewx/public_html/dwd/icons &&\
    unzip /tmp/icons-carbon.zip -d /home/weewx/public_html/dwd/icons &&\
    unzip /tmp/warnicons-dwd.zip -d /home/weewx/public_html/dwd/warn_icons

WORKDIR /tmp/weewx-${WEEWX_VERSION}

RUN pip install --no-cache-dir -r ./requirements.txt &&\
    pip install --no-cache-dir paho-mqtt==1.6.1 &&\
    python ./setup.py build && python ./setup.py install < /tmp/install-input.txt

WORKDIR ${WEEWX_HOME}

RUN bin/wee_extension --install /tmp/weewx-interceptor.zip &&\
    bin/wee_extension --install /tmp/weewx-forecast.zip &&\
    bin/wee_extension --install /tmp/weewx-mqtt.zip &&\
    bin/wee_extension --install /tmp/weewx-wdc/ &&\
    bin/wee_config --reconfigure --driver=user.interceptor --no-prompt &&\
    bin/wee_extension --list

COPY src/skin.conf ./skins/weewx-wdc/

# weewx-wdc.
RUN sed -i -e 's/device_type = acurite-bridge/device_type = ecowitt-client\n    port = 9877\n    address = 0.0.0.0/g' weewx.conf &&\
    sed -i -z -e 's/skin = Seasons\n        enable = true/skin = Seasons\n        enable = false/g' weewx.conf &&\
    sed -i -z -e 's/skin = forecast/skin = forecast\n        enable = false/g' weewx.conf &&\
    cat /tmp/weewx-dwd.conf >> weewx.conf

# weewx-mqtt.
RUN sed -i -z -e 's|INSERT_SERVER_URL_HERE|mqtt://user:password@host:port\n        topic = weather\n        unit_system = METRIC\n        binding = loop\n        [[[inputs]]]\n            [[[[windSpeed]]]]\n                format = %.0f\n            [[[[windGust]]]]\n                format = %.0f|g' weewx.conf

VOLUME [ "${WEEWX_HOME}/public_html" ]
VOLUME [ "${WEEWX_HOME}/archive" ]

RUN mkdir /data && \
  cp weewx.conf /data && \
  chown -R weewx:weewx ${WEEWX_HOME}

VOLUME ["/data"]

ENTRYPOINT [ "/entrypoint.sh" ]
CMD ["/data/weewx.conf"]
