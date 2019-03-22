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

**NOTE**: Is needed set permisions in mount directories due they are not writen by root user

minikube ssh
sudo mkdir -p /data/osm-db
sudo mkdir -p /data/osm-tile
sudo chmod 777 /dat /osm*


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




## Push images to Kubernetes registry

<https://blog.hasura.io/sharing-a-local-registry-for-minikube-37c7240d0615/>

1. Create a docker registry in k8s  
```
kubectl create -f https://gist.github.com/coco98/b750b3debc6d517308596c248daf3bb1
```

`kube-registry.yaml`
```yaml
apiVersion: v1
kind: ReplicationController
metadata:
  name: kube-registry-v0
  namespace: kube-system
  labels:
    k8s-app: kube-registry
    version: v0
spec:
  replicas: 1
  selector:
    k8s-app: kube-registry
    version: v0
  template:
    metadata:
      labels:
        k8s-app: kube-registry
        version: v0
    spec:
      containers:
      - name: registry
        image: registry:2.5.1
        resources:
          # keep request = limit to keep this container in guaranteed class
          limits:
            cpu: 100m
            memory: 100Mi
          requests:
            cpu: 100m
            memory: 100Mi
        env:
        - name: REGISTRY_HTTP_ADDR
          value: :5000
        - name: REGISTRY_STORAGE_FILESYSTEM_ROOTDIRECTORY
          value: /var/lib/registry
        volumeMounts:
        - name: image-store
          mountPath: /var/lib/registry
        ports:
        - containerPort: 5000
          name: registry
          protocol: TCP
      volumes:
      - name: image-store
        hostPath:
          path: /data/registry/

---

apiVersion: v1
kind: Service
metadata:
  name: kube-registry
  namespace: kube-system
  labels:
    k8s-app: kube-registry
spec:
  selector:
    k8s-app: kube-registry
  ports:
  - name: registry
    port: 5000
    protocol: TCP

---

apiVersion: extensions/v1beta1
kind: DaemonSet
metadata:
  name: kube-registry-proxy
  namespace: kube-system
  labels:
    k8s-app: kube-registry
    kubernetes.io/cluster-service: "true"
    version: v0.4
spec:
  template:
    metadata:
      labels:
        k8s-app: kube-registry
        version: v0.4
    spec:
      containers:
      - name: kube-registry-proxy
        image: gcr.io/google_containers/kube-registry-proxy:0.4
        resources:
          limits:
            cpu: 100m
            memory: 50Mi
        env:
        - name: REGISTRY_HOST
          value: kube-registry.kube-system.svc.cluster.local
        - name: REGISTRY_PORT
          value: "5000"
        ports:
        - name: registry
          containerPort: 80
          hostPort: 5000
```


Set your docker enviroment to local machine
```shell
$ minikube docker-env
export DOCKER_TLS_VERIFY="1"
export DOCKER_HOST="tcp://192.168.39.36:2376"
export DOCKER_CERT_PATH="/home/scaamano/.minikube/certs"
export DOCKER_API_VERSION="1.35"
# Run this command to configure your shell:
# eval $(minikube docker-env)
$ eval $(minikube docker-env)
```

2. Point your `docker` client at minikube's docker daemon by running `eval $(minikube docker-env)`.
3. Build and push an image.

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
