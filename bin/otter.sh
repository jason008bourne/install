#!/bin/bash
#1.修改配置文件的mysql连接信息和用户名密码
#2.manager部署,第一个参数manager host,第二个参数manager rpc端口，第三个参数web端口，第四个参数 启动内存，是一个数字  第5个参数zk集群地址
#bash otter.sh 172.16.254.29 8082 7070 1 172.16.254.29:21811,172.16.254.29:21812,172.16.254.29:21813
#bash otter.sh 172.16.179.61 8082 7070 1 172.16.254.29:21811,172.16.254.29:21812,172.16.254.29:21813
#3.node部署,第一个参数manager host,第二个参数manager rpc端口，第三个参数nid一个数字，类似于zk的myid，第四个参数一个数字，node启动的内存
#bash otter.sh 172.16.254.29 8081 2 1          


OTTER_VERSION="4.2.17"
source ../common.sh
DATA_PATH="${DATA_PATH_ROOT}/otter"
BASE_DIR="${PROGRAM_PATH}/otter"
MANAGER_DIR="${BASE_DIR}/manager"
NODE_DIR="${BASE_DIR}/node"


MANAGER_IP=$1
MANAGER_PORT=$2
#manager时传入web端口号，node时传nid
THIRD_PARAM=$3
JVM_MEMORY=$4
ZK_ADDR=$5
MON_PORT=11110
JAVA_AGENT_PROM="-javaagent:${JAVA_CONFIG_ROOT}/jmx_prometheus_javaagent.jar=${MON_PORT}:${JAVA_CONFIG_ROOT}"
JVM_ARGS="-Xms$[JVM_MEMORY*1024]m -Xmx$[JVM_MEMORY*1024]m ${JAVA_AGENT_PROM}/jmx-export-common.yaml "
#if [ ${#FOURTH_PARAM} -gt 5 ] ;then
if [ -n "${ZK_ADDR}" ] ;then
    MANAGER_FILE="manager.deployer-${OTTER_VERSION}.tar.gz"
	if [ ! -d "${MANAGER_DIR}" ]; then
	   sudo mkdir -p "${MANAGER_DIR}"
	   #如果文件已经存在，解压
	   if [ ! -f ~/${MANAGER_FILE} ]; then
	   	  wget -c -P ~ https://github.com/alibaba/otter/releases/download/otter-${OTTER_VERSION}/${MANAGER_FILE}
	   fi
        sudo tar zxvf ~/${MANAGER_FILE} -C ${MANAGER_DIR}
	fi
	sudo bash ${MANAGER_DIR}/bin/stop.sh
        sudo sed -ri "s/^otter\.domainName.*/otter\.domainName=${MANAGER_IP}/" ../otter/manager.properties
	sudo sed -ri "s/^otter\.communication\.manager\.port.*/otter\.communication\.manager\.port=${MANAGER_PORT}/" ../otter/manager.properties
	sudo sed -ri "s/^otter\.port.*/otter\.port=${THIRD_PARAM}/" ../otter/manager.properties
	sudo sed -ri "s/^otter\.zookeeper\.cluster\.default.*/otter\.zookeeper\.cluster\.default=${ZK_ADDR}/" ../otter/manager.properties
	sudo cp ../otter/manager.properties ${MANAGER_DIR}/conf/otter.properties
	sudo cp ../otter/manager.sh ${MANAGER_DIR}/bin/startup.sh && sudo chmod 755 ${MANAGER_DIR}/bin/startup.sh
	sudo cp ../otter/manager-stop.sh ${MANAGER_DIR}/bin/stop.sh && sudo chmod 755 ${MANAGER_DIR}/bin/stop.sh
	sudo chown -R ${USER_WHO}:docker /home/${USER_WHO}/${INSTALL_ROOT}
	sudo -u ${USER_WHO} "PATH=${PATH}" "JAVA_OPTS=${JVM_ARGS}" bash ${MANAGER_DIR}/bin/startup.sh
else
    NODE_FILE="node.deployer-${OTTER_VERSION}.tar.gz"
	if [ ! -d "${NODE_DIR}" ]; then
	   sudo mkdir -p "${NODE_DIR}"
	   #如果文件不存在，下载
	   if [ ! -f ~/${NODE_FILE} ]; then
	      wget -P ~ https://github.com/alibaba/otter/releases/download/otter-${OTTER_VERSION}/${NODE_FILE}
		  #node节点需要安装这个组件
		  sudo apt-get update && sudo apt-get install -y aria2
	   fi
	   sudo tar zxvf ~/${NODE_FILE} -C ${NODE_DIR}
	fi
	sudo bash ${NODE_DIR}/bin/stop.sh
	sudo sed -ri "s/^otter\.nodeHome.*/otter\.nodeHome=${NODE_DIR////\\/}/" ../otter/node.properties
	sudo sed -ri "s/^otter\.manager\.address.*/otter\.manager\.address=${MANAGER_IP}:${MANAGER_PORT}/" ../otter/node.properties
	sudo echo "${THIRD_PARAM}" > ../otter/nid && sudo cp ../otter/nid ${NODE_DIR}/conf/nid && sudo cp ../otter/node.properties ${NODE_DIR}/conf/otter.properties
	sudo cp ../otter/node.sh ${NODE_DIR}/bin/startup.sh && sudo chmod 755 ${NODE_DIR}/bin/startup.sh
	sudo cp ../otter/node-stop.sh ${NODE_DIR}/bin/stop.sh && sudo chmod 755 ${NODE_DIR}/bin/stop.sh
	sudo chown -R ${USER_WHO}:docker /home/${USER_WHO}/${INSTALL_ROOT}
	sudo -u ${USER_WHO} "PATH=${PATH}" "JAVA_OPTS=${JVM_ARGS}" bash ${NODE_DIR}/bin/startup.sh
fi

innerIp=`ip a | grep inet | grep -v inet6 | grep -v docker | grep -v 127 | sed 's/^[ \t]*//g' | cut -d ' ' -f2 | cut -d '/' -f1`

curl -X POST -d '{"ip":"'${innerIp}'","port":'${MON_PORT}',"nodeType":"'jmx_exporter'"}' http://consul.prometheus.jiayun.club:8080/registrator

