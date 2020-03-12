#!/bin/bash

which=mongodb
max_thread_env=$1
repl_writer_thread_count=$2
DBFOLDER=${3-`pwd`/databases}

export MONGO_REPL_MAX_THREADS=$max_thread_env

sudo bash -c "
echo never > /sys/kernel/mm/transparent_hugepage/enabled
echo never > /sys/kernel/mm/transparent_hugepage/defrag
echo 1 > /proc/sys/net/ipv4/tcp_fin_timeout
echo 1 > /proc/sys/net/ipv4/tcp_tw_recycle
echo 1 > /proc/sys/net/ipv4/tcp_tw_reuse
"

ulimit -n 60000

WATCHER_PID=/tmp/watcher.pid

start_MongoDB_Master() {
    numactl --interleave=all \
        ./mongod42mod \
        --bind_ip localhost \
        --port 27017 \
        --replSet rs0 \
        --fork \
        --logpath /var/tmp/mongodb0.log \
        --pidfilepath /var/tmp/mongodb0.pid \
        --storageEngine wiredTiger \
        --dbpath ${DBFOLDER}/mongodb/pokec \
        --setParameter replWriterThreadCount=$repl_writer_thread_count

    echo "$!" > "${WATCHER_PID}"
}

start_MongoDB_Replica1() {
    numactl --interleave=all \
        ./mongod42mod \
        --bind_ip localhost \
        --port 27018 \
        --replSet rs0 \
        --fork \
        --logpath /var/tmp/mongodb1.log \
        --pidfilepath /var/tmp/mongodb1.pid \
        --storageEngine wiredTiger \
        --dbpath ${DBFOLDER}/mongodb/pokec1 \
        --setParameter replWriterThreadCount=$repl_writer_thread_count

    echo "$!" > "${WATCHER_PID}"
}

start_MongoDB_Replica2() {
    numactl --interleave=all \
        ./mongod42mod \
        --bind_ip localhost \
        --port 27019 \
        --replSet rs0 \
        --fork \
        --logpath /var/tmp/mongodb2.log \
        --pidfilepath /var/tmp/mongodb2.pid \
        --storageEngine wiredTiger \
        --dbpath ${DBFOLDER}/mongodb/pokec2 \
        --setParameter replWriterThreadCount=$repl_writer_thread_count

    echo "$!" > "${WATCHER_PID}"
}

start_MongoDB_Replicas() {
    start_MongoDB_Replica1
    start_MongoDB_Replica2
}

echo "================================================================================"
echo "* starting: $which $version"
echo "================================================================================"

start_MongoDB_Master

echo "================================================================================"
echo "* starting replicas"
echo "================================================================================"

start_MongoDB_Replicas

