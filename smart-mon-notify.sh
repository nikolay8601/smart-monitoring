#!/bin/bash
# This script checks the health of disks
 
#Define a friendly name for this machine
mname=$(hostname)
 
#Location to temporary store the error log
logloc="/root/scripts"
#Set default for not sendig mails
sendm="1"
 
# Disks to check
disks=$(ls /dev/sd*[a-z])
 
# Setting up path
PATH="$PATH:/usr/bin:/usr/sbin"
 
# variable containing all needed commands
needed_commands="smartctl awk mail"
 
# Checking if all needed programs are available on system
for command in $needed_commands
do
  if ! hash "$command" > /dev/null 2>&1
  then
    echo "$command not found on system" 1>&2
    exit 1
  fi
done
 
# Checking disk
for disk in $disks
do
  # Creating a array with results
  declare -a status=(`smartctl -a -d auto $disk | awk '/Reallocated_Sector_Ct/ || /Seek_Error_Rate/ { print $2" "$NF }'`)
  # Checking that we do not have any Reallocated Sectors
  if [ "${status[1]}" -ne 0 ]
  then
    echo "$mname Warning: Disk $disk has errors! ${status[0]} ${status[1]} ${status[2]} ${status[3]}. Following complete smartctl output." >> diskerror.log
    smartctl -a -d ata $disk >> $logloc/diskerror.log
    failed=("${failed[@]}" "$disk")
    sendm="1"
  fi
done
 
#Send an e-mail if needed containing the failed diks (fdisks) info.
if [ $sendm == 1 ]; then
  fdisks=${failed[@]}
  mail -s "$mname - You have a disk failing - $disks" monitor@limeisp.com < $logloc/diskerror.log
  rm -rf $logloc/diskerror.log
fi
