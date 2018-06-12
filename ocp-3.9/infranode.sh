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
#sed -i -e 's/sslverify=1/sslverify=0/' /etc/yum.repos.d/rhui-load-balancers

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

# Install a NFS server on infranode
yum -y install nfs-utils rpcbind
systemctl enable nfs-server
systemctl enable rpcbind
systemctl start rpcbind
systemctl start nfs-server

systemctl stop firewalld
systemctl disable firewalld

# Create exports directory for hosting Persistent Volumes
mkdir /exports
cd /exports

# Create a bunch of directories for later PV
mkdir registry
mkdir metrics
mkdir logging-es
chown -R nfsnobody:nfsnobody registry/
chown -R nfsnobody:nfsnobody metrics/
chown -R nfsnobody:nfsnobody logging-es/
chmod -R 777 registry/
chmod -R 777 metrics/
chmod -R 777 logging-es/

n=1
while [ $n -le 9 ]
  do mkdir pv000$n
  chown -R nfsnobody:nfsnobody pv000$n/
  chmod -R 777 pv000$n
  (( n++ ))
done

n=10
while [ $n -le 30 ]
  do mkdir pv00$n
  chown -R nfsnobody:nfsnobody pv00$n/
  chmod -R 777 pv00$n
  (( n++ ))
done

cat <<EOF > /etc/exports.d/openshif-ansible.exports
/exports/registry *(rw,root_squash)
/exports/metrics *(rw,root_squash)
/exports/logging-es *(rw,root_squash)
/exports/pv0001 *(rw,root_squash)
/exports/pv0002 *(rw,root_squash)
/exports/pv0003 *(rw,root_squash)
/exports/pv0004 *(rw,root_squash)
/exports/pv0005 *(rw,root_squash)
/exports/pv0006 *(rw,root_squash)
/exports/pv0007 *(rw,root_squash)
/exports/pv0008 *(rw,root_squash)
/exports/pv0009 *(rw,root_squash)
/exports/pv0010 *(rw,root_squash)
/exports/pv0011 *(rw,root_squash)
/exports/pv0012 *(rw,root_squash)
/exports/pv0013 *(rw,root_squash)
/exports/pv0014 *(rw,root_squash)
/exports/pv0015 *(rw,root_squash)
/exports/pv0016 *(rw,root_squash)
/exports/pv0017 *(rw,root_squash)
/exports/pv0018 *(rw,root_squash)
/exports/pv0019 *(rw,root_squash)
/exports/pv0020 *(rw,root_squash)
/exports/pv0021 *(rw,root_squash)
/exports/pv0022 *(rw,root_squash)
/exports/pv0023 *(rw,root_squash)
/exports/pv0024 *(rw,root_squash)
/exports/pv0025 *(rw,root_squash)
/exports/pv0026 *(rw,root_squash)
/exports/pv0027 *(rw,root_squash)
/exports/pv0028 *(rw,root_squash)
/exports/pv0029 *(rw,root_squash)
/exports/pv0030 *(rw,root_squash)
EOF

# Exports everything and force refresh of iptables
exportfs -r
iptables -F
