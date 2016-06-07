#!/bin/bash

if [ $# -lt 2 -o $# -gt 3 ] 
then
  echo "Usage: $0 <hostname> <nodeip_cidr> [<masternode_ip>]"
  exit 1
fi

weave status &>/dev/null
if [ $? -ne 0 ]
then
  echo 'weave not found... did you launch it?'
  exit 1
fi

############################################################################################

OVS_HOST="$1"
WEAVE_CIDR="$2"
NODE_IP=${WEAVE_CIDR%%/*}
POOL_ROOT='/mnt/ovs'

############################################################################################

MASTER_IP="${3:-${NODE_IP}}"

############################################################################################

create_preconfig()
{
cat >openvstorage_preconfig.json <<__EOF__
{
 "setup":
    {
        "master_ip": "${MASTER_IP}",
        "master_password": "ovsrooter",
        "cluster_ip": "${NODE_IP}",
        "hypervisor_name": "${OVS_HOST}",
        "hypervisor_type": "KVM"
    },
 "asdmanager":
    {
        "api_ip": "${NODE_IP}",
        "asd_ips": [ "${NODE_IP}" ]
    }
}
__EOF__
}

############################################################################################
############################################################################################

eval "$(weave env)"

# uncomment next line if you want to rebuild the image before starting
# docker build --no-cache -t ovshc/unstable .

## start-stop-daemon wants to read certain /proc info which requires SYS_PTRACE capabilities!
## (cfr. http://blog.deliverous.com/2015-01-03.start-stop-daemon.html)
docker run -d -e WEAVE_CIDR="${WEAVE_CIDR}" --name "${OVS_HOST}" \
           -p 443:443 \
           -v /dev:/dev/:ro \
           --cap-add SYS_PTRACE \
           framework
if [ $? -ne 0 ]
then
  docker rm "${OVS_HOST}"
  echo "Starting the docker container failed; aborted!"
  exit 1
fi

## create new /etc/openvstorage_id
## (normally done in openvstorage-core.preinst package; so already installed in the docker image
##  and thus the same on all nodes which should not be)
docker exec -it ${OVS_HOST} /bin/bash -c 'openssl rand -base64 64 | tr -dc A-Z-a-z-0-9 | head -c 16 >/etc/openvstorage_id'

create_preconfig
docker cp openvstorage_preconfig.json "${OVS_HOST}":/opt/OpenvStorage/config/
docker exec -it ${OVS_HOST} ovs setup
docker exec -it ${OVS_HOST} /bin/bash -l
 
#docker exec -it ${OVS_HOST} halt -p
#docker stop --time=30 ${OVS_HOST}
#docker rm ${OVS_HOST}

