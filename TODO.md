[ ]Crear Base de datos de manera externa
**osm2pgsql**  
<https://www.volkerschatz.com/net/osm/osm2pgsql-usage.html>
```
Database access options

-d|--database name
The name of the PostgreSQL database to connect to (default: gis).
-p|--prefix prefix_string
Prefix for table names (default: planet_osm).
-U|--username name
PostgreSQL database user name.
-W|--password
Force password prompt. Otherwise specify password in PGPASS environment variable.
-H|--host hostname
Database server hostname or UNIX-domain socket location. Seems to default to local host.
-P|--port num
Database server port. Defaults to 5432, PostgreSQL's default port.
Options related to an additional hstore-type column for tags
```
https://openmaptiles.org/docs/
https://hub.docker.com/_/openmaptiles-openstreetmap-maps/plans/f1fc533a-76f0-493a-80a1-4e0a2b38a563?tab=instructions
https://hub.docker.com/_/openmaptiles-openstreetmap-maps?tab=description

[ ] Custom Mapnick.css
[ ] Reduce image layers 
  * Juntar apt
  * usar `sudo apt-get autoclean`
  * unificar run commands
[x] Path on static files para que apunten a ingress path files