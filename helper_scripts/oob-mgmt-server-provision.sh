#!/bin/sh
sudo sh -c 'echo "deb http://ftp.debian.org/debian jessie main" > /etc/apt/sources.list.d/jessie.list'
sudo sh -c 'echo "deb http://ftp.debian.org/debian jessie-backports main" >> /etc/apt/sources.list.d/jessie.list'
sudo sh -c 'echo "deb http://security.debian.org/ jessie/updates main" >> /etc/apt/sources.list.d/jessie.list'
sudo sh -c 'echo "deb http://repo3.cumulusnetworks.com/repo Jessie-supplemental upstream" > /etc/apt/sources.list.d/jessie_cl.list'
# needed to upgrade to ansible 2.7 for reboot module
# ansible docs says ubuntu trusty tested on jesse: https://docs.ansible.com/ansible/2.7/installation_guide/intro_installation.html
sudo sh -c 'echo "deb http://ppa.launchpad.net/ansible/ansible/ubuntu trusty main" >> /etc/apt/sources.list.d/jessie.list'
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 93C4A3FD7BB9C367
# remove list file that points to build servers so that we don't throw errors in the apt-get update
[ -e /etc/apt/sources.list.d/cumulus-apps.list ] && sudo rm /etc/apt/sources.list.d/cumulus-apps.list
sudo apt-get update
sudo apt-get install -yq git python-netaddr sshpass
sudo apt-get install -yq -t trusty ansible

echo " ### Pushing Ansible Configuration ###"
cat << EOT > /etc/ansible/ansible.cfg
[defaults]
library = /usr/share/ansible
# only use in lab settings. Reference:
# http://docs.ansible.com/intro_getting_started.html#host-key-checking
host_key_checking=False
callback_whitelist = profile_tasks
retry_files_enabled = False
pipelining = True
forks = 6
EOT

echo "sudo su - cumulus" >> /home/vagrant/.bash_profile
echo "exit" >> /home/vagrant/.bash_profile

