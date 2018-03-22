FROM ubuntu:16.04
MAINTAINER Damien Joldersma <damien@themaven.net>

ENV NAGIOS_HOME			/opt/nagios
ENV NAGIOS_USER			nagios
ENV NAGIOS_GROUP		nagios
ENV NAGIOS_CMDUSER		nagios
ENV NAGIOS_CMDGROUP		nagios
ENV NAGIOS_CONF_DIR /opt/nagios/etc
ENV NAGIOS_PLUGINS_BRANCH	release-2.2.1
ENV NAGIOS_PLUGINS_DIR /opt/nagios/plugins
ENV NAGIOS_LIBEXEC_DIR /opt/nagios/libexec
ENV NRPE_BRANCH			nrpe-3.2.1

RUN	apt-get update && apt-get install -y \
		curl \
		jq \
		ruby \
		telnet \
		iputils-ping \
		netcat \
		dnsutils \
		build-essential \
		automake \
		autoconf \
		gettext \
		git \
		libssl-dev && \
  apt-get clean

RUN	( egrep -i "^${NAGIOS_GROUP}"    /etc/group || groupadd $NAGIOS_GROUP    )
RUN ( egrep -i "^${NAGIOS_CMDGROUP}" /etc/group || groupadd $NAGIOS_CMDGROUP )
RUN	( id -u $NAGIOS_USER    || useradd --system -d $NAGIOS_HOME -g $NAGIOS_GROUP    $NAGIOS_USER    )
RUN	( id -u $NAGIOS_CMDUSER || useradd --system -d $NAGIOS_HOME -g $NAGIOS_CMDGROUP $NAGIOS_CMDUSER )

RUN	( mkdir -p ${NAGIOS_HOME}/libexec ${NAGIOS_HOME}/var )

RUN	cd /tmp							&& \
	git clone https://github.com/nagios-plugins/nagios-plugins.git -b $NAGIOS_PLUGINS_BRANCH		&& \
	cd nagios-plugins					&& \
	./tools/setup						&& \
	./configure \
		--prefix=${NAGIOS_HOME}				&& \
	make							&& \
	make install						&& \
	make clean	&& \
	mkdir -p /usr/lib/nagios/plugins	&& \
	ln -sf /opt/nagios/libexec/utils.pm /usr/lib/nagios/plugins

RUN	cd /tmp							&& \
	git clone https://github.com/NagiosEnterprises/nrpe.git	-b $NRPE_BRANCH	&& \
	cd nrpe							&& \
	./configure \
	  --with-pkgsysconfdir=/opt/nagios/etc \
		--with-ssl=/usr/bin/openssl \
		--with-ssl-lib=/usr/lib/x86_64-linux-gnu	&& \
	make nrpe						&& \
	make install-config						&& \
	cp -v src/nrpe /usr/bin/nrpe		&& \
	make clean

RUN curl -s -o /usr/local/bin/dumb-init -L https://github.com/Yelp/dumb-init/releases/download/v1.0.0/dumb-init_1.0.0_amd64 && \
   chmod +x /usr/local/bin/dumb-init

ENV ETCDCTL_VERSION v2.2.5
RUN curl -s -L https://github.com/coreos/etcd/releases/download/$ETCDCTL_VERSION/etcd-$ETCDCTL_VERSION-linux-amd64.tar.gz -o /tmp/etcd-$ETCDCTL_VERSION-linux-amd64.tar.gz && \
    cd /tmp && gzip -dc etcd-$ETCDCTL_VERSION-linux-amd64.tar.gz | tar -xof - && \
    cp -f /tmp/etcd-$ETCDCTL_VERSION-linux-amd64/etcdctl /usr/local/bin && \
    rm -rf /tmp/etcd-$ETCDCTL_VERSION-linux-amd64.tar.gz

ADD run-nrpe.sh /usr/sbin/run-nrpe.sh
RUN chmod +x /usr/sbin/run-nrpe.sh

ADD plugins $NAGIOS_PLUGINS_DIR
RUN chmod +x -R  $NAGIOS_PLUGINS_DIR

ADD nrpe.d $NAGIOS_CONF_DIR/nrpe.d

EXPOSE 5666

CMD ["/usr/local/bin/dumb-init", "/usr/sbin/run-nrpe.sh"]
