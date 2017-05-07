#!/bin/sh
docker pull failathon/docker-fusion
docker run -p 3000:3000 -p 3001:3001 -p 8764:8764 -p 8765:8765 -p 8983:8983 -p 8984:8984 -p 9983:9983 -d docker-fusion