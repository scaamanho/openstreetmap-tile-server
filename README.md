# osm-tile-server

This container allows you to easily set up an OpenStreetMap PNG tile server given a `.osm.pbf` file. It is based on the [latest Ubuntu 18.04 LTS guide](https://switch2osm.org/manually-building-a-tile-server-18-04-lts/) from [switch2osm.org](https://switch2osm.org/) and therefore uses the default OpenStreetMap style.

## Setting up the server

First create a Docker volume to hold the PostgreSQL database that will contain the OpenStreetMap data:

    docker volume create openstreetmap-data

Next, download an .osm.pbf extract from geofabrik.de for the region that you're interested in. You can then start importing it into PostgreSQL by running a container and mounting the file as `/data.osm.pbf`. For example:

```
docker run --name osm_import -v /absolute/path/to/luxembourg.osm.pbf:/data.osm.pbf -v osm-data:/var/lib/postgresql/10/main scaamanho/osm-tile-server import
docker container rm osm_import
```


If the container exits without errors, then your data has been successfully imported and you are now ready to run the tile server.

## Running the server

Run the server like this:

```
docker run -name osm -p 80:80 -v osm-data:/var/lib/postgresql/10/main -d scaamanho/osm-tile-server run
```
~~Your tiles will now be available at http://localhost:80/tile/{z}/{x}/{y}.png. If you open `leaflet-demo.html` in your browser, you should be able to see the tiles served by your own machine. Note that it will initially quite a bit of time to render the larger tiles for the first time.~~

## Preserving rendered tiles

Tiles that have already been rendered will be stored in `/var/lib/mod_tile`. To make sure that this data survives container restarts, you should create another volume for it:
```
docker volume create osm-rendered-tiles
docker run -p 80:80 -v osm-data:/var/lib/postgresql/10/main -v osm-rendered-tiles:/var/lib/mod_tile -d scaamanho/osm-tile-server run
```
## Performance tuning

The import and tile serving processes use 4 threads by default, but this number can be changed by setting the `THREADS` environment variable. For example:

    docker run -p 80:80 -e THREADS=24 -v osm-data:/var/lib/postgresql/10/main -d scaamanho/osm-tile-server run

## Kubernetes

### Minukube
<https://github.com/kubernetes/minikube>

```
minikube config set memory 8192
```
or `minikube start --memory 8192`
### Install kompose

```
curl -L https://github.com/kubernetes/kompose/releases/download/v1.18.0/kompose-linux-amd64 -o kompose
chmod +x kompose
sudo mv ./kompose /usr/local/bin/kompose
```

### Creating kubernetes files

 ```
 kompose create -f docker-compose.yml
 ```

### Install on Minukube

```
$kompose up
.... wait about 30 mins to pods download andbe ready
.... check pod status with kubectl describe pod osm and look or eventes

$kubectl get svc
NAME         TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)           AGE
kubernetes   ClusterIP   10.96.0.1        <none>        443/TCP           37h
osm          ClusterIP   10.110.109.182   <none>        80/TCP,5432/TCP   52m

$minikube tunnel & > /dev/null 2>&1

$curl 10.110.109.182
<!DOCTYPE html>
<html>
    <head>
        <title>Custom Tile Server</title>
        ...
```
or u can browse to http://10.110.109.182


## License

```
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
