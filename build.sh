#!/bin/sh
docker build -t docker-fusion .
echo Now you should run:
echo docker run -d --name docker-fusion -p 8764:8764 -p 8983:8983 docker-fusion
