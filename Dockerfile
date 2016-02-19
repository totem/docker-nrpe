FROM debian:jessie

RUN apt-get update --fix-missing \
    && apt-get install -q -y nagios-nrpe-server nagios-plugins curl \
    && apt-get clean \
    && rm -rf /var/lib/apt /tmp/* /var/tmp/*

ENV NAGIOS_CONF_DIR /etc/nagios
ENV NAGIOS_PLUGINS_DIR /usr/lib/nagios/plugins

RUN sed -e 's/^allowed_hosts=/#allowed_hosts=/' -i $NAGIOS_CONF_DIR/nrpe.cfg \
    && echo "command[check_load]=$NAGIOS_PLUGINS_DIR/check_load -w 15,10,5 -c 30,25,20" > $NAGIOS_CONF_DIR/nrpe.d/load.cfg \
    && echo "command[check_mem]=$NAGIOS_PLUGINS_DIR/check_mem -f -C -w 12 -c 10 " > $NAGIOS_CONF_DIR/nrpe.d/mem.cfg \
    && echo "command[check_total_procs]=/usr/lib/nagios/plugins/check_procs -w 500 -c 700 " > $NAGIOS_CONF_DIR/nrpe.d/procs.cfg

RUN curl -o /usr/local/bin/dumb-init -L https://github.com/Yelp/dumb-init/releases/download/v1.0.0/dumb-init_1.0.0_amd64 && \
   chmod +x /usr/local/bin/dumb-init

ENV ETCDCTL_VERSION v2.2.5
RUN curl -L https://github.com/coreos/etcd/releases/download/$ETCDCTL_VERSION/etcd-$ETCDCTL_VERSION-linux-amd64.tar.gz -o /tmp/etcd-$ETCDCTL_VERSION-linux-amd64.tar.gz && \
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
