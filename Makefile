# -*- mode: makefile-gmake -*-

SHELL=/bin/bash

build:
	sudo docker build . -t "weewx-wdc:4.10.2"