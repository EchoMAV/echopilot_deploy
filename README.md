# EchoMAV EchoPilot AI Deploy

This is the stnadard deployment package used on Jetson modules installed on the EchoPilot AI hardware.
A makefile is included which will install mavlink-router, cockpit and set the device up with a static ip address.

- mavlink-router is an open source tool to route mavlink messages across various types of endpoints. On the EchoPilot AI, it is used to accept serial data from the autopilot and act as a client or server using either UDP or TCP for packets.
- cockpit is web-based graphical user interface, allowing you to manage the system. As configured in this install, a MAVLink-Router configuration page allows you to use a simple to use web user interface to configure mavlink-router. Simply access the system using a web browser at http://IP_ADDRESS.
- A shell script is included which will configure a unique static IP address for the system based on the network adapter's MAC address.
- Other helpful applications are installed, including nano, htop and nload.

## Steps to install

1. Given a freshly flashed image, gain console access via USB, e.g. `picocom /dev/ttyUSB0 -b 115200` on Linux.
2. Ensure that one of the EchoPilot AI's network ports is plugged into a router providing a DHCP address and Internet access.
3. Clone and use `make` to install the software
usage:  
```
git clone https://github.com/echomav/echopilot_deploy.git /tmp/echopilot_deploy && cd /tmp/echopilot_deploy && make

# If you do not want to configure a static IP, then use make no-static
```

4. Record and label the device with the static IP address generated by the script, as you will need this to access the device over the network.
5. Using a host computer on the appropriate subnet (e.g., 10.223), access the webUI at http://IP_ADDRESS. https will also work.
6. You may also use ssh for terminal acces, e.g. `ssh echopilot@IP_ADDRESS`

Using the web user interface, you can now configure mavlink-router endpoints. The most common scenario is UDP Client pushing data to the ground control system computer.


