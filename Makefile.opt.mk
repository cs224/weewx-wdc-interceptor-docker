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
	chmod g+w /opt/weewx-wdc/data/weewx/archive &&\
