FROM totem/totem-base:trusty-1.0.2

RUN apt-get update --fix-missing \
    && apt-get install -q -y nagios-nrpe-server nagios-plugins \
    && apt-get clean \
    && rm -rf /var/lib/apt /tmp/* /var/tmp/*

ENV NAGIOS_CONF_DIR /etc/nagios
ENV NAGIOS_PLUGINS_DIR /usr/lib/nagios/plugins

RUN sed -e 's/^allowed_hosts=/#allowed_hosts=/' -i $NAGIOS_CONF_DIR/nrpe.cfg \
    && echo "command[check_load]=$NAGIOS_PLUGINS_DIR/check_load -w 15,10,5 -c 30,25,20" > $NAGIOS_CONF_DIR/nrpe.d/load.cfg \
    && echo "command[check_mem]=$NAGIOS_PLUGINS_DIR/check_mem -f -C -w 12 -c 10 " > $NAGIOS_CONF_DIR/nrpe.d/mem.cfg

ADD run-nrpe.sh /usr/sbin/run-nrpe.sh
RUN chmod +x /usr/sbin/run-nrpe.sh

ADD plugins $NAGIOS_PLUGINS_DIR
RUN chmod +x -R  $NAGIOS_PLUGINS_DIR

EXPOSE 5666

CMD ["/usr/sbin/run-nrpe.sh"]