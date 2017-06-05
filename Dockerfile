FROM ubuntu:latest
MAINTAINER Luke Walker "luke@blackduck.nu"

ENV FUSIONVER=3.0.1
ENV ZOOKEEPERVER=release-3.5.1
ENV LUCIDVIEW=https://github.com/lucidworks/lucidworks-view
WORKDIR /opt

VOLUME ["/zookeeperdata"]

RUN mkdir -p /opt/app \
	&& apt-get -y update \
	&& apt-get -y install wget openjdk-8-jre openjdk-8-jdk ant git nodejs npm \
	&& apt-get clean \
	&& ln -s /usr/bin/nodejs /usr/bin/node \
	&& wget -ct 0 https://download.lucidworks.com/fusion-${FUSIONVER}.tar.gz -O /opt/fusion.tar.gz \
	&& tar -xzf fusion.tar.gz \
	&& rm fusion.tar.gz
RUN npm install -g npm-install-retry \
	&& npm-install-retry --wait 500 --attempts 10 -- -g gulp bower \
	&& git clone ${LUCIDVIEW} /opt/app \
	&& cd /opt/app \
	&& npm install \
	&& bower --allow-root install
RUN mkdir /opt/zookeeper
WORKDIR /opt/zookeeper
RUN git clone https://github.com/apache/zookeeper.git . \
	&& git checkout ${ZOOKEEPERVER} \
	&& ant jar

ADD zoo.cfg /opt/zookeeper/conf/zoo.cfg
ADD FUSION_CONFIG.js /opt/app/FUSION_CONFIG.js

ADD zk-init.sh /usr/local/bin
RUN chmod 755 /usr/local/bin/zk-init.sh

ADD runner-slavenode.sh /opt/runner-slavenode.sh
ADD runner-masternode.sh /opt/runner-masternode.sh
ADD wait-for-it.sh /opt/wait-for-it.sh
RUN chmod 755 /opt/*.sh

EXPOSE 2181/tcp 3000/tcp 3001/tcp 8764/tcp 8765/tcp 8983/tcp 8984/tcp 9983/tcp

ENTRYPOINT ["/opt/runner-masternode.sh"]