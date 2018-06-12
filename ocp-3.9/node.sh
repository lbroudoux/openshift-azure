#!/bin/bash
# Last Modified : 2016-05-26

rhn_username=$1
rhn_pass=$2
rhn_pool=$3


subscription-manager register --username=${rhn_username} --password=${rhn_pass} --force
subscription-manager attach --pool=${rhn_pool}

subscription-manager repos --disable="*"
subscription-manager repos --enable="rhel-7-server-rpms" --enable="rhel-7-server-extras-rpms" --enable="rhel-7-server-ose-3.9-rpms" --enable="rhel-7-fast-datapath-rpms" --enable="rhel-7-server-ansible-2.4-rpms"

sed -i -e 's/sslverify=1/sslverify=0/' /etc/yum.repos.d/rh-cloud.repo
sed -i -e 's/sslverify=1/sslverify=0/' /etc/yum.repos.d/rhui-load-balancers

yum -y install wget git net-tools bind-utils yum-utils iptables-services bridge-utils bash-completion kexec-tools sos psacct
yum -y update

yum -y install docker-1.13.1

sed -i '/OPTIONS=.*/c\OPTIONS="--selinux-enabled --insecure-registry 172.30.0.0/16 --log-opt max-size=1M --log-opt max-file=3"' /etc/sysconfig/docker

cat <<EOF > /etc/sysconfig/docker-storage-setup
STORAGE_DRIVER=overlay2
DEVS=/dev/sdc
VG=docker-vg
EOF

docker-storage-setup
systemctl enable docker
systemctl start docker

yum -y install nfs-utils rpcbind
systemctl enable rpcbind
systemctl start rpcbind
setsebool -P virt_sandbox_use_nfs 1
setsebool -P virt_use_nfs 1

systemctl stop firewalld
systemctl disable firewalld
