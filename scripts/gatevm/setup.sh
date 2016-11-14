#!/bin/sh
# enable serial console
sed -i -e 's/quiet splash=silent/console=tty console=ttyS0,115200/' /etc/default/grub
sed -i -e 's/\(GRUB_TIMEOUT\)=.*/\1=3/' /etc/default/grub
update-bootloader --refresh

# set secure root password
sed -i -e 's#^root:.*#root:$6$oh/u8h6j$876vgM2dJsuwRtfzlf6JlwYkxlY64jGKL5KFYqR51MLQLaVHlJ.V7ESn9OWlVbcNagSR.P4ON6uSONs60.iYv0:17116::::::#' /etc/shadow

zypper -n in bridge-utils vlan

echo gatevm.cloud.suse.de > /etc/HOSTNAME
#salt '*' sysctl.persist net.ipv4.ip_forward 1
echo "net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1" > /etc/sysctl.conf # to make yast2 lan parser happy https://bugzilla.suse.com/show_bug.cgi?id=1010036
cp -a sysctl.d/* /etc/sysctl.d/
cp -a network/* /etc/sysconfig/network/
rcnetwork restart


