use local
db.system.replset.remove({"_id":"rs0"})
db.adminCommand({shutdown : 1})
