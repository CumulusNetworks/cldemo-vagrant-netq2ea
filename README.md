# NetQ SaaS (Cloud) EA server support
Built On Packet.net m2.xlarge Ubuntu 16.04 server
![Reference Topology](./documentation/cldemo_topology.png "Reference Topology")

Prerequisites:
* watch-dropbox.sh is installed as a cron job that runs every minute

`* * * * * /usr/bin/watch-dropbox.sh`

Upload EA client deb packages to /mnt/nvme/engineering-dropbox: They will be automatically moved into the correct directory with the correct name (as is defined in Vagrantfile) for the `vagrant up`

* The base OS box for the NetQ cloud will always be `device.vm.box = "cumulus/tscloud-ea"`
Use the included json file to add new boxes with different versions.
We may not always get an updated cloud opta base OS for EA. The base OS box kind of doesn't matter. If in doubt, use the most recent offical release of the base OS.
The `netq install opta` for the tarball is really what drives the NetQ version

* Clone `git clone -b cloud-opta https://github.com/CumulusNetworks/cldemo-vagrant-netq2ea.git`
* Download the NetQ 2.x libvirt.box file
* Add the image to vagrant: `vagrant box add cumulus-netq-server-2.0.2-ts-amd64-libvirt.box --name=cumulus/ts202`

Using:
1) cd to the directory from the git clone 
2) `vagrant up oob-mgmt-server oob-mgmt-switch`
3) wait for that to load (its a bit messy. don't mind the red lines. it's fine)
4) `vagrant up`
5) wait for that to load (also messy but hey what are ya gonna do)
6) `vagrant ssh oob-mgmt-server`
7) Once in the oob-mgmt-server, the cldemo-evpn-symmetric demo is in the home dir. `cd cldemo-evpn-symmetric`
8) `ansible-playbook run_demo.yml`
9) watch `kubectl get pods` and `docker ps | head` for all of the netq containers to come up and finish loading
10) Launch dat GUI (see wiki page above for what the links/ip/ports might be right now)

Once you do all this, you are running the cldemo-evpn-symmetric demo with netq2.x. The agents are all configured and registered with the telemetry server.  In other words, that should be it. All the cards/features should light up BGP, EVPN, LLDP, CLAG

Everything below this line is from the original cldemo-vagrant readme and might still apply? If you don't want to do cldemo-vagrant-evpn, that's fine the other demos *should* work unmodified.


---

>©2017 Cumulus Networks. CUMULUS, the Cumulus Logo, CUMULUS NETWORKS, and the Rocket Turtle Logo 
(the “Marks”) are trademarks and service marks of Cumulus Networks, Inc. in the U.S. and other 
countries. You are not permitted to use the Marks without the prior written consent of Cumulus 
Networks. The registered trademark Linux® is used pursuant to a sublicense from LMI, the exclusive 
licensee of Linus Torvalds, owner of the mark on a world-wide basis. All other marks are used under 
fair use or license from their respective owners.

For further details please see: [cumulusnetworks.com](http://www.cumulusnetworks.com)
