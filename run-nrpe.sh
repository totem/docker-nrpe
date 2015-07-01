#!/bin/bash -e

# Add disk plugin
CHECKDISKS="${CHECKDISKS:-$( ls -d -1 /mnt/* || echo)}"
if [ ! -z "$CHECKDISKS" ]; then
    NAGIOS_DRIVES="$(echo "$CHECKDISKS" | awk -F "[ \t\n,]+"  '{for (driveCnt = 1; driveCnt <= NF; driveCnt++) printf "-p %s ",$driveCnt}')"
    echo "command[check_disk]=$NAGIOS_PLUGINS_DIR/check_disk -w 20% -c 10% $NAGIOS_DRIVES" | sudo tee $NAGIOS_CONF_DIR/nrpe.d/disk.cfg > /dev/null
fi

# Start NREP Server
/usr/sbin/nrpe -c $NAGIOS_CONF_DIR/nrpe.cfg -d

# Wait for NRPE Daemon to exit
PID=$(ps -ef | grep -v grep | grep  "/usr/sbin/nrpe" | awk '{print $2}')
while [[ ( -d /proc/$PID ) && ( -z `grep zombie /proc/$PID/status` ) ]]; do
    sleep 10s
done
