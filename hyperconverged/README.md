# Building the image

Use the _build_image.sh_ script to create a fresh ovshc/unstable image (using the unstable openvstorage repo). This image
will also be saved as ovshc_unstable_img.tar.gz to allow re-use on other hosts.

A version is available via http://fileserver.openvstorage.com/Engineering/docker/ovshc_unstable_img.tar.gz

To load it on a docker host:
```
gzip -dc ovshc_unstable_img.tar.gz | docker load
```

Of course, we also plan to publish this image to allow docker to pull it automatically for you.

# Using the image

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
This will give you a bash shell inside the first running container/node. Do not exit this, as this will remove the setup!

From a browser, access **https://\<IP_OF_THE_FIRST_HOST\>** to open the GUI. 
