DBFOLDER=${1-`pwd`/databases}

echo "================================================================================"
echo "* configuring replica set"
echo "================================================================================"

$DBFOLDER/mongodb/bin/mongo -host localhost:27017 < replSetSetup.js

echo "waiting until both replicas reach secondary state"
while 1; do
    state1=$DBFOLDER/mongodb/bin/mongo -host localhost:27017 --eval "rs.status().members[1]['state']"
    state2=$DBFOLDER/mongodb/bin/mongo -host localhost:27017 --eval "rs.status().members[2]['state']"
    if [$state1 == '2'] && [$state2 == '2']; then
        echo "both replicas are secondary"
        break
    fi
    echo "..."
    sleep 5
done

