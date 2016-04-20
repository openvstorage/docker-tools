#!/bin/bash

rm -f ovshc_unstable_img.tar.gz
docker build --no-cache -t docker.openvstorage.org/ovshc/unstable .
docker save docker.openvstorage.org/ovshc/unstable | gzip -c >ovshc_unstable_img.tar.gz

