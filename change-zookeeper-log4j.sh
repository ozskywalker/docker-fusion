#!/bin/bash
mv /tmp/zookeeper/conf/log4j.properties /tmp/zookeeper/conf/log4j.properties.default
cat /tmp/zookeeper/conf/log4j.properties.default | sed 's/zookeeper.console.threshold=INFO/zookeeper.console.threshold=WARN/' > /tmp/zookeeper/conf/log4j.properties