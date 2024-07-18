# Makefile for installation of echomav_deploy on EchoPilot AI hardware
# This is installation of mavlink-router, cockpit and network setup
.DEFAULT_GOAL := default
SHELL := /bin/bash
SUDO := $(shell test $${EUID} -ne 0 && echo "sudo")
.EXPORT_ALL_VARIABLES:
SYSCFG = /etc/mavlink-router
CONFIG ?= /var/local
LIBSYSTEMD=/lib/systemd/system
SERVICES=mavlink-router.service temperature.service
DRY_RUN=false
LOCAL=/usr/local
LOCAL_SCRIPTS=temperature.sh cockpitScript.sh

.PHONY = enable install see uninstall static default no-static

default: 
	@$(MAKE) --no-print-directory install 
	@$(MAKE) --no-print-directory static	

no-static:
	@$(MAKE) --no-print-directory install

disable:
	@( for c in stop disable ; do $(SUDO) systemctl $${c} $(SERVICES) ; done ; true )

enable:
	@( for c in stop disable ; do $(SUDO) systemctl $${c} $(SERVICES) ; done ; true )
	@( for s in $(SERVICES) ; do $(SUDO) install -Dm644 $${s%.*}.service $(LIBSYSTEMD)/$${s%.*}.service ; done ; true )
	@if [ ! -z "$(SERVICES)" ] ; then $(SUDO) systemctl daemon-reload ; fi
	@( for s in $(SERVICES) ; do $(SUDO) systemctl enable $${s%.*} ; done ; true )
	@echo ""
	@echo "Service is installed. To run now use sudo systemctl start mavlink-router and sudo systemctl start cockpit.socket"
	@echo "Inspect output with sudo journalctl -fu mavlink-router"
	@echo ""

static:
# set up static ip address on eth0
	@$(SUDO) ./static-network.sh -i eth0 -a auto

install: 	
# install helper apps
	# @$(SUDO) rm -r /var/lib/apt/lists/*
	@$(SUDO) apt update
	@$(SUDO) apt install -y nano
	@$(SUDO) apt install -y nload
	@$(SUDO) apt install -y htop
	@$(SUDO) apt install -y picocom

# install mavlink-router
	@rm -rf ~/tmp/mavlink-router-source
	@git clone https://github.com/EchoMAV/mavlink-router-src ~/tmp/mavlink-router-source && cd ~/tmp/mavlink-router-source && git submodule update --init --recursive
	@$(SUDO) apt -y install git ninja-build pkg-config gcc g++ systemd
	@$(SUDO) apt -y install python3-pip
	@$(SUDO) pip3 install meson smbus
	@cd ~/tmp/mavlink-router-source && meson setup build . && $(SUDO) ninja -C build install

# install the config file
	@$(SUDO) mkdir -p $(SYSCFG)
	@$(SUDO) cp main.conf $(SYSCFG)/.

# install cockpit
	@$(SUDO) ./ensure-cockpit.sh

# set up cockpit files

	@$(SUDO) rm -rf /usr/share/cockpit/general/ 
	@$(SUDO) mkdir /usr/share/cockpit/general/
	@$(SUDO) cp -rf ui/general/* /usr/share/cockpit/general/
	@$(SUDO) cp -rf ui/branding-ubuntu/* /usr/share/cockpit/branding/ubuntu/
	@$(SUDO) cp -rf ui/static/* /usr/share/cockpit/static/	
	@$(SUDO) cp -rf ui/base1/* /usr/share/cockpit/base1/
	@[ -d $(LOCAL)/echopilot ] || $(SUDO) mkdir $(LOCAL)/echopilot
	@$(SUDO) install -Dm755 version.txt $(LOCAL)/echopilot/.	
	@for s in $(LOCAL_SCRIPTS) ; do $(SUDO) install -Dm755 $${s} $(LOCAL)/echopilot/$${s} ; done

# stop any running services we care about
	@for c in stop disable ; do $(SUDO) systemctl $${c} $(SERVICES) ; done ; true

# install and enable services
	@for s in $(SERVICES) ; do $(SUDO) install -Dm644 $${s%.*}.service $(LIBSYSTEMD)/$${s%.*}.service ; done
	@if [ ! -z "$(SERVICES)" ] ; then $(SUDO) systemctl daemon-reload ; fi
	@for s in $(SERVICES) ; do $(SUDO) systemctl enable $${s%.*} ; done
	

# set up the system permissions, stop/disable nvgetty etc
	@$(SUDO) systemctl stop nvgetty
	@$(SUDO) systemctl disable nvgetty
	@$(SUDO) usermod -aG dialout $${USER}
	@$(SUDO) usermod -aG tty $${USER}
	@echo ""

see:
	$(SUDO) cat $(SYSCFG)/main.conf

serial:
	-@$(SUDO) python3 serial_number.py 0 || true
	-@$(SUDO) python3 serial_number.py 1 || true

uninstall:
	@$(MAKE) --no-print-directory disable
	@( for s in $(SERVICES) ; do $(SUDO) rm $(LIBSYSTEMD)/$${s%.*}.service ; done ; true )
	@if [ ! -z "$(SERVICES)" ] ; then $(SUDO) systemctl daemon-reload ; fi


