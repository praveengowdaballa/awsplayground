#!/bin/bash
File=/etc/hosts
Swap1=$(hostname -f)
Swap2=$(hostname)
sed -i "3s/$Swap1/$swap2/g" "$File"
sed -i "3s/$Swap2/$swap1/2" "$File"
