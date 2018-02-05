#!/bin/bash
set -ex

case `whoami` in

root)
# set up stack user
useradd -m -s /bin/bash stack
echo -e "stack ALL=(ALL) NOPASSWD:ALL\nDefaults:stack !requiretty" > /etc/sudoers.d/0-stack
chmod 0777 $0
su -l stack `pwd`/$0

;;

stack)
host_ip="10.10.0.4"
network_interface=ens224
GIT_BASE="https://github.com"

DEBIAN_FRONTEND=noninteractive sudo apt-get -qqy update || sudo yum update -qy
DEBIAN_FRONTEND=noninteractive sudo apt-get install -qqy git htop || sudo yum install -qy git htop

sudo chown stack:stack /home/stack
cd /home/stack
git clone --branch=stable/newton $GIT_BASE/openstack-dev/devstack.git
cd devstack

# ref https://docs.openstack.org/horizon/newton/ref/local_conf.html
cat > local.conf <<EOF
[[local|localrc]]
ADMIN_PASSWORD=password
DATABASE_PASSWORD=password
RABBIT_PASSWORD=password
SERVICE_PASSWORD=password

VOLUME_BACKING_FILE_SIZE=532480M

CINDER_BRANCH=newton-eol
CINDERCLIENT_BRANCH=newton-eol
GLANCE_BRANCH=newton-eol
GLANCECLIENT_BRANCH=newton-eol
GLANCE_STORE_BRANCH=newton-eol
HORIZON_BRANCH=newton-eol
HORIZONAUTH_BRANCH=newton-eol
KEYSTONE_BRANCH=newton-eol
KEYSTONECLIENT_BRANCH=newton-eol
KEYSTONEAUTH_BRANCH=newton-eol
NEUTRON_BRANCH=newton-eol
NEUTRONCLIENT_BRANCH=newton-eol
NEUTRON_LIB_BRANCH=newton-eol
NOVA_BRANCH=newton-eol
NOVACLIENT_BRANCH=newton-eol
REQUIREMENTS_BRANCH=stable/newton
OPENSTACKCLIENT_BRANCH=newton-eol

## Neutron options
Q_USE_SECGROUP=True
FIXED_RANGE=10.0.0.0/24
FLOATING_RANGE=172.18.161.0/24
PUBLIC_NETWORK_GATEWAY=172.18.161.1
PUBLIC_INTERFACE=$network_interface

# Enable Neutron (Networking)
# to use nova net rather than neutron, comment out the following group
disable_service n-net
enable_service q-svc
enable_service q-agt
enable_service q-dhcp
enable_service q-l3
enable_service q-meta
enable_service q-metering
enable_service q-qos

# Disable unused services
disable_service n-novnc tempest

# Speedups
GIT_BASE="$GIT_BASE"
CINDER_VOLUME_CLEAR=none # don't zero-out volumes on deletion
EOF

cat > post-stack.sh <<EOF
#IP forward rules
source ./openrc admin demo

#Clean-up
openstack project delete invisible_to_admin
openstack project delete alt_demo
openstack user delete alt_demo

#Make demo user an admin
openstack role add --project demo --user demo admin

# required for private network routing
echo Now run:
echo sudo iptables -t nat -A POSTROUTING -o br-ex -j MASQUERADE
EOF

chmod +x post-stack.sh

./stack.sh
./post-stack.sh
;;

esac

