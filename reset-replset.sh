
DBFOLDER=${1-`pwd`/databases}

export MONGO_REPL_MAX_THREADS=50

./mongod42mod \
--bind_ip localhost \
--port 27017 \
--fork \
--logpath /var/tmp/mongodb0-single.log \
--storageEngine wiredTiger \
--dbpath $DBFOLDER/mongodb/pokec 

$DBFOLDER/mongodb/bin/mongo -host localhost:27017 --eval "use local"
$DBFOLDER/mongodb/bin/mongo -host localhost:27017 --eval "db.system.replset.remove({"_id":"rs0"})"
$DBFOLDER/mongodb/bin/mongo -host localhost:27017 --eval "db.adminCommand({shutdown : 1})"

