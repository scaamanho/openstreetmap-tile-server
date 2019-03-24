# osm-tile-server

This proyect is aimed to create a empty OpenStreetMap PNG tile server for rendering layers over it, with [Leaflet](https://leafletjs.com/) or [OpenLayer](https://openlayers.org/)

It is based on the [latest Ubuntu 18.04 LTS guide](https://switch2osm.org/manually-building-a-tile-server-18-04-lts/) from [switch2osm.org](https://switch2osm.org/) and [openstreetmap-tile-server](https://github.com/Overv/openstreetmap-tile-server)

## Roadmap

* [x] Standalone Docker image
* [x] Standalone Kuebernete Pod
* [x] Simple default frontend
* [x] Peristent Volumes in Docker
* [ ] Persistent Volumes in Kubernetes
* [ ] Import `osm` and `osm.pbf` files throught volumes
* [ ] Custom styles rendering map
* [ ] Use remote database (far away...)

## Deploy on Docker

### Build Docker image

```shell 
$ docker build -t osm-tile-server .
```

### Create Volumes and run container

Tiles that have already been rendered will be stored in `/var/lib/mod_tile`. To make sure that this data survives container restarts, you should create another volume for it

```shell
$ docker volume create osm-data
$ docker volume create osm-rendered-tiles
$ docker run -p 80:80 -v osm-data:/var/lib/postgresql/10/main \
      -v osm-rendered-tiles:/var/lib/mod_tile \
      -d scaamanho/osm-tile-server run
```

The import and tile serving processes use 4 threads by default, but this number can be changed by setting the `THREADS` environment variable.
```shell
$ docker run -p 80:80 -e THREADS=24 -v osm-data:/var/lib/postgresql/10/main -d scaamanho/osm-tile-server run
```


### Deploy with Docker Compose

```shell
$ docker-compose up [-d]
```

### Push image to Registry
Login to docker hub:
```shell 
$ docker login --username=yourhubusername --email=youremail@company.com
WARNING: login credentials saved in /home/username/.docker/config.json
Login Succeeded
```
Check the image id
```
docker images
REPOSITORY              TAG       IMAGE ID         CREATED           SIZE
osm-tile-server         latest    023ab91c6291     3 minutes ago     3.750 GB
...
```
add your tag image
```shell
docker tag bb38976d03cf yourhubusername/osm-tile-server:latest
```
Push your image to the repository you created
```shell
docker push yourhubusername/osm-tile-server
```

### Load and saving images
Pushing to Docker Hub is great, but it does have some disadvantages:
- It take a lot of bandwidht uploading and downloading images 
- When working on some clusters, each time you launch a job that uses a Docker container it pulls the container from Docker Hub, and if you are running many jobs, this can be really slow.

Solutions to these problems can be to save the Docker container locally as a a tar archive, and then you can easily load that to an image when needed.

To save a Docker image after you have pulled, committed or built it you use the docker save command. For example, lets save a local copy of the `osm-tile-server` docker image we made:
```shell
docker save osm-tile-server > osm-tile-server.tar
```
If we want to load that Docker container from the archived tar file in the future, we can use the docker load command:
```shell
docker load --input osm-tile-server.tar
```

### Import new data in osm-tile-server
[TODO]

## Deploy in Kubernetes

### Install Kubernetes registry as Docker registry
This step is not needed, but allow you deploy custom images and push them into Kubernetes registry, instead push to Docker registry or push it to custom registry and deal with security and certificates.

This osm-tile-server image takes its time in create, push and pull from Docker Hub, so unless u have a great machine and a great connection speed, use this method to speed up the process

Based on  [Sharing a local registry for minikube](https://blog.hasura.io/sharing-a-local-registry-for-minikube-37c7240d0615/)

#### Create a Docker Registry inside Kubernetes

```bash
$ kubectl create -f kube-registry.yaml
```
#### Point your docker client at kubertes docker daemon

##### Minikube
```bash
$ eval $(minikube docker-env)
```
this command exports the followin enviroment variables
```shell
$ minikube docker-env
export DOCKER_TLS_VERIFY="1"
export DOCKER_HOST="tcp://192.168.39.36:2376"
export DOCKER_CERT_PATH="/home/scaamano/.minikube/certs"
export DOCKER_API_VERSION="1.35"
# Run this command to configure your shell:
# eval $(minikube docker-env)
```
##### Kubernetes Cluster
[TODO]


#### Build and push an image.
Now you can build a push your docker images to Kubernetes registry
docker login <REGISTRY_HOST>:<REGISTRY_PORT>  
docker tag <IMAGE_ID> <REGISTRY_HOST>:<REGISTRY_PORT>/<APPNAME>:<APPVERSION>  
docker push <REGISTRY_HOST>:<REGISTRY_PORT>/<APPNAME>:<APPVERSION>  

```bash
$ docker build -t osm-tile-server .
$ docker login repo.company.com:3456
$ docker tag 19fcc4aa71ba repo.company.com:3456/myapp:0.1
$ docker push repo.company.com:3456/myapp:0.1
```
### Install osm-tile-server on Kubernetes
**NOTE**: Is needed set permisions in mount directories due they are not writen by root user
```shell
$ minikube ssh
$ sudo mkdir -p /data/osm-db
$ sudo mkdir -p /data/osm-tile
$ sudo chmod 777 /dat /osm*
```


```bash
kubectl create -f osm-k8s-full.yaml
```
You can now test your server with: 

curl http://$(minukube ip)/osm/tile/{z}/{x}/{y}.png
curl http://$(minukube ip)/osm/

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
