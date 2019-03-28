#!/bin/bash

echo "#################################"
echo "  Running Switch Post Config (config_switch.sh)"
echo "#################################"
sudo su

echo "deb https://apps3.cumulusnetworks.com/repos/deb CumulusLinux-3 netq-2.0" > /etc/apt/sources.list.d/netq.list
apt-get update
apt-get install -yq cumulus-netq

## Convenience code. This is normally done in ZTP.

# Make DHCP occur without delays
echo "retry 1;" >> /etc/dhcp/dhclient.conf


echo "#################################"
echo "   Finished"
echo "#################################"
