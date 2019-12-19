#!/bin/bash

echo "################################################"
echo "  Running Management Server Setup (config_oob_server.sh)..."
echo "################################################"
echo -e "\n This script was originally written for CumulusCommunity/vx_oob_server"
echo -e "it has been modified to deploy NetQ 2.X Cloud OPTA in place of the oob-mgmt-server"
echo " Detected vagrant user is: $username"
sudo su

#fix the red 'dpkg-reconfigure: unable to re-open stdin: No file or directory' from apt-get stuff
export DEBIAN_FRONTEND=noninteractive

echo " ### Overwriting /etc/network/interfaces ###"
cat <<EOT > /etc/network/interfaces
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
    alias Connects (via NAT) To the Internet

auto eth1
iface eth1 inet static
    alias Faces the Internal Management Network
    address 192.168.0.254/24

EOT

ifup eth1

apt-add-repository -y ppa:ansible/ansible

apt-get update

echo " ### Install Git ###"
apt-get install -yq git

echo " ### Install pip ###"
apt-get install -yq python-pip

#echo " ### janky cloud-opta fixes"
#pip install --upgrade six
#pip install --upgrade PyYAML

echo " ### Install Ansible ###"
apt-get install -yq ansible

echo " ### Install Apache ###"
apt-get install -yq apache2

echo " ### Install DHCP Server ###"
apt-get install -yq isc-dhcp-server

#echo " ### Install dnsmasq ###"
#apt-get install -yq dnsmasq

#using chrony for time sync with NetQ 2.4 on Ubuntu 18.04
mkdir /etc/chrony
echo " ### Write /etc/chrony/chrony.conf ###"
cat << EOT > /etc/chrony/chrony.conf
# Welcome to the chrony configuration file. See chrony.conf(5) for more
# information about usuable directives.

# This will use (up to):
# - 4 sources from ntp.ubuntu.com which some are ipv6 enabled
# - 2 sources from 2.ubuntu.pool.ntp.org which is ipv6 enabled as well
# - 1 source from [01].ubuntu.pool.ntp.org each (ipv4 only atm)
# This means by default, up to 6 dual-stack and up to 2 additional IPv4-only
# sources will be used.
# At the same time it retains some protection against one of the entries being
# down (compare to just using one of the lines). See (LP: #1754358) for the
# discussion.
#
# About using servers from the NTP Pool Project in general see (LP: #104525).
# Approved by Ubuntu Technical Board on 2011-02-08.
# See http://www.pool.ntp.org/join.html for more information.
pool ntp.ubuntu.com        iburst maxsources 4
pool 0.ubuntu.pool.ntp.org iburst maxsources 1
pool 1.ubuntu.pool.ntp.org iburst maxsources 1
pool 2.ubuntu.pool.ntp.org iburst maxsources 2

# This directive specify the location of the file containing ID/key pairs for
# NTP authentication.
keyfile /etc/chrony/chrony.keys

# This directive specify the file into which chronyd will store the rate
# information.
driftfile /var/lib/chrony/chrony.drift

# Uncomment the following line to turn logging on.
#log tracking measurements statistics

# Log files location.
logdir /var/log/chrony

# Stop bad estimates upsetting machine clock.
maxupdateskew 100.0

# This directive enables kernel synchronisation (every 11 minutes) of the
# real-time clock. Note that it can’t be used along with the 'rtcfile' directive.
rtcsync

# Step the system clock instead of slewing it if the adjustment is larger than
# one second, but only in the first three clock updates.
makestep 1 3

# Allow NTP client access from local network.
allow 192.168.0.0/16
EOT

#mkdir /etc/ansible
echo " ### Pushing Ansible Configuration ###"
cat << EOT > /etc/ansible/ansible.cfg
[defaults]
library = /usr/share/ansible
host_key_checking=False
callback_whitelist = profile_tasks
retry_files_enabled = False
pipelining = True
forks = 6

[ssh_connection]
ssh_args = -C -o ControlMaster=no -o ControlPersist=60s
pipelining=True
EOT

echo " ### Pushing Ansible Hosts File ###"
cat << EOT > /etc/ansible/hosts
[oob-switch]
oob-mgmt-switch ansible_host=192.168.0.1 ansible_user=cumulus

[exit]
exit02 ansible_host=192.168.0.42 ansible_user=cumulus
exit01 ansible_host=192.168.0.41 ansible_user=cumulus

[leaf]
leaf04 ansible_host=192.168.0.14 ansible_user=cumulus
leaf02 ansible_host=192.168.0.12 ansible_user=cumulus
leaf03 ansible_host=192.168.0.13 ansible_user=cumulus
leaf01 ansible_host=192.168.0.11 ansible_user=cumulus

[spine]
spine02 ansible_host=192.168.0.22 ansible_user=cumulus
spine01 ansible_host=192.168.0.21 ansible_user=cumulus

[host]
edge01 ansible_host=192.168.0.51 ansible_user=cumulus
server01 ansible_host=192.168.0.31 ansible_user=cumulus
server03 ansible_host=192.168.0.33 ansible_user=cumulus
server02 ansible_host=192.168.0.32 ansible_user=cumulus
server04 ansible_host=192.168.0.34 ansible_user=cumulus
EOT

echo " ### Pushing DHCP File ###"
cat << EOT > /etc/dhcp/dhcpd.conf
ddns-update-style none;

authoritative;

log-facility local7;

option www-server code 72 = ip-address;
option cumulus-provision-url code 239 = text;

# Create an option namespace called ONIE
# See: https://github.com/opencomputeproject/onie/wiki/Quick-Start-Guide#advanced-dhcp-2-vivsoonie/onie/
option space onie code width 1 length width 1;
# Define the code names and data types within the ONIE namespace
option onie.installer_url code 1 = text;
option onie.updater_url   code 2 = text;
option onie.machine       code 3 = text;
option onie.arch          code 4 = text;
option onie.machine_rev   code 5 = text;
# Package the ONIE namespace into option 125
option space vivso code width 4 length width 1;
option vivso.onie code 42623 = encapsulate onie;
option vivso.iana code 0 = string;
option op125 code 125 = encapsulate vivso;
class "onie-vendor-classes" {
  # Limit the matching to a request we know originated from ONIE
  match if substring(option vendor-class-identifier, 0, 11) = "onie_vendor";
  # Required to use VIVSO
  option vivso.iana 01:01:01;

  ### Example how to match a specific machine type ###
  #if option onie.machine = "" {
  #  option onie.installer_url = "";
  #  option onie.updater_url = "";
  #}
}

# OOB Management subnet
shared-network LOCAL-NET{

subnet 192.168.0.0 netmask 255.255.255.0 {
  range 192.168.0.201 192.168.0.250;
  option domain-name-servers 4.2.2.2;
  option domain-name "simulation";
  default-lease-time 172800;  #2 days
  max-lease-time 345600;      #4 days
  option www-server 192.168.0.254;
  option default-url = "http://192.168.0.254/onie-installer";
  option cumulus-provision-url "http://192.168.0.254/ztp_oob.sh";
  option ntp-servers 192.168.0.254;
}

}

#include "/etc/dhcp/dhcpd.pools";
include "/etc/dhcp/dhcpd.hosts";
EOT

echo " ### Push DHCP Host Config ###"
cat << EOT > /etc/dhcp/dhcpd.hosts
group {

  option domain-name-servers 4.2.2.2;
  option domain-name "simulation";
  option routers 192.168.0.254;
  option www-server 192.168.0.254;
  option default-url = "http://192.168.0.254/onie-installer";

 host oob-mgmt-switch {hardware ethernet a0:00:00:00:00:61; fixed-address 192.168.0.1; option host-name "oob-mgmt-switch"; option cumulus-provision-url "http://192.168.0.254/ztp_oob.sh";  } 

 host exit02 {hardware ethernet a0:00:00:00:00:42; fixed-address 192.168.0.42; option host-name "exit02"; option cumulus-provision-url "http://192.168.0.254/ztp_oob.sh";  } 

 host exit01 {hardware ethernet a0:00:00:00:00:41; fixed-address 192.168.0.41; option host-name "exit01"; option cumulus-provision-url "http://192.168.0.254/ztp_oob.sh";  } 

 host spine02 {hardware ethernet a0:00:00:00:00:22; fixed-address 192.168.0.22; option host-name "spine02"; option cumulus-provision-url "http://192.168.0.254/ztp_oob.sh";  } 

 host spine01 {hardware ethernet a0:00:00:00:00:21; fixed-address 192.168.0.21; option host-name "spine01"; option cumulus-provision-url "http://192.168.0.254/ztp_oob.sh";  } 

 host leaf04 {hardware ethernet a0:00:00:00:00:14; fixed-address 192.168.0.14; option host-name "leaf04"; option cumulus-provision-url "http://192.168.0.254/ztp_oob.sh";  } 

 host leaf02 {hardware ethernet a0:00:00:00:00:12; fixed-address 192.168.0.12; option host-name "leaf02"; option cumulus-provision-url "http://192.168.0.254/ztp_oob.sh";  } 

 host leaf03 {hardware ethernet a0:00:00:00:00:13; fixed-address 192.168.0.13; option host-name "leaf03"; option cumulus-provision-url "http://192.168.0.254/ztp_oob.sh";  } 

 host leaf01 {hardware ethernet a0:00:00:00:00:11; fixed-address 192.168.0.11; option host-name "leaf01"; option cumulus-provision-url "http://192.168.0.254/ztp_oob.sh";  } 

 host edge01 {hardware ethernet a0:00:00:00:00:51; fixed-address 192.168.0.51; option host-name "edge01"; } 

 host server01 {hardware ethernet a0:00:00:00:00:31; fixed-address 192.168.0.31; option host-name "server01"; } 

 host server03 {hardware ethernet a0:00:00:00:00:33; fixed-address 192.168.0.33; option host-name "server03"; } 

 host server02 {hardware ethernet a0:00:00:00:00:32; fixed-address 192.168.0.32; option host-name "server02"; } 

 host server04 {hardware ethernet a0:00:00:00:00:34; fixed-address 192.168.0.34; option host-name "server04"; } 

 host internet {hardware ethernet a0:00:00:00:00:50; fixed-address 192.168.0.253; option host-name "internet"; option cumulus-provision-url "http://192.168.0.254/ztp_oob.sh";  } 

}#End of static host group
EOT

chmod 755 -R /etc/dhcp/*
systemctl enable isc-dhcp-server > /dev/null 2>&1
systemctl restart isc-dhcp-server

echo " ### Push Hosts File ###"
cat << EOT > /etc/hosts
127.0.0.1 localhost 
127.0.1.1 oob-mgmt-server
192.168.0.254 oob-mgmt-server 

192.168.0.1 oob-mgmt-switch
192.168.0.42 exit02
192.168.0.41 exit01
192.168.0.22 spine02
192.168.0.21 spine01
192.168.0.14 leaf04
192.168.0.12 leaf02
192.168.0.13 leaf03
192.168.0.11 leaf01
192.168.0.51 edge01
192.168.0.31 server01
192.168.0.33 server03
192.168.0.32 server02
192.168.0.34 server04
192.168.0.253 internet

# The following lines are desirable for IPv6 capable hosts
::1     localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
EOT

echo " ### Creating SSH keys for cumulus user ###"
mkdir -p /home/cumulus/.ssh
#/usr/bin/ssh-keygen -b 2048 -t rsa -f /home/cumulus/.ssh/id_rsa -q -N ""
cat <<EOT > /home/cumulus/.ssh/id_rsa
-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEAsx/kflIY1YnFLSNHWjVHHnWIX74E9XW2V4GN9yG5uDDqPl/O
CMLs4q5t0BZ2H9jt7smYzcqwOn4/ahROxJLpeGw+jwrLULqVz8HzzI57NjO7ZB7C
py2IzcVjapf6wlMaB9gepz8s7XEQmrLN5SHNnJX15AmPSbX+5IAtnv3ZnIcsD1eT
6xarZR4GVJ8qD8lgR+zozy1cWMLQiZ/erBZK42hvUAznqHojb3BpZOAyaf4PS+H9
gGhKuvcfPoAUxVKgBbA/HnDveNXDPLGtdeu67ET8e0it9u9CYuRFBd5WbIKWoiID
IbSAf+0DU5DfWY0AWs8cZTVTelrYRfKJG+zkrQIDAQABAoIBAAqDBp+7JaXybdXW
SiurEL9i2lv0BMp62/aKrdAg9Iswo66BZM/y0IAFCIC7sLbxvhTTU9pP2MO2APay
tmSm0ni0sX8nfQMB0CTfFvWcLvLhWk/n1jiFXY/l042/2YFp6w8mybW66WINzpGl
iJu3vh9AVavKO9Rxj8HNG+BGuWyMEQ7TB4JLIGOglfapHlSFzjBxlMTcVA4mWyDd
bztzh+Hn/J7Mmqw+FqmFXha+IWbojiMGTm1wS/78Iy7YgWpUYTP5CXGewC9fGnoK
H3WvZDD7puTWa8Qhd5p73NSEe/yUd5Z0qmloij7lUVX9kFNVZGS19BvbjAdj7ZL6
OCVLOkECgYEA3I7wDN0pmbuEojnvG3k09KGX4bkJRc/zblbWzC83rFzPWTn7uryL
n28JZMk1/DCEGWtroOQL68P2zSGdF6Yp3PAqsSKHks9fVJsJ0F3ZlXkZHtRFfNI7
i0dl5SsSWlnDPiSnC4bshM25vYb4qd3vij7vvHzb3rA3255u69aU0DkCgYEAz+iA
qoLEja9kTR+sqbP9zvHUWQ/xtKfNCQ5nnjXc7tZ7XUGEf0UTMrAgOKcZXKDq6g5+
hNTkEDPUpPwGhA4iAPbA96RNWh/bwClFQEkBHU3oHPzKcL2Utvo/c6pAb44f2bGD
9kS4B/sumQxvUYM41jfwXDFTNPXN/SBn2XnWUBUCgYBoRug1nMbTWTXvISbsPVUN
J+1QGhTJPfUgwMvTQ6u1wTeDPwfGFOiKW4v8a6krb6C1B/Wd3tPIByGDgJXuHXCD
dcUpdGLWxVaUAK0WJ5j8s4Ft8vxbdGYUhpAlVkTaFMBbfCbCK2tdqopbkhm07ioX
mYPtALdPRM9T9UcKF6zJ+QKBgQCd57lpR55e+foU9VyfG1xGg7dC2XA7RELegPlD
2SbuoynY/zzRqLXXBpvCS29gwbsJf26qFkMM50C2+c89FrrOvpp6u2ggbhfpz66Q
D6JwDk6fTYO3stUzT8dHYuRDlc8s+L0AGtsm/Kg8h4w4fZB6asv8SV4n2BTWDnmx
W+7grQKBgQCm52n2zAOh7b5So1upvuV7REHiAmcNNCHhuXFU75eZz7DQlqazjTzn
CNr0QLZlgxpAg0o6iqwUaduck4655bSrClg4PtnzuDe5e2RuPNSiyZRbUmmiYIYp
i06Z/SJZSH8a1AjEh2I8ayxIEIESpmyhn1Rv1aUT6IjmIQjgbxWxGg==
-----END RSA PRIVATE KEY-----
EOT

cat <<EOT > /home/cumulus/.ssh/id_rsa.pub
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCzH+R+UhjVicUtI0daNUcedYhfvgT1dbZXgY33Ibm4MOo+X84Iwuzirm3QFnYf2O3uyZjNyrA6fj9qFE7Ekul4bD6PCstQupXPwfPMjns2M7tkHsKnLYjNxWNql/rCUxoH2B6nPyztcRCass3lIc2clfXkCY9Jtf7kgC2e/dmchywPV5PrFqtlHgZUnyoPyWBH7OjPLVxYwtCJn96sFkrjaG9QDOeoeiNvcGlk4DJp/g9L4f2AaEq69x8+gBTFUqAFsD8ecO941cM8sa1167rsRPx7SK3270Ji5EUF3lZsgpaiIgMhtIB/7QNTkN9ZjQBazxxlNVN6WthF8okb7OSt
EOT

cat /home/cumulus/.ssh/id_rsa.pub >> /home/cumulus/.ssh/authorized_keys
cp /home/cumulus/.ssh/id_rsa.pub /var/www/html/authorized_keys

chmod 700 -R /home/cumulus/.ssh
chown cumulus:cumulus -R /home/cumulus/.ssh

echo "### Adding to .ssh_config to avoid HostKeyChecking"
printf "Host * \n\t StrictHostKeyChecking no\n" >> /home/cumulus/.ssh/config

echo " ### Pushing Fake License ###"
echo "this is a fake license" > /var/www/html/license.lic
chmod 777 /var/www/html/license.lic

echo " ### Pushing ZTP Script ###"
cat << EOT > /var/www/html/ztp_oob.sh
#!/bin/bash

###################
# Simple ZTP Script
###################

function error() {
  echo -e "\e[0;33mERROR: The Zero Touch Provisioning script failed while running the command \$BASH_COMMAND at line \$BASH_LINENO.\e[0m" >&2
}
trap error ERR

# Setup SSH key authentication for Ansible
mkdir -p /home/cumulus/.ssh
#wget -O /home/cumulus/.ssh/authorized_keys http://192.168.0.254/authorized_keys
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCzH+R+UhjVicUtI0daNUcedYhfvgT1dbZXgY33Ibm4MOo+X84Iwuzirm3QFnYf2O3uyZjNyrA6fj9qFE7Ekul4bD6PCstQupXPwfPMjns2M7tkHsKnLYjNxWNql/rCUxoH2B6nPyztcRCass3lIc2clfXkCY9Jtf7kgC2e/dmchywPV5PrFqtlHgZUnyoPyWBH7OjPLVxYwtCJn96sFkrjaG9QDOeoeiNvcGlk4DJp/g9L4f2AaEq69x8+gBTFUqAFsD8ecO941cM8sa1167rsRPx7SK3270Ji5EUF3lZsgpaiIgMhtIB/7QNTkN9ZjQBazxxlNVN6WthF8okb7OSt" >> /home/cumulus/.ssh/authorized_keys
chmod 700 -R /home/cumulus/.ssh
chown cumulus:cumulus -R /home/cumulus/.ssh


echo "cumulus ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/10_cumulus

# Setup NTP
sed -i '/^server [1-3]/d' /etc/ntp.conf
sed -i 's/^server 0.cumulusnetworks.pool.ntp.org iburst/server 192.168.0.254 iburst/g' /etc/ntp.conf

# Purge NetQ 1.4 
sudo apt -y purge cumulus-netq netq-agent netq-apps python-netq-lib

ping 8.8.8.8 -c2
if [ "\$?" == "0" ]; then
  echo "deb http://apps3.cumulusnetworks.com/repos/deb CumulusLinux-3 netq-2.2" > /etc/apt/sources.list.d/netq.list
  apt-get update -qy
  apt-get install ntpdate -qy
fi

dpkg -i /home/vagrant/netq-agent_cl.deb
dpkg -i /home/vagrant/netq-apps_cl.deb

echo " " >/etc/network/interfaces
echo "auto lo" >>/etc/network/interfaces
echo "iface lo inet loopback" >>/etc/network/interfaces
echo "" >>/etc/network/interfaces
echo "auto eth0" >>/etc/network/interfaces
echo "iface eth0 inet dhcp" >>/etc/network/interfaces
echo "    vrf mgmt" >>/etc/network/interfaces
echo "" >>/etc/network/interfaces
echo "auto mgmt" >>/etc/network/interfaces
echo "iface mgmt" >>/etc/network/interfaces
echo "    address 127.0.0.1/8" >>/etc/network/interfaces
echo "    vrf-table auto" >>/etc/network/interfaces

#write /etc/netq/netq.yml
echo "netq-agent:" >/etc/netq/netq.yml
echo "  port: 31980" >>/etc/netq/netq.yml
echo "  server: 192.168.0.254" >>/etc/netq/netq.yml
echo "  vrf: mgmt" >>/etc/netq/netq.yml

netq config restart agent

systemctl stop ntp.service
systemctl disable ntp.service
systemctl enable ntp@mgmt
systemctl start ntp@mgmt  

nohup bash -c 'sleep 2; shutdown now -r "Rebooting to Complete ZTP"' &
exit 0
#CUMULUS-AUTOPROVISIONING
EOT

echo "Set login as cumulus user"
echo "sudo su - cumulus" >> /home/vagrant/.bash_profile
echo "exit" >> /home/vagrant/.bash_profile

echo " ### Clone Repo ###"
git clone https://github.com/CumulusNetworks/cldemo-evpn-symmetric /home/cumulus/cldemo-evpn-symmetric  > /dev/null 2>&1
chown cumulus:cumulus -R /home/cumulus/cldemo-evpn-symmetric

echo " ### Patch the Repo ###"
# change the bond name to 'bond0' because 'uplink' doesn't really work. It functions, like it arps and I can ping default gw,
# but something is wonky in kernel land and the post-up route to the rest of the topo won't work
sed -i -e 's/uplink/bond0/g' /home/cumulus/cldemo-evpn-symmetric/config/server04/interfaces
sed -i -e 's/uplink/bond0/g' /home/cumulus/cldemo-evpn-symmetric/config/server03/interfaces
sed -i -e 's/uplink/bond0/g' /home/cumulus/cldemo-evpn-symmetric/config/server02/interfaces
sed -i -e 's/uplink/bond0/g' /home/cumulus/cldemo-evpn-symmetric/config/server01/interfaces
#
# I don't want a default route on the bond because then you can't default route out through oob-server
# Also we get default route from DHCP, so another default route fails with netlink error
sed -i -e 's/add\ default/add\ 10\.0\.0\.0\/8/g' /home/cumulus/cldemo-evpn-symmetric/config/server01/interfaces
sed -i -e 's/add\ default/add\ 10\.0\.0\.0\/8/g' /home/cumulus/cldemo-evpn-symmetric/config/server02/interfaces
sed -i -e 's/add\ default/add\ 10\.0\.0\.0\/8/g' /home/cumulus/cldemo-evpn-symmetric/config/server03/interfaces
sed -i -e 's/add\ default/add\ 10\.0\.0\.0\/8/g' /home/cumulus/cldemo-evpn-symmetric/config/server04/interfaces
#
# add advertise-svi-ip
# can't add it to the official repo yet because this only exists in 3.7.4 and cldemo-vagrant is skipping that build
# once cldemo-vagrant runs 3.7.5 put this change there.
#sed -i -e 's/advertise-all-vni/advertise-all-vni\r\n\ \ advertise-svi-ip/' /home/cumulus/cldemo-evpn-symmetric/config/leaf01/frr.conf
#sed -i -e 's/advertise-all-vni/advertise-all-vni\r\n\ \ advertise-svi-ip/' /home/cumulus/cldemo-evpn-symmetric/config/leaf02/frr.conf
#sed -i -e 's/advertise-all-vni/advertise-all-vni\r\n\ \ advertise-svi-ip/' /home/cumulus/cldemo-evpn-symmetric/config/leaf03/frr.conf
#sed -i -e 's/advertise-all-vni/advertise-all-vni\r\n\ \ advertise-svi-ip/' /home/cumulus/cldemo-evpn-symmetric/config/leaf04/frr.conf

echo " ### Start Apache for ZTP ###"
systemctl start apache2

#echo " ### Enable dnsmasq ###"
#systemctl enable dnsmasq.service > /dev/null 2>&1
#systemctl start dnsmasq.service

echo " ### Install PAT rule in iptables for outbound access via oob-mgmt ###"
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE # install rule now
sysctl -w net.ipv4.ip_forward=1
# also put in rc.local so it adds the rule on reboot
echo "!/bin/sh -e" >/etc/rc.local
echo " " >>/etc/rc.local
echo "iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE" >>/etc/rc.local
echo "exit 0" >>/etc/rc.local
# also modify /etc/sysctl.conf to persist ipv4 routing
sed -i 's/^#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf


echo "############################################"
echo "      DONE!"
echo "############################################"
