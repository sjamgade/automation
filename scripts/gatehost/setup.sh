#!/bin/sh
echo 'this assumes you have applied "gatehost" rules from gitlab@gitlab.suse.de:cloud/cloudsalt.git
using salt-ssh gatehost state.highstate'

grep -q salt /etc/motd || { echo "error: salt not applied" ; exit 74; }

git config --global push.default simple
# install media is not needed when we have the Pool repo
zypper rr SLES12-SP2-12.2-0
# drop redundant repos from autoyast
rm /etc/zypp/repos.d/http-*

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

sleep 100 # TODO waitfor ssh
echo "default root password is linux"
ssh gatevm mkdir -p ~/.ssh/
scp ~/.ssh/authorized_keys gatevm:.ssh/
scp -r /etc/zypp/repos.d gatevm:/etc/zypp/
ssh gatevm zypper -n in python-pyOpenSSL python-xml
echo "now use salt-ssh gatevm state.highstate"
