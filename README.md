# EchoMAV EchoPilot AI Deploy

This is the deployment package, which will install mavlink-router, cockpit and set the device up with a static ip address.

1. After a freshly flashed image, gain console access via USB, e.g. `picocom /dev/ttyUSB0 -b 115200`
2. Ensure that one of the network ports is plugged into a router providing a DHCP address
3. Clone and use `make` to install the software
usage:  
```
git clone https://github.com/echomav/echopilot_deploy.git /tmp/echopilot_deploy
cd /tmp/echopilot_deploy
make
```
