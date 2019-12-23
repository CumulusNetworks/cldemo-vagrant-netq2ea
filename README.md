# NetQ SaaS (Cloud) EA server support
Built On Packet.net m2.xlarge Ubuntu 16.04 server chai

This branch is meant to support the EA NetQ SaaS server. To support this, we need to use custom EA agents that aren't on the repo right now.

How to use this branch:
* watch-dropbox.sh is installed as a cron job that runs every minute

`* * * * * /usr/bin/watch-dropbox.sh`

1) Upload the EA client deb packages to `/mnt/nvme/engineering-dropbox` They will be automatically moved into the correct directory with the correct name (as is defined in Vagrantfile) for the `vagrant up`

2) The base OS box for the NetQ cloud will always be `device.vm.box = "cumulus/tscloud-ea"` Use the included json file to add new boxes with different versions.

We may not always get an updated cloud opta base OS for EA. The base OS box kind of doesn't matter. If in doubt, use the most recent offical release of the base OS.

The `netq install opta` for the tarball is really what drives the NetQ version


---

>©2017 Cumulus Networks. CUMULUS, the Cumulus Logo, CUMULUS NETWORKS, and the Rocket Turtle Logo 
(the “Marks”) are trademarks and service marks of Cumulus Networks, Inc. in the U.S. and other 
countries. You are not permitted to use the Marks without the prior written consent of Cumulus 
Networks. The registered trademark Linux® is used pursuant to a sublicense from LMI, the exclusive 
licensee of Linus Torvalds, owner of the mark on a world-wide basis. All other marks are used under 
fair use or license from their respective owners.

For further details please see: [cumulusnetworks.com](http://www.cumulusnetworks.com)
