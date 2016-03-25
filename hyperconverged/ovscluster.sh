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
cat >openvstorage_preconfig.cfg <<__EOF__
[setup]
; join_cluster False for 1st node; True for others
join_cluster = ${JOIN_CLUSTER}
; master_ip is the IP of the 1st node 
master_ip = ${MASTER_IP}
; target_ip & cluster_ip are local IP from this node
target_ip = ${NODE_IP}
cluster_ip = ${NODE_IP}
; this password is set in via Dockerfile; keep them in sync!
target_password = ovsrooter
cluster_name = dockey
; we need to set hypervisor params but these are unused
hypervisor_type = KVM
hypervisor_name = ${OVS_HOST}
hypervisor_username = unknown
hypervisor_password = notsosiekret
hypervisor_ip = 127.0.0.1
;
configure_memcached = True
configure_rabbitmq = True

[asdmanager]
; api_ip is local IP of this node
api_ip = ${NODE_IP}
asd_ips = [ "${NODE_IP}" ]
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

create_preconfig
docker cp openvstorage_preconfig.cfg "${OVS_HOST}":/tmp
docker exec -it ${OVS_HOST} pkill memcached
docker exec -it ${OVS_HOST} ovs setup
docker exec -it ${OVS_HOST} /bin/bash
 
docker exec -it ${OVS_HOST} halt -p
docker wait ${OVS_HOST}
docker rm ${OVS_HOST}

