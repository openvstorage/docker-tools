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

eval "$(weave env)"

sudo mount --make-shared /
sudo mkdir -p ${POOL_ROOT}

# uncomment next line if you want to rebuild the image before starting
# docker build --no-cache -t ovshc/unstable .

docker run -d -p 443:443 -e WEAVE_CIDR="${WEAVE_CIDR}" --name "${OVS_HOST}" \
              --privileged --cap-drop=ALL --cap-add=SYS_ADMIN --cap-add=MKNOD \
              -v /dev:/dev/:ro \
              -v ${POOL_ROOT}:/exports:shared ovshc/unstable

if [ "${JOIN_CLUSTER}" == "True" ]
then
   # wait for avahi-daemon to be up & running
   docker exec "${OVS_HOST}" avahi-daemon --check
   while [ $? -ne 0 ]
   do
     sleep 1
     docker exec "${OVS_HOST}" avahi-daemon --check
   done
   MASTER_IP=$(docker exec "${OVS_HOST}" avahi-browse -atlpf | awk -F ';' '/ovs_cluster_dockey_/ { n=split($4, i, "_"); print i[n-3]"."i[n-2]"."i[n-1]"."i[n]; exit }')
   while [ -z "${MASTER_IP}" ]
   do
     sleep 1
     MASTER_IP=$(docker exec "${OVS_HOST}" avahi-browse -atlpf | awk -F ';' '/ovs_cluster_dockey_/ { n=split($4, i, "_"); print i[n-3]"."i[n-2]"."i[n-1]"."i[n]; exit }')
   done
   echo "MASTER_IP set to ${MASTER_IP}"
fi

sed -e "s/__NODE_IP__/${NODE_IP}/g" \
    -e "s/__MASTER_IP__/${MASTER_IP}/g" \
    -e "s/__JOIN_CLUSTER__/${JOIN_CLUSTER}/g" \
    -e "s/__OVS_HOST__/${OVS_HOST}/g" \
    openvstorage_preconfig.template >openvstorage_preconfig.cfg
docker cp openvstorage_preconfig.cfg "${OVS_HOST}":/tmp
docker exec -it ${OVS_HOST} pkill memcached
docker exec -it ${OVS_HOST} ovs setup
docker exec -it ${OVS_HOST} /bin/bash
 
docker exec -it ${OVS_HOST} halt -p
docker wait ${OVS_HOST}
docker rm ${OVS_HOST}

