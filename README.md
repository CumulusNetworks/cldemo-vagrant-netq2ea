# Cumulus Linux Demo Framework Fork for NetQ2.x
# Cloud OPTA Branch

This is a repo to use a cloud-opta box in place of oob-mgmt-server in a [cldemo-vagrant reference topology](https://github.com/CumulusNetworks/cldemo-vagrant).

Prerequisites:
* Clone `git clone -b cloud-opta https://github.com/CumulusNetworks/cldemo-vagrant-netq2ea.git`
* Download the NetQ 2.x libvirt.box file
* Add the box to vagrant: `vagrant box add cumulus-netq-server-2.2.2-tscloud-amd64-libvirt.box --name=cumulus/tscloud222`

Using:
1) cd to the directory from the git clone 
2) `vagrant up oob-mgmt-server oob-mgmt-switch && vagrant up`
3) `vagrant ssh oob-mgmt-server`
4) Once in the oob-mgmt-server, install the OPTA: (the .tgz is already on the box) 

`netq install opta interface eth0 tarball download config-key <config-key>`
- this step takes a few mins
- config-key should be recieved from onboarding with cloud server

5) Add CLI server to OPTA (and optionally, the network devices)


`netq config add cli server api.netq.cumulusnetworks.com access-key <access-key> secret-key <secret-key> port 443 <premises (name)>`  
`netq config restart cli`

For network devices (leafs, spines, exit), you'll need to include `vrf mgmt` at the end of the `netq config add cli server` command:

`netq config add cli server api.netq.cumulusnetworks.com access-key <access-key> secret-key <secret-key> vrf mgmt`  
`netq config restart cli`

6) Provision the [cldemo-evpn-symmetric](https://github.com/CumulusNetworks/cldemo-evpn-symmetric) demo. We have to `cd ~/cldemo-evpn-symmetric`
7) Then run the playbook `ansible-playbook run_demo.yml`
8) After the playbook completes its run, you can launch the GUI at https://netq.cumulusnetworks.com It will take several minutes for data to populate. It's usually easier to check that agents are showing as registered using the CLI as it tends to indicate earlier than the GUI.

Once you do all this, you are running the cldemo-evpn-symmetric demo with Netq2.x. Have fun.

To destroy the simulation `vagrant destroy -f`, then go back to step #2 to restart.

---

>©2019 Cumulus Networks. CUMULUS, the Cumulus Logo, CUMULUS NETWORKS, and the Rocket Turtle Logo 
(the “Marks”) are trademarks and service marks of Cumulus Networks, Inc. in the U.S. and other 
countries. You are not permitted to use the Marks without the prior written consent of Cumulus 
Networks. The registered trademark Linux® is used pursuant to a sublicense from LMI, the exclusive 
licensee of Linus Torvalds, owner of the mark on a world-wide basis. All other marks are used under 
fair use or license from their respective owners.

For further details please see: [cumulusnetworks.com](http://www.cumulusnetworks.com)
