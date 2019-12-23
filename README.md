# Cumulus Linux Demo Framework Fork for NetQ2.x 
![Reference Topology](./documentation/cldemo_topology.png "Reference Topology")

This is an unofficial fork of cldemo-vagrant. A NetQ server is used in place of the CumulusCommunity/vx-oob-server.

Branches:  
* master: Will be a full on prem latest release version on premise NetQ Telemetry Server   
* debian-packages: Same as above, but used for instances when the NetQ agent needs to be manually installed from a package. Usually when we're doing release candidates  
* cloud-opta: Will use a cloud-opta NetQ image instead of a full grown on prem telemetry server. This image uses only 8GB ram and 4 CPU cores. You must have some keys provided by engineering. See the readme of the branch  
* cloud-opta-debian-packages: Same as above, but used for instances when the NetQ agent needs to be manually installed from a package  

See the Readme in each branch for additional information.

Prerequisites:
* Clone `git clone https://github.com/CumulusNetworks/cldemo-vagrant-netq2ea.git`
* Download the NetQ 2.x libvirt.box file
* Use/edit the included `netq-onprem-box-add.json` to add the NetQ telemetry server box with the *CORRECT VERSION*
* Add the box to vagrant: `vagrant box add netq-onprem-box-add.json`

Using:
1) cd to `cldemo-vagrant-netq2ea` folder (or where you cloned to) 
2) `vagrant up oob-mgmt-server oob-mgmt-switch && vagrant up`
3) `vagrant ssh oob-mgmt-server`
4) Bootstrap the server: `netq bootstrap master interface eth0 tarball /mnt/installables/netq-bootstrap-2.4.0.tgz`

*After bootstrap, the NetQ may be installed via GUI/Wizard. see wiki for more details. CLI steps below:*

5) Install the NetQ application: `netq install standalone full interface eth0 bundle /mnt/installables/NetQ-2.4.0.tgz config-key EhVuZXRxLWVuZHBvaW50LWdhdGV3YXkYsagD`
6) Provision the cldemo-evpn-symmetric demo is in the home dir. `cd cldemo-evpn-symmetric`
7) Run the playbook `ansible-playbook run_demo.yml`

Once complete, you are running the cldemo-evpn-symmetric demo with the addition of Netq2.x.

---

>©2019 Cumulus Networks. CUMULUS, the Cumulus Logo, CUMULUS NETWORKS, and the Rocket Turtle Logo 
(the “Marks”) are trademarks and service marks of Cumulus Networks, Inc. in the U.S. and other 
countries. You are not permitted to use the Marks without the prior written consent of Cumulus 
Networks. The registered trademark Linux® is used pursuant to a sublicense from LMI, the exclusive 
licensee of Linus Torvalds, owner of the mark on a world-wide basis. All other marks are used under 
fair use or license from their respective owners.

For further details please see: [cumulusnetworks.com](http://www.cumulusnetworks.com)
