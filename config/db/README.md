Die Skripte werden von Docker in aplhabetischer Reihenfolge ausgeführt. 
Somit wird erst drop.sql ausgeführt und dropped eine eventuell vorhandene Database ptv
Danach kommt das init Skript und erstellt die korrekte Datenbank

Diese Skripte werden allerdings nur ausgeführt wenn der Container UND das Volume vorher nicht existiert haben, sollte dies jedoch der Fall sein müssen die Skripte manuell ausgeführt werden:

Mit Docker Container verbinden und bash starten
```
docker exec -it ptv-db bash
```

In Skript Ordner wechseln
```
cd docker-entrypoint-initdb.d/
```

Jeweilige Skripte starten
```
psql -U admin -f drop.sql
```
```
psql -U admin -f initDB.sql
```

Wieder aus Container rauswechseln
```
exit
```