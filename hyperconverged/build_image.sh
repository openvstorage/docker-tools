#!/bin/bash

docker build --no-cache -t ovshc/unstable .
docker save ovshc/unstable | gzip -c >ovshc_unstable_img.tar.gz

