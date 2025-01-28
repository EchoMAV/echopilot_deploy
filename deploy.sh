#!/bin/bash

# deploy bash script for installation of echomav_deploy on EchoPilot AI hardware
# This is installation of mavlink-router, cockpit and network setup
if [ ! -z "$2" ]; then
  apn="$2"
else
  apn=teal
fi
# export all variables
set -a
SYSCFG=/etc/mavlink-router
CONFIG=/var/local
LIBSYSTEMD=/lib/systemd/system
SERVICES=(mavlink-router.service temperature.service)
DRY_RUN=false
LOCAL=/usr/local
LOCAL_SCRIPTS=(temperature.sh cockpitScript.sh)
set +a

# exit on any error
set -e

# get script directory
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
cd "$SCRIPT_DIR"

error() {
  echo -e "\e[91m$1\e[0m" 1>&2
  exit 1
}

warning() {
  echo -e "\e[93m\e[5m◢◣\e[25m WARNING: $1\e[0m" 1>&2
}

status() {
  #detect if a flag was passed, and if so, pass it on to the echo command
  if [[ "$1" == '-'* ]] && [ ! -z "$2" ]; then
    echo -e $1 "\e[96m$2\e[0m" 1>&2
  else
    echo -e "\e[96m$1\e[0m" 1>&2
  fi
}

sudo() {
  # systemctl cannot be used natively in a chroot since systemd is not running
  # one alternative is to pass the --root=/ argument so that enable/disable/is-enabled (and related commands) can be used to directly operate on the filesystem (which is not used)
  # another is to use the debian systemd helper designed for running in debian package post/pre install/remove scripts which can be used to directly operate on the filesystem (which is used below)
  if [ "$1" == systemctl ]; then
    if ischroot; then
      shift
      # if command is systemctl enable, always enable the script even if it was previously disabled by deb-systemd-helper
      if [ "$1" == enable ]; then
        command sudo rm -f /var/lib/systemd/deb-systemd-helper-enabled/"$2".dsh-also
      fi
      command sudo DPKG_MAINTSCRIPT_PACKAGE=echopilot-deploy deb-systemd-helper "$@"
    else
      command sudo "$@"
    fi
  else
    command sudo "$@"
  fi
}

export -f sudo


status_green() {
  echo -e "\e[92m$1\e[0m" 1>&2
}

default() {
  install
  static
}

explicit-ip() {
  install
  sudo ./static-network.sh -i eth0 -a $(ip)
}

no-static() {
  install
}

cellular() {
  rm -rf /tmp/cellular_drivers && cd /tmp/ && echo "Downloading Cellular Driver Source Code..." && git clone https://github.com/EchoMAV/cellular_drivers
  # run script which builds and installs the Sierra Wireless drivers
  cd /tmp/cellular_drivers/scripts && sudo ./install-sw_driver.sh
  # run script which sets up nmcli "Cellular" connection with given apn (defaults to teal if not supplied)
  echo "Configuring Cellular Network Interface..." && cd /tmp/cellular_drivers/scripts && sudo ./ensure-cellular.sh --apn "$apn"
}

disable() {
  for c in stop disable; do sudo systemctl ${c} ${SERVICES[@]}; done
}

enable() {
  for s in ${SERVICES[@]}; do
    sudo systemctl stop ${s} || true
    sudo systemctl disable ${s} || true
  done
  for s in ${SERVICES[@]}; do
    sudo install -Dm644 ${s%.*}.service $LIBSYSTEMD/${s%.*}.service
  done
  sudo systemctl daemon-reload
  for s in ${SERVICES[@]}; do sudo systemctl enable ${s}; done
  status "Service is installed. To run now use sudo systemctl start mavlink-router and sudo systemctl start cockpit.socket"
  status "Inspect output with sudo journalctl -fu mavlink-router"
}

static() {
  # set up static ip address on eth0
  sudo ./static-network.sh -i eth0 -a auto
}

install() {
  # install helper apps
  sudo apt update
  sudo apt install -y nano nload htop picocom

  # install mavlink-router
  rm -rf /tmp/mavlink-router-source
  git clone https://github.com/EchoMAV/mavlink-router-src /tmp/mavlink-router-source
  cd /tmp/mavlink-router-source
  git submodule update --init --recursive
  sudo apt -y install git ninja-build pkg-config gcc g++ systemd
  sudo apt -y install python3-pip
  sudo pip3 install meson smbus
  meson setup build .
  sudo ninja -C build install

  # install the config file
  cd "$SCRIPT_DIR"
  sudo mkdir -p $SYSCFG
  sudo cp main.conf $SYSCFG/.

  # install cockpit
  sudo ./ensure-cockpit.sh

  # set up cockpit files
  sudo rm -rf /usr/share/cockpit/general/
  sudo mkdir /usr/share/cockpit/general/
  sudo cp -rf ui/general/* /usr/share/cockpit/general/
  sudo cp -rf ui/branding-ubuntu/* /usr/share/cockpit/branding/ubuntu/
  sudo cp -rf ui/static/* /usr/share/cockpit/static/
  sudo cp -rf ui/base1/* /usr/share/cockpit/base1/
  [ -d $LOCAL/echopilot ] || sudo mkdir $LOCAL/echopilot
  sudo install -Dm755 version.txt $LOCAL/echopilot/.
  for s in $LOCAL_SCRIPTS; do sudo install -Dm755 ${s} $LOCAL/echopilot/${s}; done

  # stop any running services we care about
  for s in ${SERVICES[@]}; do
    sudo systemctl stop ${s} || true
    sudo systemctl disable ${s} || true
  done

  # install and enable services
  for s in ${SERVICES[@]}; do sudo install -Dm644 ${s%.*}.service $LIBSYSTEMD/${s%.*}.service; done
  sudo systemctl daemon-reload
  for s in ${SERVICES[@]}; do
    sudo systemctl enable ${s}
  done

  # set up the system permissions, stop/disable nvgetty etc
  sudo systemctl stop nvgetty || true
  sudo systemctl disable nvgetty || true
  sudo usermod -aG dialout ${USER}
  sudo usermod -aG tty ${USER}
}

see() {
  sudo cat $SYSCFG/main.conf
}

serial() {
  sudo python3 serial_number.py 0 || true
  sudo python3 serial_number.py 1 || true
}

uninstall() {
  disable
  for s in ${SERVICES[@]}; do sudo rm $LIBSYSTEMD/${s%.*}.service; done
  if [ ! -z "${SERVICES[@]}" ]; then sudo systemctl daemon-reload; fi
}

case $1 in
enable | disable | install | see | uninstall | static | default | no-static | cellular)
  $1
  ;;
"")
  default
  ;;
*)
  error "Deploy option not available, please use no argument, no-static, or cellular"
  ;;
esac
