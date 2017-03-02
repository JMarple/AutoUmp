UMass Senior Design Project 2017

Linux Drivers tips for xmos xtag:

in /etc/udev/rules.d
add 99-xmos.rules

SUBSYSTEM!="usb|usb_device", GOTO="xmos_rules_end"
ACTION!="add", GOTO="xmos_rules_end"

# 20b1:f7d1 for xmos xtag2
#ATTRS{idVendor}=="20b1", ATTRS{idProduct}=="f7d3", MODE="0666", SYMLINK+="xtag2-%n"
ATTRS{idVendor}=="20b1", ATTRS{idProduct}=="f7d4", MODE="0666", SYMLINK+="xtag3-%n"

# 0403:6010 for XC-1 with FTDI dual-uart chip
ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6010", MODE="0666", SYMLINK+="xc1-%n"

LABEL="xmos_rules_end"


