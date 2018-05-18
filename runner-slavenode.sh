#!/bin/bash
echo Running Fusion in Multi-Node
echo This is a slave node

HOSTNAME=`hostname`
IPADDRESS=`ip -4 addr show scope global dev eth0 | grep inet | awk '{print \$2}' | cut -d / -f 1`

if [ -e /opt/firstsetup_complete ]
then
	echo Cluster setup already completed - proceed with services start
	cd /opt/fusion/4.0.1/
	/usr/local/bin/zk-init.sh $MYID $ZK &
	bin/fusion stop ; bin/fusion start
	tail -f /dev/null
else
	echo setting zkQuorum as 127.0.0.1
	echo 127.0.0.1 zkQuorum >> /etc/hosts

	echo waiting for node1 Zookeeper to come online
	/opt/wait-for-it.sh node1:2181 -- echo node1 zookeeper appears to be up, lets proceed

	# upload config
	echo creating default.json with single server $IPADDRESS
	# this is hardcoded -- make it more dynamic
	read -d '' payload << EOF
{"id" : "default",
  "connectString" : "node1:2181,node2:2182,node3:2183",
  "zkClientTimeout" : 30000,
  "zkConnectTimeout" : 60000,
  "cloud" : true,
  "bufferFlushInterval" : 1000,
  "bufferSize" : 100,
  "concurrency" : 10,
  "validateCluster" : true}
EOF
	echo $payload > /tmp/default.json

	echo Editing Fusion configuration file
	sed 's/= 9983/= 2181/g' /opt/fusion/4.0.1/conf/fusion.properties > /tmp/fusion.properties
	sed 's/group.default = zookeeper,/group.default = /g' /tmp/fusion.properties > /tmp/fusion.properties2
	sed 's/zookeeper.start = true/zookeeper.start = false/g' /tmp/fusion.properties2 > /opt/fusion/4.0.1/conf/fusion.properties
	rm /tmp/fusion.properties /tmp/fusion.properties2

	echo "default.address = $HOSTNAME" >> /opt/fusion/4.0.1/conf/fusion.properties

	echo Touching firstsetup_complete
	touch /opt/firstsetup_complete

	echo Starting services
	cd /opt/fusion/4.0.1/
	/opt/wait-for-it.sh node1:2181 -- echo node1 zookeeper is alive, lets start our node
	/usr/local/bin/zk-init.sh $MYID $ZK &

	echo Sleeping 30 seconds to let zookeeper settle
	sleep 30

	echo checking local zookeeper came alive
	/opt/wait-for-it.sh localhost:2181 -- echo local zookeeper instance is alive, lets start the show || /usr/local/bin/zk-init.sh $MYID $ZK &
	/opt/wait-for-it.sh localhost:2181 -- echo second braindead check complete

	echo clear PIDs/stop fusion services
	/opt/fusion/4.0.1/bin/fusion stop

	echo waiting for node1 components to come online
	/opt/wait-for-it.sh node1:8983 -- echo node1 SOLR is up, waiting on API
	/opt/wait-for-it.sh node1:8765 -- echo node1 API is up, waiting on connectors
	/opt/wait-for-it.sh node1:8984 -- echo node1 connectors are up, waiting on UI
	/opt/wait-for-it.sh node1:8764 -- echo node1 UI is up, lets proceed

	echo start fusion services
	/opt/fusion/4.0.1/bin/fusion start

	tail -f /dev/null
fi
