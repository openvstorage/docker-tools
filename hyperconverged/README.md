# Building the image

Use the _build_image.sh_ script to create a fresh ovshc/unstable image (using the unstable openvstorage repo). This image
will also be saved as ovshc_unstable_img.tar.gz to allow re-use on other hosts.

A version is available via our Docker registry at docker.openvstorage.org:

To load it on a docker host (assuming you have docker already installed):
```
docker pull docker.openvstorage.org/ovshc/unstable
```

# Using the image

(tip: more detailed info in the wiki on https://github.com/openvstorage/docker-tools/wiki/Taking-the-dockerised-hyperconverged-setup-for-a-testrun)

First download _weave_ to enable networking between docker containers running on different hosts.
```
sudo curl -L git.io/weave -o /usr/local/bin/weave
sudo chmod a+x /usr/local/bin/weave
```

You need a free IP range to use for this network. Here we'll use _10.250.0.0/16_ as an example; feel free to change this
if this range is already taken in your environment.

**On the first host:**
* start weave
```
weave launch --ipalloc-range 10.250.0.0/16
```
* run the _ovscluster.sh_ script to get the first node up and running:
```
./ovscluster.sh create ovshc1 10.250.0.1/16
```
This will give you a bash shell inside the first running container/node. Do not exit this, as this will remove the setup!

**On the second host:**
* start weave
```
weave launch --ipalloc-range 10.250.0.0/16 <IP_OF_FIRST_HOST>
```
* run the _ovscluster.sh_ script to let the second node join the cluster:
```
./ovscluster.sh join ovshc2 10.250.0.2/16
```
This will give you a bash shell inside the second running container/node. Do not exit this, as this will remove the setup!

From a browser, access **https://\<IP_OF_THE_FIRST_HOST\>** to open the GUI. 
Created vpools will be available on /mnt/ovs/\<vpool_name\> on the hosts (outside the container).

# Cleaning up

Simply exit the bash shells in the containers and the whole setup will be discarded.
To stop weave, do
```
weave stop-plugin && weave reset
```
