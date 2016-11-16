#!/bin/sh
# enable serial console
sed -i -e 's/quiet splash=silent/console=tty console=ttyS0,115200/' /etc/default/grub
sed -i -e 's/\(GRUB_TIMEOUT\)=.*/\1=3/' /etc/default/grub
update-bootloader --refresh

zypper ar http://smt-scc.nue.suse.com/repo/SUSE/Products/SUSE-Manager-Server/3.0/x86_64/product/ manager30
zypper ar http://smt-scc.nue.suse.com/repo/SUSE/Updates/SUSE-Manager-Server/3.0/x86_64/update/ manager30up
zypper -n in salt-ssh salt-master salt-minion

salt-call network.mod_hostname gatevm.cloud.suse.de
rcsalt-master restart
rcsalt-minion restart
salt-key -A --yes

# set secure root password
#salt '*' shadow.set_password root '$6$oh/u8h6j$876vgM2dJsuwRtfzlf6JlwYkxlY64jGKL5KFYqR51MLQLaVHlJ.V7ESn9OWlVbcNagSR.P4ON6uSONs60.iYv0'
sed -i -e 's#^root:.*#root:$6$oh/u8h6j$876vgM2dJsuwRtfzlf6JlwYkxlY64jGKL5KFYqR51MLQLaVHlJ.V7ESn9OWlVbcNagSR.P4ON6uSONs60.iYv0:17116::::::#' /etc/shadow

#salt '*' pkg.install bridge-utils vlan
zypper -n in bridge-utils vlan

#salt '*' sysctl.persist net.ipv4.ip_forward 1
echo "net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1" > /etc/sysctl.conf # to make yast2 lan parser happy https://bugzilla.suse.com/show_bug.cgi?id=1010036
cp -a sysctl.d/* /etc/sysctl.d/
cp -a network/* /etc/sysconfig/network/
rcnetwork restart


