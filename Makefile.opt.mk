# -*- mode: makefile-gmake -*-

SHELL=/bin/bash

setup:
	mkdir -p /opt/weewx-wdc/data/duplicati &&\
	mkdir -p /opt/weewx-wdc/data/weewx/data &&\
	mkdir -p /opt/weewx-wdc/data/weewx/public_html &&\
	mkdir -p /opt/weewx-wdc/data/weewx/archive &&\
	mkdir -p /opt/weewx-wdc/duplicati-backup &&\
	chown root:dialout /opt/weewx-wdc/data/weewx/data &&\
	chown root:dialout /opt/weewx-wdc/data/weewx/public_html &&\
	chown root:dialout /opt/weewx-wdc/data/weewx/archive &&\
	chmod g+w /opt/weewx-wdc/data/weewx/data &&\
	chmod g+w /opt/weewx-wdc/data/weewx/public_html &&\
	chmod g+w /opt/weewx-wdc/data/weewx/archive

run:
	docker run -it --rm -e "WEEWX_UID=weewx" -e "WEEWX_GID=dialout" -v $(shell readlink -f ./data/weewx/archive):/home/weewx/archive -v $(shell readlink -f ./data/weewx/public_html):/home/weewx/public_html -v $(shell readlink -f ./data/weewx/data):/data weewx-wdc:4.10.2 --gen-test-config
