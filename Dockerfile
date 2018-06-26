FROM ubuntu:16.04
MAINTAINER Luke Walker "luke@blackduck.nu"

ENV FUSIONVER=4.0.2
ENV ZOOKEEPERVER=release-3.5.4
ENV LUCIDVIEW=https://github.com/lucidworks/lucidworks-view
WORKDIR /opt

RUN mkdir -p /opt/app \
	&& apt-get -y update \
	&& apt-get -y install wget openjdk-8-jre openjdk-8-jdk ant git nodejs npm \
	&& apt-get clean \
	&& ln -s /usr/bin/nodejs /usr/bin/node \
	&& wget -ct 0 https://download.lucidworks.com/fusion-${FUSIONVER}/fusion-${FUSIONVER}.tar.gz -O /opt/fusion.tar.gz \
	&& tar -xzf fusion.tar.gz \
	&& rm fusion.tar.gz

RUN mkdir /tmp/zookeeper
WORKDIR /tmp/zookeeper
RUN git clone https://github.com/apache/zookeeper.git . \
	&& git checkout ${ZOOKEEPERVER} \
	&& ant jar \
	&& cp /tmp/zookeeper/conf/zoo_sample.cfg /tmp/zookeeper/conf/zoo.cfg

RUN echo "standaloneEnabled=false" >> /tmp/zookeeper/conf/zoo.cfg \
	&& echo "dynamicConfigFile=/tmp/zookeeper/conf/zoo.cfg.dynamic" >> /tmp/zookeeper/conf/zoo.cfg \
	&& echo "reconfigEnabled=true" >> /tmp/zookeeper/conf/zoo.cfg \
	&& echo >> /tmp/zookeeper/conf/zoo.cfg

ADD zk-init.sh /usr/local/bin
RUN chmod 755 /usr/local/bin/zk-init.sh

ADD runner-slavenode.sh /opt/runner-slavenode.sh
ADD runner-masternode.sh /opt/runner-masternode.sh
ADD wait-for-it.sh /opt/wait-for-it.sh
ADD change-zookeeper-log4j.sh /opt/change-zookeeper-log4j.sh
RUN chmod 755 /opt/*.sh
RUN /opt/change-zookeeper-log4j.sh

EXPOSE 2181/tcp 2888/tcp 3888/tcp 3000/tcp 3001/tcp 8764/tcp 8765/tcp 8985/tcp 8983/tcp 8984/tcp 9983/tcp 8771/tcp 8763/tcp 8780/tcp

ENTRYPOINT ["/opt/runner-masternode.sh"]
