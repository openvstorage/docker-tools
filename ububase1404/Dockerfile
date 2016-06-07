FROM ubuntu:14.04.4

ENV DEBIAN_FRONTEND noninteractive
ENV container docker 
ENV TERM xterm

ADD init-fake.conf /etc/init/fake-container-events.conf
ADD networking.conf /etc/init/

RUN echo 'force-unsafe-io' > /etc/dpkg/dpkg.cfg.d/docker-apt-speedup \
 && echo 'DPkg::Post-Invoke { "rm -f /var/cache/apt/archives/*.deb /var/cache/apt/archives/partial/*.deb /var/cache/apt/*.bin || true"; };' > /etc/apt/apt.conf.d/docker-clean \
 && echo 'APT::Update::Post-Invoke { "rm -f /var/cache/apt/archives/*.deb /var/cache/apt/archives/partial/*.deb /var/cache/apt/*.bin || true"; };' >> /etc/apt/apt.conf.d/docker-clean \
 && echo 'Dir::Cache::pkgcache ""; Dir::Cache::srcpkgcache "";' >> /etc/apt/apt.conf.d/docker-clean \
 && echo 'Acquire::Languages "none";' > /etc/apt/apt.conf.d/docker-no-languages \
 && echo 'Acquire::GzipIndexes "true"; Acquire::CompressionTypes::Order:: "gz";' > /etc/apt/apt.conf.d/docker-gzip-indexes \
 \
 \
 && apt-get update -qq \
 && apt-get install -y --no-install-recommends upstart openssh-server \
 && rm -rf /var/lib/apt/lists/* /usr/share/man/*  \
 \
 # ALLOW UPSTART TO WORK 
 ## cfr https://github.com/tianon/dockerfiles/blob/master/sbin-init/ubuntu/upstart/14.04/Dockerfile
 \
 && rm /usr/sbin/policy-rc.d \
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
 && echo '# /lib/init/fstab: cleared out for bare-bones Docker' > /lib/init/fstab \
 \
 ## ALLOW SSH FOR ROOT & SET ROOT PASSWORD
 \
 && sed -i -e 's/^PermitRootLogin.*/PermitRootLogin yes/' \
           -e 's/^AcceptEnv/#AcceptEnv/' /etc/ssh/sshd_config \
 && /bin/echo -e 'ovsrooter\novsrooter' | passwd root

WORKDIR /root

CMD ["/sbin/init"]
