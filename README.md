# Cumulus Linux Demo Framework Fork for NetQ 2.x On-Prem 

![Reference Topology](./documentation/cldemo_topology.png "Reference Topology")

This branch "debian-packages" is meant to be used when we are in EA or testing release candidates for NetQ On-Prem. In pre-release, we do not have the NetQ agent packages available on our public repo able to be installed using apt or apt-get. We are provided debian packages (debs) from engineering that must be installed manually with the dpkg -i command. These packages are preloaded onto the tea servers (chai or roobios) and the provisioning scripts here assume a constant filename that is copied onto the box, then installed in the config_*.sh script

watch-dropbox.sh runs as a cron job every minute. It looks for new files in the engineering dropbox. If it finds new files, it assumes they are the most recent ones, and it copies them into the place where the Vagrant file provisioner will copy them into the machines when you do a 'vagrant up'

At this time, we still have to manually move/copy and 'vagrant box add' for the on-prem images. This branch has Vagrantfile set to look for a box named `cumulus/ts-ea`. Use the .json file attached to add boxes. `vagrant box add netq-onprem-ea-add.json`. Use version numbering by appending 9s so that the "most recent" or "highest version" box is always loaded. The intent is to have a more static repo, where all the consumers need to do is vagrant destroy then vagrant up without chanign the repo to realize updates to the NetQ agents or NetQ server base box.

For example)

For the 2.4.1 NetQ release, add vagrant boxes with versioning as:
1) 2.4.0.9
2) 2.4.0.99
3) 2.4.0.999
etc...

For the 2.5.0 NetQ release, add vagrant boxes with versioning as:
1) 2.4.9
2) 2.4.99
3) 2.4.999
etc...

See more deets here: https://wiki.cumulusnetworks.com/display/PC/Field+Team+Workbenches

Using:
1) cd to the directory from the git clone 
2) `vagrant up oob-mgmt-server oob-mgmt-switch && vagrant up`
3) wait for that to load 
4) `vagrant ssh oob-mgmt-server`
5) Perform master bootstrap: `netq bootstrap master interface eth0 tarball /mnt/installables/netq-bootstrap-2.4.0.tgz`

*Can install NetQ via GUI wizard here see wiki above. CLI steps below:

6) Install NetQ application `netq install standalone full interface eth0 bundle /mnt/installables/NetQ-2.4.0.tgz config-key EhVuZXRxLWVuZHBvaW50LWdhdGV3YXkYsagD`
7) Setup EVPN Symmetric mode for some NetQ data: `cd cldemo-evpn-symmetric`
8) `ansible-playbook run_demo.yml`
