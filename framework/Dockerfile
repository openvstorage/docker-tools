FROM ubuntu:14.04.4

ENV DEBIAN_FRONTEND noninteractive
ENV container docker 
ENV TERM xterm

EXPOSE 443

ADD init-fake.conf /etc/init/fake-container-events.conf

RUN echo 'force-unsafe-io' > /etc/dpkg/dpkg.cfg.d/docker-apt-speedup \
 && echo 'DPkg::Post-Invoke { "rm -f /var/cache/apt/archives/*.deb /var/cache/apt/archives/partial/*.deb /var/cache/apt/*.bin || true"; };' > /etc/apt/apt.conf.d/docker-clean \
 && echo 'APT::Update::Post-Invoke { "rm -f /var/cache/apt/archives/*.deb /var/cache/apt/archives/partial/*.deb /var/cache/apt/*.bin || true"; };' >> /etc/apt/apt.conf.d/docker-clean \
 && echo 'Dir::Cache::pkgcache ""; Dir::Cache::srcpkgcache "";' >> /etc/apt/apt.conf.d/docker-clean \
 && echo 'Acquire::Languages "none";' > /etc/apt/apt.conf.d/docker-no-languages \
 && echo 'Acquire::GzipIndexes "true"; Acquire::CompressionTypes::Order:: "gz";' > /etc/apt/apt.conf.d/docker-gzip-indexes \
 \
 \
 && echo "deb http://apt.openvstorage.org unstable main" > /etc/apt/sources.list.d/ovsaptrepo.list \
 && apt-get update -qq \
 && apt-get install -y upstart openssl libvirt-bin omniorb-nameserver fuse avahi-daemon avahi-utils \
 && apt-get install -y --no-install-recommends --allow-unauthenticated openvstorage \
 && sed -i.org '/install_plugins():/a\        return' /opt/OpenvStorage/ovs/extensions/generic/plugins.py \
 && apt-get install -y --no-install-recommends --allow-unauthenticated openvstorage-hc \
 && mv /opt/OpenvStorage/ovs/extensions/generic/plugins.py.org /opt/OpenvStorage/ovs/extensions/generic/plugins.py \
 && rm -rf /var/lib/apt/lists/* \
 && update-rc.d -f gunicorn remove \
 && update-rc.d -f nfs-kernel-server remove \
 && strip /usr/bin/arakoon /usr/bin/alba /usr/lib/alba/*

## following line removes some packages that are pulled in but not needed; but that breaks dependencies
## and, while making the docker image smaller it also prevents extra installs in the container
## && dpkg --purge --force-depends python2.7-dev python-dev libexpat1-dev libc6-dev dpkg-dev libc-dev-bin linux-libc-dev

## ALLOW UPSTART TO WORK
## cfr https://github.com/tianon/dockerfiles/blob/master/sbin-init/ubuntu/upstart/14.04/Dockerfile

RUN rm /usr/sbin/policy-rc.d \
 && rm /sbin/initctl; dpkg-divert --rename --remove /sbin/initctl \
 \
 && /usr/sbin/update-rc.d -f ondemand remove \
 && for f in /etc/init/ureadahead*.conf  \
             /etc/init/udev-fallback-graphics.conf \
             /etc/init/mounted-dev.conf  \
             /etc/init/mounted-proc.conf \
             /etc/init/mounted-run.conf  \
             /etc/init/mounted-tmp.conf  \
             /etc/init/mounted-var.conf  \
             /etc/init/hostname.conf     \
             /etc/init/networking.conf   \
             /etc/init/tty*.conf         \
             /etc/init/plymouth*.conf    \
             /etc/init/hwclock*.conf     \
             /etc/init/module*.conf      \
      ; do dpkg-divert --local --rename --add "$f"; done \
  && echo 'exec mount -a' >>/etc/init/mountall.sh.conf \
  && echo '# /lib/init/fstab: cleared out for bare-bones Docker' > /lib/init/fstab 

ADD networking.conf /etc/init/

## VARIOUS FIXES TO THE OVS PACKAGES
# ADD *.patch /tmp/

RUN cd /; \
    sed -i "/^ALLOWED_HOSTS/s/\]/,'*'\]/" /opt/OpenvStorage/webapps/api/settings.py; \
    sed -i '/^disk:/s/:$/:ovs/' /etc/group;

## MAKE SURE SSH WORKS FOR ROOT
RUN sed -i 's/^PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config; \
    /bin/echo -e 'ovsrooter\novsrooter' | passwd root

WORKDIR /root

CMD ["/sbin/init"]
