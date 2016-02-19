#!/bin/sh -e

export HOST_IP="${HOST_IP:-$(/sbin/ip route|awk '/default/ { print $3 }')}"

export ETCD_HOST="${ETCD_HOST:-$HOST_IP}"
export ETCD_PORT="${ETCD_PORT:-4001}"

export CHECK_YODA="${CHECK_YODA:-}"
export CHECK_YODA_HOST="${CHECK_YODA_HOST:-$HOST_IP}"
export MACHINE_ID="${MACHINE_ID:-local}"

if [ -f "/usr/sbin/nrpe" ]; then
  NRPE_EXEC="/usr/sbin/nrpe"
else
  NRPE_EXEC="/usr/bin/nrpe"
fi


# Add disk plugin
CHECKDISKS="${CHECKDISKS:-$( ls -d -1 /mnt/* || echo)}"
if [ ! -z "$CHECKDISKS" ]; then
    NAGIOS_DRIVES="$(echo "$CHECKDISKS" | awk -F "[ \t\n,]+"  '{for (driveCnt = 1; driveCnt <= NF; driveCnt++) printf "-p %s ",$driveCnt}')"
    echo "command[check_disk]=$NAGIOS_PLUGINS_DIR/check_disk -w 20% -c 10% $NAGIOS_DRIVES" | tee $NAGIOS_CONF_DIR/nrpe.d/disk.cfg > /dev/null
fi

# Start NREP Server
$NRPE_EXEC -c $NAGIOS_CONF_DIR/nrpe.cfg -d

# Wait for NRPE Daemon to exit
PID=$(ps -ef | grep -v grep | grep  "${NRPE_EXEC}" | awk '{print $2}')
if [ ! "$PID" ]; then
  echo "Error: Unable to start nrpe daemon..."
  # exit 1
fi
while [ -d /proc/$PID ] && [ -z `grep zombie /proc/$PID/status` ]; do
    echo "NRPE: $PID (running)..."
    sleep 60s
done
echo "NRPE daemon exited. Quitting.."