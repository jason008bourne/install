#!/bin/bash
#1.修改配置文件的mysql连接信息和用户名密码
#参数是一个数字 jvm内存大小
#bash canal-adapter.sh 1

PROGRAM_VERSION="1.1.3"
source ../common.sh
PROGRAM_NAME="canal"
PROGRAM_FILE="${PROGRAM_NAME}.adapter-${PROGRAM_VERSION}.tar.gz"
DOWN_URL="https://github.com/alibaba/${PROGRAM_NAME}/releases/download/${PROGRAM_NAME}-${PROGRAM_VERSION}/${PROGRAM_FILE}"
DATA_PATH="${DATA_PATH_ROOT}/${PROGRAM_NAME}"


ZK_ADDR=$1
JVM_MEMORY=$2
KAFKA_ADDR=$3
KAFKA_USER=$4
KAFKA_PASS=$5
INSTANCE_ID=$6


if [ -z "${INSTANCE_ID}" ]; then
    INSTANCE_ID=0
fi
MON_PORT="3111${INSTANCE_ID}"
DEBUG_PORT="5111${INSTANCE_ID}"
PROM_NAME="jmx${INSTANCE_ID}_exporter"

PROGRAM_DIR="${PROGRAM_PATH}/${PROGRAM_NAME}-adapter${INSTANCE_ID}"

JAVA_AGENT_PROM="-javaagent:${JAVA_CONFIG_ROOT}/jmx_prometheus_javaagent.jar=${MON_PORT}:${JAVA_CONFIG_ROOT}"
JVM_ARGS="-Xms$[JVM_MEMORY*1024]m -Xmx$[JVM_MEMORY*1024]m ${JAVA_AGENT_PROM}/jmx-export-common.yaml "
#JVM_ARGS="-Xms$[JVM_MEMORY*1024]m -Xmx$[JVM_MEMORY*1024]m "

if [ ! -d "${PROGRAM_DIR}" ]; then
   sudo mkdir -p "${PROGRAM_DIR}"
   #如果文件已经存在，解压
   if [ ! -f ~/${PROGRAM_FILE} ]; then
   	  #wget -c -P ~ ${DOWN_URL}
	  rclone copy -P hz-jump:hz-jump/${PROGRAM_FILE} ~
   fi
   sudo tar zxvf ~/${PROGRAM_FILE} -C ${PROGRAM_DIR}
fi
sudo bash ${PROGRAM_DIR}/bin/stop.sh

YAML_FILE="../${PROGRAM_NAME}/adapter/application.yml"
if [ -z "${KAFKA_USER}" ]; then
    YAML_FILE="../${PROGRAM_NAME}/adapter/kafka-no-pass.yml"
fi

sudo sed -ri "s/port.*/port: 808${INSTANCE_ID}/" ${YAML_FILE}

if [ -z "${KAFKA_ADDR}" ]; then
    sudo sed -ri "s/mode.*/mode: tcp/" ${YAML_FILE}
else
    sudo sed -ri "s/mode.*/mode: kafka/" ${YAML_FILE}
    sudo sed -ri "s/mqServers.*/mqServers: ${KAFKA_ADDR}/" ${YAML_FILE}
fi

if [ -z "${KAFKA_PASS}" ]; then
    sudo sed -ri "s/config.*/config: org\.apache\.kafka\.common\.security\.plain\.PlainLoginModule required username=\"bob\" password=\"bob-pwd\";/" ${YAML_FILE}
else
    sudo sed -ri "s/config.*/config: org\.apache\.kafka\.common\.security\.plain\.PlainLoginModule required username=\"${KAFKA_USER}\" password=\"${KAFKA_PASS}\";/" ${YAML_FILE}
fi
sudo rm -f ${PROGRAM_DIR}/conf/es/*
sudo cp ../${PROGRAM_NAME}/adapter/es/* ${PROGRAM_DIR}/conf/es
sudo cp ${YAML_FILE} ${PROGRAM_DIR}/conf/application.yml
sudo cp ../${PROGRAM_NAME}/adapter/startup.sh ${PROGRAM_DIR}/bin/startup.sh && sudo chmod 755 ${PROGRAM_DIR}/bin/startup.sh
sudo cp ../${PROGRAM_NAME}/adapter/stop.sh ${PROGRAM_DIR}/bin/stop.sh && sudo chmod 755 ${PROGRAM_DIR}/bin/stop.sh
sudo chown -R ${USER_WHO} /home/${USER_WHO}/${INSTALL_ROOT}
sudo -u ${USER_WHO} "PATH=${PATH}" "JAVA_OPTS=${JVM_ARGS}" bash ${PROGRAM_DIR}/bin/startup.sh debug ${DEBUG_PORT}


innerIp=`ip a | grep inet | grep -v inet6 | grep -v docker | grep -v 127 | sed 's/^[ \t]*//g' | cut -d ' ' -f2 | cut -d '/' -f1`

curl -X POST -d '{"ip":"'${innerIp}'","port":'${MON_PORT}',"nodeType":"'${PROM_NAME}'"}' http://consul.prometheus.jiayun.club:8080/registrator

