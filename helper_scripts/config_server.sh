#!/bin/bash

echo "#################################"
echo "  Running config_server.sh"
echo "#################################"
sudo su

# to make the red "dpkg-reconfigure: unable to re-open stdin: No file or directory" not happen from apt-get stuff
export DEBIAN_FRONTEND=noninteractive

# Make DHCP Try Over and Over Again
echo "retry 1;" >> /etc/dhcp/dhclient.conf

#Replace existing network interfaces file
echo -e "auto lo" > /etc/network/interfaces
echo -e "iface lo inet loopback\n\n" >> /etc/network/interfaces

#Add vagrant interface
echo -e "\n\nauto eth0" >> /etc/network/interfaces
echo -e "iface eth0 inet dhcp\n\n" >> /etc/network/interfaces

useradd cumulus -m -s /bin/bash
echo "cumulus:CumulusLinux!" | chpasswd
sed "s/PasswordAuthentication no/PasswordAuthentication yes/" -i /etc/ssh/sshd_config

## Convenience code. This is normally done in ZTP.
echo "cumulus ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/10_cumulus
mkdir /home/cumulus/.ssh
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCzH+R+UhjVicUtI0daNUcedYhfvgT1dbZXgY33Ibm4MOo+X84Iwuzirm3QFnYf2O3uyZjNyrA6fj9qFE7Ekul4bD6PCstQupXPwfPMjns2M7tkHsKnLYjNxWNql/rCUxoH2B6nPyztcRCass3lIc2clfXkCY9Jtf7kgC2e/dmchywPV5PrFqtlHgZUnyoPyWBH7OjPLVxYwtCJn96sFkrjaG9QDOeoeiNvcGlk4DJp/g9L4f2AaEq69x8+gBTFUqAFsD8ecO941cM8sa1167rsRPx7SK3270Ji5EUF3lZsgpaiIgMhtIB/7QNTkN9ZjQBazxxlNVN6WthF8okb7OSt" >> /home/cumulus/.ssh/authorized_keys
chmod 700 -R /home/cumulus
chown -R cumulus:cumulus /home/cumulus
chmod 600 /home/cumulus/.ssh/*
chmod 700 /home/cumulus/.ssh


# Other stuff
ping 8.8.8.8 -c2
if [ "$?" == "0" ]; then
  wget https://apps3.cumulusnetworks.com/setup/cumulus-apps-deb.pubkey > /dev/null 2>&1
  apt-key add cumulus-apps-deb.pubkey
  echo "deb [arch=amd64] https://apps3.cumulusnetworks.com/repos/deb xenial netq-2.4" > /etc/apt/sources.list.d/netq.list
  apt-get update -qy
  apt-get install unzip lldpd ntp ntpdate traceroute -qy
  apt-get install cumulus-netq -qy
  echo "configure lldp portidsubtype ifname" > /etc/lldpd.d/port_info.conf 
fi

# Set Timezone
cat << EOT > /etc/timezone
Etc/UTC
EOT

# Apply Timezone Now
# dpkg-reconfigure -f noninteractive tzdata

# Write NTP Configuration
cat << EOT > /etc/ntp.conf
# /etc/ntp.conf, configuration for ntpd; see ntp.conf(5) for help

driftfile /var/lib/ntp/ntp.drift

statistics loopstats peerstats clockstats
filegen loopstats file loopstats type day enable
filegen peerstats file peerstats type day enable
filegen clockstats file clockstats type day enable

server 192.168.0.254 iburst

# By default, exchange time with everybody, but don't allow configuration.
restrict -4 default kod notrap nomodify nopeer noquery
restrict -6 default kod notrap nomodify nopeer noquery

# Local users may interrogate the ntp server more closely.
restrict 127.0.0.1
restrict ::1

# Specify interfaces, don't listen on switch ports
interface listen eth0
EOT

/lib/systemd/systemd-sysv-install enable ntp
systemctl start ntp.service

netq config add agent server 192.168.0.254
netq config add cli server 192.168.0.254
netq config restart agent
netq config restart cli

# Ok this is a dirty hack to get netq 2.0 interface checks to succeed. It causes no functional problems otherwise and please don't do this unless you need a clean netq interface check
# netq detects a autonegotiation mismatch between all server and leaf ports. Ubuntu is autoneg on, CL leafs are autoneg off
# looks like ubuntu needs real speed/duplex from emulated e1000 in libvirt to make bond come up, but i can't disable autoneg
# but CL VX doesn't seem to let you enable autoneg either
# But if you set ubuntu to 100 full autoneg off, then ethtool shows autoneg off and netq is happy
# ethtool still shows speed as 1000mbps when you do this, but who knows what else it breaks.
ethtool -s eth1 speed 100 duplex full autoneg off
ethtool -s eth2 speed 100 duplex full autoneg off
echo "#!/bin/bash" >/etc/rc.local
echo "/sbin/ethtool -s eth1 speed 100 duplex full autoneg off" >>/etc/rc.local
echo "/sbin/ethtool -s eth2 speed 100 duplex full autoneg off" >>/etc/rc.local
echo "sudo systemctl restart networking" >>/etc/rc.local
echo "exit 0" >>/etc/rc.local
chmod 755 /etc/rc.local
#end dirty hack, please find a better way to do this or don't do it at all because it feels janky af and normally causes no problems.

#add cronjob to ping and send traffic for bridge learning
echo "* * * * * root /bin/ping -q -c 4 10.0.0.253" >>/etc/crontab

echo "#################################"
echo "   Finished"
echo "#################################"
