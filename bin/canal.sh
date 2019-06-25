#!/bin/bash
#1.修改配置文件的mysql连接信息和用户名密码
#2.canal部署,第一个参数绑定的本机ip  第二个参数canal的服务端口 第三个参数 数字 jvm启动的内存 第四个参数zk集群地址
#bash canal.sh 172.16.254.38 21111 1 172.16.254.29:21811,172.16.254.29:21812,172.16.254.29:21813

PROGRAM_VERSION="1.1.3"
source ../common.sh
PROGRAM_NAME="canal"
PROGRAM_DIR="${PROGRAM_PATH}/${PROGRAM_NAME}"
PROGRAM_FILE="${PROGRAM_NAME}.deployer-${PROGRAM_VERSION}.tar.gz"
DOWN_URL="https://github.com/alibaba/${PROGRAM_NAME}/releases/download/${PROGRAM_NAME}-${PROGRAM_VERSION}/${PROGRAM_FILE}"
DATA_PATH="${DATA_PATH_ROOT}/${PROGRAM_NAME}"

PROGRAM_IP=$1
PROGRAM_PORT=$2
JVM_MEMORY=$3
ZK_ADDR=$4
MON_PORT=11110
JAVA_AGENT_PROM="-javaagent:${JAVA_CONFIG_ROOT}/jmx_prometheus_javaagent.jar=${MON_PORT}:${JAVA_CONFIG_ROOT}"
#JVM_ARGS="-Xms$[JVM_MEMORY*1024]m -Xmx$[JVM_MEMORY*1024]m ${JAVA_AGENT_PROM}/jmx-export-common.yaml "
JVM_ARGS="-Xms$[JVM_MEMORY*1024]m -Xmx$[JVM_MEMORY*1024]m "

if [ ! -d "${PROGRAM_DIR}" ]; then
   sudo mkdir -p "${PROGRAM_DIR}"
   #如果文件已经存在，解压
   if [ ! -f ~/${PROGRAM_FILE} ]; then
   	  wget -c -P ~ ${DOWN_URL}
   fi
   sudo tar zxvf ~/${PROGRAM_FILE} -C ${PROGRAM_DIR}
fi
sudo bash ${PROGRAM_DIR}/bin/stop.sh
sudo rm -rf ${PROGRAM_DIR}/conf/example

DEST_STR=
for file in ../${PROGRAM_NAME}/destination/*
do
  if test -f $file 
  then  
    #fileName=${file%.*}
    fileName=`basename $file .properties`
    sudo mkdir -p "${PROGRAM_DIR}/conf/${fileName}"
    sudo cp ${file} ${PROGRAM_DIR}/conf/${fileName}/instance.properties
    if [ -z "${DEST_STR}" ]; then 
        DEST_STR="${fileName}"
    else
        DEST_STR="${DEST_STR},${fileName}"			
    fi
  else
    echo $file 是目录
  fi
done
sudo sed -ri "s/^canal\.ip.*/canal\.ip=${PROGRAM_IP}/" ../${PROGRAM_NAME}/canal.properties
sudo sed -ri "s/^canal\.port.*/canal\.port=${PROGRAM_PORT}/" ../${PROGRAM_NAME}/canal.properties
sudo sed -ri "s/^canal\.zkServers.*/canal\.zkServers=${ZK_ADDR}/" ../${PROGRAM_NAME}/canal.properties
sudo sed -ri "s/^canal\.destinations.*/canal\.destinations=${DEST_STR}/" ../${PROGRAM_NAME}/canal.properties
sudo cp ../${PROGRAM_NAME}/canal.properties ${PROGRAM_DIR}/conf/canal.properties
sudo cp ../${PROGRAM_NAME}/startup.sh ${PROGRAM_DIR}/bin/startup.sh && sudo chmod 755 ${PROGRAM_DIR}/bin/startup.sh
sudo cp ../${PROGRAM_NAME}/stop.sh ${PROGRAM_DIR}/bin/stop.sh && sudo chmod 755 ${PROGRAM_DIR}/bin/stop.sh
sudo chown -R ${USER_WHO}:docker /home/${USER_WHO}/${INSTALL_ROOT}
sudo -u ${USER_WHO} "PATH=${PATH}" "JAVA_OPTS=${JVM_ARGS}" bash ${PROGRAM_DIR}/bin/startup.sh


innerIp=`ip a | grep inet | grep -v inet6 | grep -v docker | grep -v 127 | sed 's/^[ \t]*//g' | cut -d ' ' -f2 | cut -d '/' -f1`

curl -X POST -d '{"ip":"'${innerIp}'","port":'11113',"nodeType":"'canal_exporter'"}' http://consul.prometheus.jiayun.club:8080/registrator

#curl -X POST -d '{"ip":"'${innerIp}'","port":'${MON_PORT}',"nodeType":"'jmx_exporter'"}' http://consul.prometheus.jiayun.club:8080/registrator

