#!/bin/bash

#check if directory is empty
if [ -z "$(ls -A /mnt/nvme/engineering-dropbox)" ]; then
   logger "watch-dropbox: Detected that /mnt/nvme/engineering-dropbox is empty. Exiting"
   exit 0
fi

#check if downloading/transferring is occuring right now
SIZE1=`ls -l /mnt/nvme/engineering-dropbox/ | grep total | cut -d' ' -f2`
sleep 3
SIZE2=`ls -l /mnt/nvme/engineering-dropbox/ | grep total | cut -d' ' -f2`

if [ "$SIZE1" != "$SIZE2" ]; then
 logger "watch-dropbox: Detected that directory size changed. Skipping this run"
 exit 0
fi

logger "watch-dropbox: No download in progress detected. Moving files"
#Get the list of files in the directory
FILELIST=`ls -l /mnt/nvme/engineering-dropbox/ | grep -v '^total' | cut -d' ' -f9`

#for FILE in $FILELIST; do
#  echo $FILE
#done

#Regex paterns to know which files we're working with
ubuntu_apps="^netq-apps_.*ub18.04u.*.deb"
ubuntu_agent="^netq-agent_.*ub18.04u.*.deb"
cl_apps="^netq-apps_.*cl3u.*.deb"
cl_agent="^netq-agent_.*cl3u.*.deb"
netq_onprem="^cumulus-netq-server-.*-ts-amd64.*libvirt.box"
netq_opta="^cumulus-netq-server-.*-tscloud-amd64.*libvirt.box"

for FILE in $FILELIST; do
  if [[ $FILE =~ $ubuntu_apps ]]; then
    logger "watch-dropbox: Found ubuntu apps: $FILE"
    logger "watch-dropbox: moving and renaming to /mnt/nvme/netq_releases/dev-client-debs/netq-apps_ubuntu.deb"
    mv /mnt/nvme/engineering-dropbox/$FILE /mnt/nvme/netq_releases/dev-client-debs/netq-apps_ubuntu.deb
  fi

  if [[ $FILE =~ $ubuntu_agent ]]; then
    logger "watch-dropbox: Found ubuntu agent: $FILE"
    logger "watch-dropbox: moving and renaming to /mnt/nvme/netq_releases/dev-client-debs/netq-agent_ubuntu.deb"
    mv /mnt/nvme/engineering-dropbox/$FILE /mnt/nvme/netq_releases/dev-client-debs/netq-agent_ubuntu.deb
  fi

  if [[ $FILE =~ $cl_apps ]]; then
    logger "watch-dropbox: Found cl apps: $FILE"
    logger "watch-dropbox: moving and renaming to /mnt/nvme/netq_releases/dev-client-debs/netq-apps_cl.deb"
    mv /mnt/nvme/engineering-dropbox/$FILE /mnt/nvme/netq_releases/dev-client-debs/netq-apps_cl.deb
  fi

  if [[ $FILE =~ $cl_agent ]]; then
    logger "watch-dropbox: Found cl agent: $FILE"
    logger "watch-dropbox: moving and renaming to /mnt/nvme/netq_releases/dev-client-debs/netq-agent_cl.deb"
    mv /mnt/nvme/engineering-dropbox/$FILE /mnt/nvme/netq_releases/dev-client-debs/netq-agent_cl.deb
  fi

  if [[ $FILE =~ $netq_onprem ]]; then
    logger "watch-dropbox: Found a NetQ full on prem ts image: $FILE" 
    logger "watch-dropbox: moving to /mnt/nvme/netq_releases folder""
    mv /mnt/nvme/engineering-dropbox/$FILE /mnt/nvme/netq_releases/$FILE
  fi

  if [[ $FILE =~ $netq_opta ]]; then
    logger "watch-dropbox: Found a NetQ OPTA base OS image: $FILE" 
    logger "watch-dropbox: moving to /mnt/nvme/netq_releases folder""
    mv /mnt/nvme/engineering-dropbox/$FILE /mnt/nvme/netq_releases/$FILE
  fi

done
