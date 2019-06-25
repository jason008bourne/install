#!/bin/bash
#1.修改配置文件的mysql连接信息和用户名密码
#参数是一个数字 jvm内存大小
#bash canal-adapter.sh 1

PROGRAM_VERSION="1.1.3"
source ../common.sh
PROGRAM_NAME="canal"
PROGRAM_DIR="${PROGRAM_PATH}/${PROGRAM_NAME}-adapter"
PROGRAM_FILE="${PROGRAM_NAME}.adapter-${PROGRAM_VERSION}.tar.gz"
DOWN_URL="https://github.com/alibaba/${PROGRAM_NAME}/releases/download/${PROGRAM_NAME}-${PROGRAM_VERSION}/${PROGRAM_FILE}"
DATA_PATH="${DATA_PATH_ROOT}/${PROGRAM_NAME}"


JVM_MEMORY=$1
MON_PORT=11110
JAVA_AGENT_PROM="-javaagent:${JAVA_CONFIG_ROOT}/jmx_prometheus_javaagent.jar=${MON_PORT}:${JAVA_CONFIG_ROOT}"
JVM_ARGS="-Xms$[JVM_MEMORY*1024]m -Xmx$[JVM_MEMORY*1024]m ${JAVA_AGENT_PROM}/jmx-export-common.yaml "
#JVM_ARGS="-Xms$[JVM_MEMORY*1024]m -Xmx$[JVM_MEMORY*1024]m "

if [ ! -d "${PROGRAM_DIR}" ]; then
   sudo mkdir -p "${PROGRAM_DIR}"
   #如果文件已经存在，解压
   if [ ! -f ~/${PROGRAM_FILE} ]; then
   	  wget -c -P ~ ${DOWN_URL}
   fi
   sudo tar zxvf ~/${PROGRAM_FILE} -C ${PROGRAM_DIR}
fi
sudo bash ${PROGRAM_DIR}/bin/stop.sh

sudo rm -f ${PROGRAM_DIR}/conf/es/*
sudo cp ../${PROGRAM_NAME}/adapter/es/* ${PROGRAM_DIR}/conf/es
sudo cp ../${PROGRAM_NAME}/adapter/application.yml ${PROGRAM_DIR}/conf/application.yml
sudo cp ../${PROGRAM_NAME}/adapter/startup.sh ${PROGRAM_DIR}/bin/startup.sh && sudo chmod 755 ${PROGRAM_DIR}/bin/startup.sh
sudo cp ../${PROGRAM_NAME}/adapter/stop.sh ${PROGRAM_DIR}/bin/stop.sh && sudo chmod 755 ${PROGRAM_DIR}/bin/stop.sh
sudo chown -R ${USER_WHO}:docker /home/${USER_WHO}/${INSTALL_ROOT}
sudo -u ${USER_WHO} "PATH=${PATH}" "JAVA_OPTS=${JVM_ARGS}" bash ${PROGRAM_DIR}/bin/startup.sh


innerIp=`ip a | grep inet | grep -v inet6 | grep -v docker | grep -v 127 | sed 's/^[ \t]*//g' | cut -d ' ' -f2 | cut -d '/' -f1`

#curl -X POST -d '{"ip":"'${innerIp}'","port":'11113',"nodeType":"'canal_exporter'"}' http://consul.prometheus.jiayun.club:8080/registrator

curl -X POST -d '{"ip":"'${innerIp}'","port":'${MON_PORT}',"nodeType":"'jmx_exporter'"}' http://consul.prometheus.jiayun.club:8080/registrator

