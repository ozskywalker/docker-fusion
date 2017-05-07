# Docker image for Lucidworks Fusion 3.0.1 (+ View)

Built to support a experimental project by loading Lucidworks Fusion and View into a docker container, intended for both single node and 3x node DEV deployments.  This build has not been optimized, nor secured for production usage or exposure to regular internet.

**If you do intend to run this on a exposed network / public cloud**, configure your host firewalls to restrict access to only the necessary ports (:3000 & :8764) and set secure passwords.

**It is not recommended to run 3 node configuration on a machine with less than 16GB RAM and 8x CPUs**

This project also lives in Docker hub as [failathon/docker-fusion](https://registry.hub.docker.com/u/failathon/docker-fusion/)

## Getting Started - 3x Node deployment

```
docker-compose up
```

Worth noting that on resource starved systems, you may need to start node1 by itself (docker-compose up node1), let it settle, then start node2 & node3.

## Getting Started - Single Node

* Internet access is required, both to download Fusion from the Lucidworks website, and to grab required packages from the Ubutnu servers.

* Make sure you have minimum 4-6GB RAM for your docker machine or this will run slow.  Dataset size will also impact memory requirements.  Java & Big Data are always hungry, hungry hippos :)

### Usage -- from Docker Hub (pre-existing image)

(also saved in ./pull_from_docker.sh)

```
docker pull failathon/docker-fusion
docker run -p 3000:3000 -p 3001:3001 -p 8764:8764 -p 8765:8765 -p 8983:8983 -p 8984:8984 -p 9983:9983 -d failathon/docker-fusion
```

### Usage -- Docker CLI / fresh build

(also saved in ./build.sh)

```
git clone https://github.com/failathon/docker-fusion
cd docker-fusion
docker build -t docker-fusion .
docker run -p 3000:3000 -p 3001:3001 -p 8764:8764 -p 8765:8765 -p 8983:8983 -p 8984:8984 -p 9983:9983 -d docker-fusion
```

### Usage -- watching logs

```
docker logs -f <container id/name>
```

Service startup & View logs will be visible here.

### Browser

Once the image has loaded, fire up your web browser at:
* Fusion UI - http://localhost:8764/
* View - http://localhost:3000/search

Other ports:
* SOLR - http://localhost:8983/solr/
* API - http://localhost:8765/api/
* Connectors - http://localhost:8984/connectors/

Sample Quickstart on fresh build:
![quickstart_screenshot](https://raw.githubusercontent.com/failathon/docker-fusion/master/quickstart.png)

## Known Issues

* SOLR fails to start on node2 or node3 - check Zookeeper has loaded successfully.
* Zookeeper complains of address already in use - stop the node, and start it again.
* Not sure if node has joined the zookeeper quorum?  Try querying it using:
```
/opt/fusion/3.0.1/apps/solr-dist/server/scripts/cloud-scripts/zkcli.sh -zkhost node1 -cmd get /zookeeper/config
```

## TODO

* Improve service startup error checking
* Reduce package dependencies to reduce build time
* Automate package build
* Separate out UI from fusion node (+docker-compose)
* Allow SOLR/other services logs to be visible from docker logs (apply https://github.com/jwilder/dockerize)
* Support cluster scaling (edit runner-slavenode.sh, docker-compose)
* Support cluster downsizing (alerting & clean-up scripts)
* Fix routing from host to individual nodes (and reduce exposed ports)

## Version numbers

* solr-spec 6.4.2
* lucene-spec 6.4.2
* OpenJDK 1.8.0
* Fusion 3.0.1
* Zookeeper 3.5.3