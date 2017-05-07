FROM ubuntu:latest
MAINTAINER Luke Walker "luke@blackduck.nu"

ENV FUSIONVER=3.0.1
ENV LUCIDVIEW=https://github.com/lucidworks/lucidworks-view
WORKDIR /opt

RUN mkdir -p /opt/app \
	&& apt-get -y update \
	&& apt-get -y install wget openjdk-8-jre git nodejs npm \
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

ADD FUSION_CONFIG.js /opt/app/FUSION_CONFIG.js
ADD runner.sh /opt/app/runner.sh
RUN chmod 755 /opt/app/runner.sh

EXPOSE 3000/tcp 3001/tcp 8764/tcp 8765/tcp 8983/tcp 8984/tcp 9983/tcp

ENTRYPOINT ["/opt/app/runner.sh"]