#!/bin/bash -e

# Add disk plugin
CHECKDISKS="$(df | grep -v "/etc/hosts" | grep '^/dev/' | cut -d ' ' -f 1 | sed 's/^/-p /' | tr '\n' ' ')"
echo "command[check_disk]=$NAGIOS_PLUGINS_DIR/check_disk -w 20% -c 10% $CHECKDISKS" | sudo tee $NAGIOS_CONF_DIR/nrpe.d/disk.cfg > /dev/null

# Start NREP Server
/usr/sbin/nrpe -c $NAGIOS_CONF_DIR/nrpe.cfg -d

# Wait for NRPE Daemon to exit
PID=$(ps -ef | grep -v grep | grep  "/usr/sbin/nrpe" | awk '{print $2}')
while [[ ( -d /proc/$PID ) && ( -z `grep zombie /proc/$PID/status` ) ]]; do
    sleep 10s
done
