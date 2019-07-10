#!/bin/bash
#1.修改配置文件的mysql连接信息和用户名密码,canal默认取内网ip，端口21111,看是否需要调整,
#2.canal部署,第一个参数 zk集群地址 第二个数字 jvm启动的内存 第三个参数kafka集群地址，可以不传，不传canal按照TCP方式运行 第四个参数kafka user 第五个参数kafka password 
#如果第四个参数开始都不传，表示kafka不需要认证，如果传了第四个（任意值）,不传第五个表示kafka开启了默认认证，但使用bob和bob-pwd这组默认账户密码（主要为了测试环境方便
#，测试环境很多人都是设置这组官方默认密码），如果第四个和第五个参数都传了，就完整传入的账户密码
#bash canal.sh 172.16.254.29:21811,172.16.254.29:21812,172.16.254.29:21813 1 172.16.254.29:9092 bob bob-pwd

PROGRAM_VERSION="1.1.3"
source ../common.sh
PROGRAM_NAME="canal"
PROGRAM_DIR="${PROGRAM_PATH}/${PROGRAM_NAME}"
PROGRAM_FILE="${PROGRAM_NAME}.deployer-${PROGRAM_VERSION}.tar.gz"
DOWN_URL="https://github.com/alibaba/${PROGRAM_NAME}/releases/download/${PROGRAM_NAME}-${PROGRAM_VERSION}/${PROGRAM_FILE}"
DATA_PATH="${DATA_PATH_ROOT}/${PROGRAM_NAME}"

innerIp=`ip a | grep inet | grep -v inet6 | grep -v docker | grep -v 127 | sed 's/^[ \t]*//g' | cut -d ' ' -f2 | cut -d '/' -f1`

PROGRAM_IP="${innerIp}"
PROGRAM_PORT=21111
ZK_ADDR=$1
JVM_MEMORY=$2
KAFKA_ADDR=$3
KAFKA_USER=$4
KAFKA_PASS=$5
MON_PORT=11110
JAVA_AGENT_PROM="-javaagent:${JAVA_CONFIG_ROOT}/jmx_prometheus_javaagent.jar=${MON_PORT}:${JAVA_CONFIG_ROOT}"
JVM_ARGS="-Xms$[JVM_MEMORY*1024]m -Xmx$[JVM_MEMORY*1024]m "
#JVM_ARGS="${JVM_ARGS} ${JAVA_AGENT_PROM}/jmx-export-common.yaml"

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

if [ -z "${KAFKA_ADDR}" ]; then 
    sudo sed -ri "s/^canal\.serverMode.*/canal\.serverMode=tcp/" ../${PROGRAM_NAME}/canal.properties
else    
    sudo sed -ri "s/^canal\.serverMode.*/canal\.serverMode=kafka/" ../${PROGRAM_NAME}/canal.properties
    sudo sed -ri "s/^canal\.mq\.servers.*/canal\.mq\.servers=${KAFKA_ADDR}/" ../${PROGRAM_NAME}/canal.properties
fi

if [ -z "${KAFKA_USER}" ]; then 
    sudo cp ../${PROGRAM_NAME}/canal.properties ../${PROGRAM_NAME}/canal-kafka-no-pass.properties
    sudo sed -ri "s/^canal\.mq\.properties\.sasl.*/#/" ../${PROGRAM_NAME}/canal-kafka-no-pass.properties
    sudo sed -ri "s/^canal\.mq\.properties\.security\.protocol.*/#/" ../${PROGRAM_NAME}/canal-kafka-no-pass.properties
    sudo cp ../${PROGRAM_NAME}/canal-kafka-no-pass.properties ${PROGRAM_DIR}/conf/canal.properties
else    
    if [ -z "${KAFKA_PASS}" ]; then 
        sudo sed -ri "s/^canal\.mq\.properties\.sasl\.mechanism.*/canal\.mq\.properties\.sasl\.mechanism=PLAIN/" ../${PROGRAM_NAME}/canal.properties
        sudo sed -ri "s/^canal\.mq\.properties\.sasl\.jaas\.config.*/canal\.mq\.properties\.sasl\.jaas\.config=org\.apache\.kafka\.common\.security\.plain\.PlainLoginModule required username=\"bob\" password=\"bob-pwd\";/" ../${PROGRAM_NAME}/canal.properties
        sudo sed -ri "s/^canal\.mq\.properties\.security\.protocol.*/canal\.mq\.properties\.security\.protocol=SASL_PLAINTEXT/" ../${PROGRAM_NAME}/canal.properties
    else    
        sudo sed -ri "s/^canal\.mq\.properties\.sasl\.mechanism.*/canal\.mq\.properties\.sasl\.mechanism=PLAIN/" ../${PROGRAM_NAME}/canal.properties
        sudo sed -ri "s/^canal\.mq\.properties\.sasl\.jaas\.config.*/canal\.mq\.properties\.sasl\.jaas\.config=org\.apache\.kafka\.common\.security\.plain\.PlainLoginModule required username=\"${KAFKA_USER}\" password=\"${KAFKA_PASS}\";/" ../${PROGRAM_NAME}/canal.properties
        sudo sed -ri "s/^canal\.mq\.properties\.security\.protocol.*/canal\.mq\.properties\.security\.protocol=SASL_PLAINTEXT/" ../${PROGRAM_NAME}/canal.properties
    fi
    sudo cp ../${PROGRAM_NAME}/canal.properties ${PROGRAM_DIR}/conf/canal.properties
fi
sudo cp ../${PROGRAM_NAME}/startup.sh ${PROGRAM_DIR}/bin/startup.sh && sudo chmod 755 ${PROGRAM_DIR}/bin/startup.sh
sudo cp ../${PROGRAM_NAME}/stop.sh ${PROGRAM_DIR}/bin/stop.sh && sudo chmod 755 ${PROGRAM_DIR}/bin/stop.sh
sudo chown -R ${USER_WHO} /home/${USER_WHO}/${INSTALL_ROOT}
sudo -u ${USER_WHO} "PATH=${PATH}" "JAVA_OPTS=${JVM_ARGS}" bash ${PROGRAM_DIR}/bin/startup.sh debug 50005



curl -X POST -d '{"ip":"'${innerIp}'","port":'11113',"nodeType":"'canal_exporter'"}' http://consul.prometheus.jiayun.club:8080/registrator

#curl -X POST -d '{"ip":"'${innerIp}'","port":'${MON_PORT}',"nodeType":"'jmx_exporter'"}' http://consul.prometheus.jiayun.club:8080/registrator

