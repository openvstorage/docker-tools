#!/bin/bash

while :
do
  pkill -e memcached && break
  sleep 2
done

ovs setup <<_EOF_
1
docky
1
1

1

3

_EOF_

# ALLOW ACCESS TO GUI FROM EVERYWHERE
sed -i "/^ALLOWED_HOSTS/s/\]/,'*'\]/" /opt/OpenvStorage/webapps/api/settings.py || echo FAILED

# MAKE SURE ovs CAN ACCESS THE DISKS
usermod -aG disk ovs

