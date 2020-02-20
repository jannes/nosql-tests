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

WATCHER_PID0=/tmp/watcher0.pid
WATCHER_PID1=/tmp/watcher1.pid
WATCHER_PID2=/tmp/watcher2.pid

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
    killPIDFile "/var/tmp/mongodb0.pid"
    killPIDFile "/var/tmp/mongodb1.pid"
    killPIDFile "/var/tmp/mongodb2.pid"
}

start_MongoDB_Master() {
    numactl --interleave=all \
        ${DBFOLDER}/mongodb/bin/mongod42mod \
        --bind_ip 0.0.0.0 \
        --port 27017 \
        --fork \
        --logpath /var/tmp/mongodb0.log \
        --pidfilepath /var/tmp/mongodb0.pid \
        --storageEngine wiredTiger \
        --dbpath ${DBFOLDER}/mongodb/pokec

    nohup bash -c "
while true; do
    sleep 1
    echo -n \"`date`; \"
    ps -C mongod -o 'comm cputime etimes rss pcpu' --no-headers | \
        awk '${AWKCMD}'
done  > $FN 2>&1 " > /dev/null 2>&1 &
    echo "$!" > "${WATCHER_PID0}"
}

start_MongoDB_Replica1() {
    numactl --interleave=all \
        ${DBFOLDER}/mongodb/bin/mongod42mod \
        --bind_ip 0.0.0.0 \
        --port 27018 \
        --fork \
        --logpath /var/tmp/mongodb1.log \
        --pidfilepath /var/tmp/mongodb1.pid \
        --storageEngine wiredTiger \
        --dbpath ${DBFOLDER}/mongodb/pokec1

    nohup bash -c "
while true; do
    sleep 1
    echo -n \"`date`; \"
    ps -C mongod -o 'comm cputime etimes rss pcpu' --no-headers | \
        awk '${AWKCMD}'
done  > $FN 2>&1 " > /dev/null 2>&1 &
    echo "$!" > "${WATCHER_PID1}"
}

start_MongoDB_Replica2() {
    numactl --interleave=all \
        ${DBFOLDER}/mongodb/bin/mongod42mod \
        --bind_ip 0.0.0.0 \
        --port 27019 \
        --fork \
        --logpath /var/tmp/mongodb2.log \
        --pidfilepath /var/tmp/mongodb2.pid \
        --storageEngine wiredTiger \
        --dbpath ${DBFOLDER}/mongodb/pokec2

    nohup bash -c "
while true; do
    sleep 1
    echo -n \"`date`; \"
    ps -C mongod -o 'comm cputime etimes rss pcpu' --no-headers | \
        awk '${AWKCMD}'
done  > $FN 2>&1 " > /dev/null 2>&1 &
    echo "$!" > "${WATCHER_PID1}"
}

start_MongoDB_Replicas() {
    start_MongoDB_Replica1
    start_MongoDB_Replica2
}

echo "================================================================================"
echo "* stopping mongod instances"
echo "================================================================================"

stop_MongoDB

killPIDFile "${WATCHER_PID0}"
killPIDFile "${WATCHER_PID1}"
killPIDFile "${WATCHER_PID2}"

echo "================================================================================"
echo "* starting: $which $version"
echo "================================================================================"

start_MongoDB_Master

echo "================================================================================"
echo "* starting replicas"
echo "================================================================================"

start_MongoDB_Replicas
