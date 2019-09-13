#!/bin/bash

echo "#################################"
echo "  Running Extra_Server_Config.sh"
echo "#################################"

# cosmetic fix for dpkg-reconfigure: unable to re-open stdin: No file or directory during vagrant up
export DEBIAN_FRONTEND=noninteractive

useradd cumulus -m -s /bin/bash
echo "cumulus:CumulusLinux!" | chpasswd
echo "cumulus ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/10_cumulus
sed "s/PasswordAuthentication no/PasswordAuthentication yes/" -i /etc/ssh/sshd_config

## Convenience code. This is normally done in ZTP.
echo "cumulus ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/10_cumulus
mkdir /home/cumulus/.ssh
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCzH+R+UhjVicUtI0daNUcedYhfvgT1dbZXgY33Ibm4MOo+X84Iwuzirm3QFnYf2O3uyZjNyrA6fj9qFE7Ekul4bD6PCstQupXPwfPMjns2M7tkHsKnLYjNxWNql/rCUxoH2B6nPyztcRCass3lIc2clfXkCY9Jtf7kgC2e/dmchywPV5PrFqtlHgZUnyoPyWBH7OjPLVxYwtCJn96sFkrjaG9QDOeoeiNvcGlk4DJp/g9L4f2AaEq69x8+gBTFUqAFsD8ecO941cM8sa1167rsRPx7SK3270Ji5EUF3lZsgpaiIgMhtIB/7QNTkN9ZjQBazxxlNVN6WthF8okb7OSt" >> /home/cumulus/.ssh/authorized_keys
chmod 700 -R /home/cumulus
chown -R cumulus:cumulus /home/cumulus
chmod 600 /home/cumulus/.ssh/*
chmod 700 /home/cumulus/.ssh

echo "Add bonding module"
echo "bonding" >> /etc/modules

#echo "Add Cumulus Apps Pubkey"
#wget -q -O- https://apps3.cumulusnetworks.com/setup/cumulus-apps-deb.pubkey | apt-key add - 2>&1

#echo "Adding Cumulus Apps Repo"
#echo "deb http://apps3.cumulusnetworks.com/repos/deb bionic netq-2.2" > /etc/apt/sources.list.d/netq.list

#Install LLDP & NTP
echo "Installing LLDP NTP & Python"
apt-get update -qy && apt-get install lldpd ntp ntpdate python ifenslave -qy
#apt-get install cumulus-netq -qy
echo "configure lldp portidsubtype ifname" > /etc/lldpd.d/port_info.conf

echo "Enabling LLDP"
/lib/systemd/systemd-sysv-install enable lldpd
systemctl start lldpd.service

echo "Manual NetQ Agent install from debs"
dpkg -i /home/vagrant/netq-agent_ubuntu.deb
dpkg -i /home/vagrant/netq-apps_ubuntu.deb

echo "Configuring NetQ agent"
netq config add agent server 192.168.0.254
netq config restart agent

echo "Configure etc/network/interfaces"
echo -e "auto lo" > /etc/network/interfaces
echo -e "iface lo inet loopback\n\n" >> /etc/network/interfaces
echo -e  "source /etc/network/interfaces.d/*.cfg\n" >> /etc/network/interfaces

#Add vagrant interface
echo -e "\n\nauto vagrant" > /etc/network/interfaces.d/vagrant.cfg
echo -e "iface vagrant inet dhcp\n\n" >> /etc/network/interfaces.d/vagrant.cfg

echo -e "\n\nauto eth0" > /etc/network/interfaces.d/eth0.cfg
echo -e "iface eth0 inet dhcp\n\n" >> /etc/network/interfaces.d/eth0.cfg

echo "retry 1;" >> /etc/dhcp/dhclient.conf
echo "timeout 600;" >> /etc/dhcp/dhclient.conf

echo "Configure NTP"
timedatectl set-ntp false
# Write NTP Configuration
cat << EOT > /etc/ntp.conf
# /etc/ntp.conf, configuration for ntpd; see ntp.conf(5) for help
driftfile /var/lib/ntp/ntp.drift
statistics loopstats peerstats clockstats
filegen loopstats file loopstats type day enable
filegen peerstats file peerstats type day enable
filegen clockstats file clockstats type day enable
server 192.168.200.1 iburst
# By default, exchange time with everybody, but don't allow configuration.
restrict -4 default kod notrap nomodify nopeer noquery
restrict -6 default kod notrap nomodify nopeer noquery
# Local users may interrogate the ntp server more closely.
restrict 127.0.0.1
restrict ::1
# Specify interfaces, don't listen on switch ports
interface listen eth0
EOT

echo "Enable and start NTP"
/lib/systemd/systemd-sysv-install enable ntp
systemctl start ntp.service

echo "Virtual network adapter speed/duplex hackery"
ethtool -s eth1 speed 100 duplex full autoneg off
ethtool -s eth2 speed 100 duplex full autoneg off
echo "#!/bin/bash" >/etc/rc.local
echo "/sbin/ethtool -s eth1 speed 100 duplex full autoneg off" >>/etc/rc.local
echo "/sbin/ethtool -s eth2 speed 100 duplex full autoneg off" >>/etc/rc.local
echo "sudo systemctl restart networking" >>/etc/rc.local
echo "exit 0" >>/etc/rc.local

#add cronjob to ping and send traffic for bridge learning
echo "* * * * * root /bin/ping -q -c 4 10.0.0.253" >>/etc/crontab

echo "#################################"
echo "   Finished"
echo "#################################"
