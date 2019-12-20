# Cumulus Linux Demo Framework Fork for NetQ 2.x On-Prem 

![Reference Topology](./documentation/cldemo_topology.png "Reference Topology")

This branch "debian-packages" is meant to be used when we are in EA or testing release candidates for NetQ On-Prem. In pre-release, we do not have the NetQ agent packages available on our public repo able to be installed using apt or apt-get. We are provided debian packages (debs) from engineering that must be installed manually with the dpkg -i command. These packages are preloaded onto the tea servers (chai or roobios) and the provisioning scripts here assume a constant filename that is copied onto the box, then installed in the config_*.sh script

See more deets here: https://wiki.cumulusnetworks.com/display/PC/Field+Team+Workbenches

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
