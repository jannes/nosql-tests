#!/bin/bash

DBFOLDER=${1-`pwd`/databases}

sudo bash -c "
echo never > /sys/kernel/mm/transparent_hugepage/enabled
echo never > /sys/kernel/mm/transparent_hugepage/defrag
echo 1 > /proc/sys/net/ipv4/tcp_fin_timeout
echo 1 > /proc/sys/net/ipv4/tcp_tw_recycle
echo 1 > /proc/sys/net/ipv4/tcp_tw_reuse
"

WATCHER_PID0=/tmp/watcher0.pid
WATCHER_PID1=/tmp/watcher1.pid
WATCHER_PID2=/tmp/watcher2.pid
export AWKCMD='{a[$1] = $1; b[$1] = $2; c[$1] = $3; d[$1] = $4}END{for (i in a)printf "%s, %s, %s, %0.1f\n", a[i], b[i], c[i], d[i]}'

killPIDFile() {
    PID_FN=$1
    if test -f ${PID_FN}; then
        PID=`cat ${PID_FN}`
        kill ${PID} 2> /dev/null
        count=0
        while test -d /proc/${PID}; do
            echo "."
            sleep 1
            count=$((${count} + 1))
            if test "${count}" -gt 60; then
                kill -9 ${PID}
            fi
        done
        rm -f ${PID_FN}
    fi
}

stop_MongoDB() {
    killPIDFile "/var/tmp/mongodb0.pid"
    killPIDFile "/var/tmp/mongodb1.pid"
    killPIDFile "/var/tmp/mongodb2.pid"
}


echo "================================================================================"
echo "* stopping mongod instances"
echo "================================================================================"

stop_MongoDB
killPIDFile "${WATCHER_PID0}"
killPIDFile "${WATCHER_PID1}"
killPIDFile "${WATCHER_PID2}"
