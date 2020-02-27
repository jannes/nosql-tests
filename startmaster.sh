export MONGO_REPL_MAX_THREADS=50

./mongod42mod \
--bind_ip localhost \
--port 27017 \
--storageEngine wiredTiger \
--dbpath databases/mongodb/pokec 
