#!/bin/bash
#部署步骤 1.修改jvm内存大小 2.修改docker安装y or n  3.bash执行，下面是例子
#bash kafka.sh 172.16.254.29:21811,172.16.254.29:21812 1 1 a
#第一个参数，brokerId
#第二个参数,JVM内存大小
#第三个参数,zookeeper集群连接地址
#第四个参数 可以为任意值，也可以不传，如果不传则按照非认证模式部署，如果传了则用SASL认证


KAFKA_VERSION=2.2.0
SCALA_VERSION=2.12
FILEPATH="kafka_${SCALA_VERSION}-${KAFKA_VERSION}"
FILENAME="${FILEPATH}.tgz"

source ../common.sh
DATA_DIR_NAME="kafka"
DOCKER_DATA_PATH="${DOCKER_DATA_PATH_ROOT}/${DATA_DIR_NAME}"
DATA_PATH="${DATA_PATH_ROOT}/${DATA_DIR_NAME}"

innerIp=`ip a | grep inet | grep -v inet6 | grep -v docker | grep -v 127 | sed 's/^[ \t]*//g' | cut -d ' ' -f2 | cut -d '/' -f1`

zkAddr=$1
brokerId=$2
JVM_MEMORY=$3
sasl=$4
hostAddr="${innerIp}"
hostPort=9092

MON_PORT=9999
INSTALL_DOCKER="y"
JAVA_AGENT_PROM="-javaagent:${JAVA_CONFIG_ROOT}/jmx_prometheus_javaagent.jar=${MON_PORT}:${JAVA_CONFIG_ROOT}"
KAFKA_OPTS="${JAVA_AGENT_PROM}/jmx-export-kafka.yaml"
KAFKA_HEAP="-Xms$[JVM_MEMORY*1024]m -Xmx$[JVM_MEMORY*1024]m"
#参数$1是brokerId,$2是zookeerper集群连接地址 $3是服务监听的ip $4端口，$5 zk数据文件目录
function installFunc(){
	echo "$1--$2--$3--$4--$5"
	
	if [ $1 -le 0 ] ;then
	  return
	fi
	
	if [ "${INSTALL_DOCKER}" != "y"  ] ;then
	  if [ ! -d "${PROGRAM_PATH}/${FILEPATH}" ]; then
	    #如果文件已经存在，解压
	    sudo mkdir -p "${PROGRAM_PATH}"
	    if [ ! -f ~/${FILENAME} ]; then
	   	  wget -c -P ~ https://archive.apache.org/dist/kafka/${KAFKA_VERSION}/${FILENAME}
	    fi
       	    sudo tar zxvf ~/${FILENAME} -C ${PROGRAM_PATH}
	  fi
	fi
	
	bId=$1
	zk=$2
	hostNm=$3
	cPort=$4
	rootDir=$5
	dataDir=${rootDir}/data
	confDir=${rootDir}/conf
	logDir=${rootDir}/logs
	sudo mkdir -p ${dataDir} && sudo mkdir -p ${confDir} && sudo mkdir -p ${logDir} 
	listenStr="PLAINTEXT"
	configFile="server"
	if [ -z "${sasl}" ]; then 
		configFile="${configFile}-plain.properties"
	else
		listenStr="SASL_PLAINTEXT"
		configFile="${configFile}-sasl.properties"
	fi
	sudo sed -ri "s/^broker.id=.*/broker\.id=${bId}/" ../kafka/${configFile}
	sudo sed -ri "s/^log.dirs=.*/log\.dirs=${dataDir////\\/}/" ../kafka/${configFile}
	sudo sed -ri "s/^zookeeper.connect=.*/zookeeper\.connect=${zk}/" ../kafka/${configFile}
	sudo sed -ri "s/^listeners=.*/listeners=${listenStr}:\/\/:${cPort}/" ../kafka/${configFile}
	sudo sed -ri "s/^advertised.listeners=.*/advertised\.listeners=${listenStr}:\/\/${hostNm}:${cPort}/" ../kafka/${configFile}
	sudo cp ../kafka/${configFile} ../kafka/server.properties
	sudo cp -r ../kafka/. ${confDir}
	sudo chown -R ${USER_WHO}:docker /home/${USER_WHO}/${INSTALL_ROOT}
	sudo chown -R ${USER_WHO}:docker ${DOCKER_DATA_PATH} 

    
	
	if [ "${INSTALL_DOCKER}" != "y"  ] ;then
	   sudo bash ${PROGRAM_PATH}/${FILEPATH}/bin/kafka-server-stop.sh ${confDir}/server.properties
	else
	   echo `docker rm -f ${DATA_DIR_NAME}${bId}`
	   sudo sed -ri "s/^log.dirs=.*/log\.dirs=\/kafka\/data/" ${confDir}/server.properties
	fi
	
	if [ "${INSTALL_DOCKER}" != "y"  ] ;then
	   sudo -u ${USER_WHO} "PATH=${PATH}" "LOG_DIR=${logDir}" "KAFKA_HEAP_OPTS=${KAFKA_HEAP}" "KAFKA_OPTS=${KAFKA_OPTS}" "JMX_PORT=9988" bash ${PROGRAM_PATH}/${FILEPATH}/bin/kafka-server-start.sh -daemon ${confDir}/server.properties
	else
	   echo "docker run --restart always --name ${DATA_DIR_NAME}${bId} --net=host -d -e KAFKA_BROKER_ID=${bId} -e KAFKA_LOG_DIRS=/kafka/data -e LOG_DIR=/kafka/logs \
	       -e KAFKA_ZOOKEEPER_CONNECT='${zk}' -e KAFKA_LISTENERS='${listenStr}://:${cPort}' -e KAFKA_ADVERTISED_LISTENERS='${listenStr}://${hostNm}:${cPort}' \
	       -e KAFKA_OPTS='${KAFKA_OPTS}' -e KAFKA_HEAP_OPTS='${KAFKA_HEAP}' -e JMX_PORT=9988 -v ${confDir}:/opt/kafka/config -v ${rootDir}:/kafka \
	       -v /java-common-config:/java-common-config -v /var/run/docker.sock:/var/run/docker.sock registry.cn-hangzhou.aliyuncs.com/chinaqqpub/mq.kafka:${KAFKA_VERSION}"
	   docker run --restart always --name ${DATA_DIR_NAME}${bId} --net=host -d -e KAFKA_BROKER_ID=${bId} -e KAFKA_LOG_DIRS=/kafka/data -e LOG_DIR=/kafka/logs \
	       -e KAFKA_ZOOKEEPER_CONNECT='${zk}' -e KAFKA_LISTENERS='${listenStr}://:${cPort}' -e KAFKA_ADVERTISED_LISTENERS='${listenStr}://${hostNm}:${cPort}' \
	       -e KAFKA_OPTS='${KAFKA_OPTS}' -e KAFKA_HEAP_OPTS='${KAFKA_HEAP}' -e JMX_PORT=9988 -v ${confDir}:/opt/kafka/config -v ${rootDir}:/kafka \
	       -v /java-common-config:/java-common-config -v /var/run/docker.sock:/var/run/docker.sock registry.cn-hangzhou.aliyuncs.com/chinaqqpub/mq.kafka:${KAFKA_VERSION}

	fi
}

if [ "${INSTALL_DOCKER}" != "y"  ] ;then
   installFunc "${brokerId}" "${zkAddr}" "${hostAddr}" "${hostPort}" "${DATA_PATH}/${brokerId}"
else
   installFunc "${brokerId}" "${zkAddr}" "${hostAddr}" "${hostPort}" "${DOCKER_DATA_PATH}/${brokerId}"
fi



