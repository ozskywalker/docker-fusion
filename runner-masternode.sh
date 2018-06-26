#!/bin/bash
echo Running Fusion in Multi-Node
echo This is the first node

HOSTNAME=`hostname`
IPADDRESS=`ip -4 addr show scope global dev eth0 | grep inet | awk '{print \$2}' | cut -d / -f 1`

if [ -e /opt/firstsetup_complete ]
then
	echo Cluster setup already completed - proceed with services start
	cd /opt/fusion/4.0.2/
	/usr/local/bin/zk-init.sh 1 &
	bin/fusion stop ; bin/fusion start
	tail -f /dev/null
else
	echo setting zkQuorum as 127.0.0.1
	echo 127.0.0.1 zkQuorum >> /etc/hosts

	# upload config
	echo creating default.json with single server $HOSTNAME
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

	if [ \! -z "$ZOO_SERVERS" ]
	then
		echo Crafting zookeeper servers config
		for server in `echo $ZOO_SERVERS | cut -d' '`; do
			echo "$server" >> "/tmp/zookeeper/conf/zoo.cfg"
		done
		echo Final zoo.cfg
		cat /tmp/zookeeper/conf/zoo.cfg
	else
		echo No ZOO_SERVERS specified, assuming single server only
		echo "server.1=0.0.0.0:2888:3888:participant;2781" >> /tmp/zookeeper/conf/zoo.cfg
	fi

	echo starting first Zookeeper node
	/usr/local/bin/zk-init.sh 1 &

	echo zookeeper: creating /lucid/search-clusters
	/opt/fusion/4.0.2/apps/solr-dist/server/scripts/cloud-scripts/zkcli.sh -z localhost -cmd makepath /lucid/search-clusters
	echo zookeeper: uploading /tmp/default.json to /lucid/search-clusters/default
	/opt/fusion/4.0.2/apps/solr-dist/server/scripts/cloud-scripts/zkcli.sh -z localhost -cmd putfile /lucid/search-clusters/default /tmp/default.json
	rm /tmp/default.json

	echo Editing Fusion configuration file
	sed 's/= 9983/= 2181/g' /opt/fusion/4.0.2/conf/fusion.properties > /tmp/fusion.properties
	sed 's/group.default = zookeeper,/group.default = /g' /tmp/fusion.properties > /tmp/fusion.properties2
	sed 's/zookeeper.start = true/zookeeper.start = false/g' /tmp/fusion.properties2 > /opt/fusion/4.0.2/conf/fusion.properties
	rm /tmp/fusion.properties /tmp/fusion.properties2

	echo "default.address = $HOSTNAME" >> /opt/fusion/4.0.2/conf/fusion.properties

	echo Touching firstsetup_complete
	touch /opt/firstsetup_complete

	if [ \! -z "$NODES" ]
	then
		echo Waiting for zookeeper instances to get their act together
		i=1
		while [ $i -lt $(($NODES+1)) ]; do
			/opt/wait-for-it.sh node$i:$((2181+$i)) -- echo node$i:$((2181+$i)) zookeepeer is alive
			i=$((i+1))
		done
	fi
	
	echo Assuming all zookeeper nodes are up, lets start services
	cd /opt/fusion/4.0.2/
	bin/fusion stop ; bin/fusion start
	tail -f /dev/null
fi
