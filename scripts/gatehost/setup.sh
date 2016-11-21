#!/bin/sh
git config --global push.default simple
echo server ntp1.suse.de iburst minpoll 4 >> /etc/ntp.conf 
echo server ntp2.suse.de iburst >> /etc/ntp.conf
chkconfig ntpd on
rcntpd restart
# set secure root password
sed -i -e 's#^root:.*#root:$6$oh/u8h6j$876vgM2dJsuwRtfzlf6JlwYkxlY64jGKL5KFYqR51MLQLaVHlJ.V7ESn9OWlVbcNagSR.P4ON6uSONs60.iYv0:17116::::::#' /etc/shadow

cp -a network/* /etc/sysconfig/network/
rcnetwork restart

# install media is not needed when we have the Pool repo
zypper rr SLES12-SP2-12.2-0
zypper --non-interactive in --no-recommends libvirt qemu-kvm
chkconfig libvirtd on
rclibvirtd restart

pushd /tmp
wget http://clouddata.cloud.suse.de/images/x86_64/SLES12-SP2.qcow2
lvcreate -L 10G -n gatevm gate
qemu-img convert SLES12-SP2.qcow2 /dev/gate/gatevm
lvcreate -L 30G -n jenkins-tu-sle12 gate
popd
#TODO during start dd if=/dev/gate/jenkins-tu-sle12 of=/dev/shm/jenkins-tu-sle12 bs=64k
#TODO make clean image - initial setup of image used ssh -C gate dd if=/dev/system/jenkins-tu-sle12 bs=64k | dd of=/dev/gate/jenkins-tu-sle12 bs=64k

for vm in gatevm jenkins-tu-sle12 ; do
  virsh define $vm.xml
  virsh start $vm
  virsh autostart $vm
done

ssh gatevm mkdir -p ~/.ssh/
scp ~/.ssh/authorized_keys gatevm:.ssh/
scp -r /etc/zypp/repos.d gatevm:/etc/zypp/
ssh gatevm zypper -n in rsync
rsync -a ~/automation gatevm:
ssh gatevm "cd ~/automation/scripts/gatevm && ./setup.sh"

