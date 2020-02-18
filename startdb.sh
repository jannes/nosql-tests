#!/bin/bash

which=mongodb
FN=$2
DBFOLDER=${3-`pwd`/databases}

sudo bash -c "
echo never > /sys/kernel/mm/transparent_hugepage/enabled
echo never > /sys/kernel/mm/transparent_hugepage/defrag
echo 1 > /proc/sys/net/ipv4/tcp_fin_timeout
echo 1 > /proc/sys/net/ipv4/tcp_tw_recycle
echo 1 > /proc/sys/net/ipv4/tcp_tw_reuse
"

ulimit -n 60000

WATCHER_PID=/tmp/watcher.pid

# comm cputime etimes rss pcpu
export AWKCMD='{a[$1] = $1; b[$1] = $2; c[$1] = $3; d[$1] = $4; e[$1] = $5} END {for (i in a) printf "%s; %s; %s; %0.1f; %0.1f\n", a[i], b[i], c[i], d[i], e[i]}'

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
    killPIDFile "/var/tmp/mongodb.pid"
}

start_MongoDB() {
    numactl --interleave=all \
        ${DBFOLDER}/mongodb/bin/mongod \
        --bind_ip 0.0.0.0 \
        --fork \
        --logpath /var/tmp/mongodb.log \
        --pidfilepath /var/tmp/mongodb.pid \
        --storageEngine wiredTiger \
        --dbpath ${DBFOLDER}/mongodb/pokec

    nohup bash -c "
while true; do
    sleep 1
    echo -n \"`date`; \"
    ps -C mongod -o 'comm cputime etimes rss pcpu' --no-headers | \
        awk '${AWKCMD}'
done  > $FN 2>&1 " > /dev/null 2>&1 &
    echo "$!" > "${WATCHER_PID}"
}


echo "================================================================================"
echo "* stopping mongod"
echo "================================================================================"

stop_MongoDB

killPIDFile "${WATCHER_PID}"

echo "================================================================================"
echo "* starting: $which $version"
echo "================================================================================"

start_MongoDB
