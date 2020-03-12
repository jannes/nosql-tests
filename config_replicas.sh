DBFOLDER=${1-`pwd`/databases}

echo "================================================================================"
echo "* configuring replica set"
echo "================================================================================"

$DBFOLDER/mongodb/bin/mongo -host localhost:27017 < replSetSetup.js

echo "waiting until both replicas reach secondary state"
while true; do
    state1=$($DBFOLDER/mongodb/bin/mongo -host localhost:27017 --eval "rs.status().members[1]['state']")
    state2=$($DBFOLDER/mongodb/bin/mongo -host localhost:27017 --eval "rs.status().members[2]['state']")
    s1=$(echo "$state1" | tail -n1)
    s2=$(echo "$state2" | tail -n1)
    echo "repl1 state: $s1"
    echo "repl2 state: $s2"
    if [ "$s1" == '2' ] && [ "$s2" == '2' ]; then
        echo "both replicas are secondary"
        break
    fi
    echo "..."
    sleep 5
done

