time_stamp=$(date +%F-%H:%M:%S)
cp /etc/fstab /etc/fstab.backup.$time_stamp
# Stores all /dev/sd* and /dev/xvd* entries from fstab into a temporary file
  sed -n 's|^/dev/\(rootvg\)*|\1|p' /etc/fstab | cut -d " " -f1  | cut -d "/" -f2   >/tmp/device_names
while read LINE; do
        # For each line in /tmp/device_names
            echo "$LINE"
            dev_name=`ls -l /dev/mapper/ | grep -w "$LINE" | awk '{print $11}'| cut -d "/" -f2`
         UUID=`ls -l /dev/disk/by-uuid | grep "$dev_name" | sed -n 's/^.* \([^ ]*\) -> .*$/\1/p'`
            echo "$UUID"
        if [ ! -z "$UUID" ]
        then
            # Changes the entry in fstab to UUID form
            sed -i "s|^/dev/rootvg/\<${LINE}\>|UUID=${UUID}|" /etc/fstab 
        fi
done </tmp/device_names

mount -a

