DBFOLDER=${1-`pwd`/databases}

echo "================================================================================"
echo "* configuring replica set"
echo "================================================================================"

$DBFOLDER/mongodb/bin/mongo -host localhost:27017 < replSetSetup.js
sleep 5
$DBFOLDER/mongodb/bin/mongo -host localhost:27017 < replSetReconfig.js
