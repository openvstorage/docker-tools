#!/bin/bash

if [ $# != 3 ] || [ "$1" != 'join' -a "$1" != 'create' ]
then
  echo "Usage: $0 create|join <ovs_hostname> <ip_cidr>"
  exit 1
fi

weave status &>/dev/null
if [ $? -ne 0 ]
then
  echo 'weave not found... did you launch it?'
  exit 1
fi

############################################################################################

OVS_HOST="$2"
WEAVE_CIDR="$3"
NODE_IP=${WEAVE_CIDR%%/*}
POOL_ROOT='/mnt/ovs'

############################################################################################

MASTER_IP="${NODE_IP}"  ## will be changed later if joining cluster
JOIN_CLUSTER="True"
if [ "$1" == 'create' ]
then
  JOIN_CLUSTER="False"
fi

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

sudo mount --make-shared /
sudo mkdir -p ${POOL_ROOT}

# uncomment next line if you want to rebuild the image before starting
# docker build --no-cache -t ovshc/unstable .

docker run -d -p 443:443 -e WEAVE_CIDR="${WEAVE_CIDR}" --name "${OVS_HOST}" \
              --privileged --cap-drop=ALL --cap-add=SYS_ADMIN --cap-add=MKNOD \
              -v /dev:/dev/:ro \
              -v ${POOL_ROOT}:/exports:shared docker.openvstorage.org/ovshc/unstable

if [ "${JOIN_CLUSTER}" == "True" ]
then
   # wait for avahi-daemon to be up & running
   docker exec "${OVS_HOST}" avahi-daemon --check
   while [ $? -ne 0 ]
   do
     sleep 1
     docker exec "${OVS_HOST}" avahi-daemon --check
   done
   MASTER_IP=$(docker exec "${OVS_HOST}" avahi-browse -atlpf | awk -F ';' '/ovs_cluster_preconfig-/ { n=split($4, i, "_"); print i[n-3]"."i[n-2]"."i[n-1]"."i[n]; exit }')
   while [ -z "${MASTER_IP}" ]
   do
     sleep 1
     MASTER_IP=$(docker exec "${OVS_HOST}" avahi-browse -atlpf | awk -F ';' '/ovs_cluster_preconfig-/ { n=split($4, i, "_"); print i[n-3]"."i[n-2]"."i[n-1]"."i[n]; exit }')
   done
   echo "MASTER_IP set to ${MASTER_IP}"
fi

## create new /etc/openvstorage_id
## (normally done in openvstorage-core.preinst package; so already installed in the docker image
##  and thus the same on all nodes which should not be)
docker exec -it ${OVS_HOST} /bin/bash -c 'openssl rand -base64 64 | tr -dc A-Z-a-z-0-9 | head -c 16 >/etc/openvstorage_id'

create_preconfig
docker cp openvstorage_preconfig.json "${OVS_HOST}":/opt/OpenvStorage/config/
docker exec -it ${OVS_HOST} pkill memcached
docker exec -it ${OVS_HOST} ovs setup
docker exec -it ${OVS_HOST} /bin/bash
 
docker exec -it ${OVS_HOST} halt -p
docker wait ${OVS_HOST}
docker rm ${OVS_HOST}

