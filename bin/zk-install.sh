#!/bin/bash
#1.修改配置的jvm内存大小，2.部署
#第一个参数，ip列表，以“,”分割，表示需要以leader/follower模式部署的ip列表
#第二个参数,ip列表以“,”分割，表示需要以observer模式部署的ip列表，z
#第三个参数,单个ip,当前部署实例ip；
#bash zk-install.sh 172.16.254.28,172.16.254.29,172.16.179.61 172.16.254.26,172.16.254.25 172.16.179.61 表示分布式部署,第一个参数leader/follower模式的机器列表，第二个参数是observer模式的机器列表


leaderFollowerIps=$1
observerIps=$2
currentInstance=$3

leaderFollowerArray=(${leaderFollowerIps//,/ })
leaderFollowerNum=${#leaderFollowerArray[@]} 

tempArray=(${observerIps//,/ })
source ../common.sh
FILEPATH="zookeeper-3.4.14"
FILENAME="${FILEPATH}.tar.gz"
DATA_DIR_NAME="zookeeper"
DATA_PATH="${DATA_PATH_ROOT}/${DATA_DIR_NAME}"

JVM_MEMORY=3

MON_PORT=11111
JAVA_AGENT_PROM="-javaagent:${JAVA_CONFIG_ROOT}/jmx_prometheus_javaagent.jar=${MON_PORT}:${JAVA_CONFIG_ROOT}"
JVM_ARGS="-Xms$[JVM_MEMORY*1024]m -Xmx$[JVM_MEMORY*1024]m ${JAVA_AGENT_PROM}/jmx-export-zk.yaml $JVMFLAGS"

#leader_follower的起始myid
START_ZOOID=0

#observer的起始myid
START_OBSERVER_ZOOID=1000


#参数$1是zooId,$2是zooServer参数,$3是client端口，$4 zk数据文件目录
function installFunc(){
	echo "$1--$2--$3--$4"
	
	if [ $1 -le 0 ] ;then
	  return
	fi
	
	if [ ! -d "${PROGRAM_PATH}/${FILEPATH}" ]; then
	   #如果文件已经存在，解压
	   sudo mkdir -p "${PROGRAM_PATH}"
	   if [ ! -f ~/${FILENAME} ]; then
	   	  wget -c -P ~ http://ftp.cuhk.edu.hk/pub/packages/apache.org/zookeeper/${FILEPATH}/${FILENAME}
	   fi
           sudo tar zxvf ~/${FILENAME} -C ${PROGRAM_PATH}
	fi
	
	sudo cp ../zk/log4j.properties ${PROGRAM_PATH}/${FILEPATH}/conf/log4j.properties
	zId=$1
	zooServerStr=$2
	cPort=$3
	rootDir=$4
	dataDir=${rootDir}/data
	confDir=${rootDir}/conf
	logDir=${rootDir}/logs
	sudo mkdir -p ${dataDir} && sudo mkdir -p ${confDir} && sudo mkdir -p ${logDir} 
	sudo mkdir -p ${rootDir}/dataLogDir && sudo cp ../zk/zoo_sample.cfg ${confDir}/zoo.cfg
	sudo chown -R `whoami` ${rootDir} && sudo echo ${zId} > ${dataDir}/myid && sudo echo "clientPort=${cPort}" >> ${confDir}/zoo.cfg
	sudo echo "dataDir=${dataDir}" >> ${confDir}/zoo.cfg && sudo echo "dataLogDir=${rootDir}/dataLogDir" >> ${confDir}/zoo.cfg
	
	for cfgItem in ${zooServerStr[@]} 
	do
	   sudo echo ${cfgItem} >> ${confDir}/zoo.cfg
	done
	sudo bash ${PROGRAM_PATH}/${FILEPATH}/bin/zkServer.sh stop ${confDir}/zoo.cfg
	sudo chown -R ${USER_WHO}:docker /home/${USER_WHO}/${INSTALL_ROOT}
	#export ZOO_LOG4J_PROP="INFO,ROLLINGFILE"
    	#export ZOO_LOG_DIR=${logDir}JAVA_AGENT_PROM
	#JVM_ARGS="-Xms$[JVM_MEMORY*1024]m -Xmx$[JVM_MEMORY*1024]m $JVMFLAGS"
	#export JVMFLAGS=${JVM_ARGS}"
	sudo -u ${USER_WHO} "PATH=${PATH}" "ZOO_LOG4J_PROP=INFO,ROLLINGFILE" "ZOO_LOG_DIR=${logDir}" "JVMFLAGS=${JVM_ARGS}" bash ${PROGRAM_PATH}/${FILEPATH}/bin/zkServer.sh start ${confDir}/zoo.cfg
}





clientPort=2181
#dataDir=/data
#dataLogDir=/datalog
tickTime=2000
initLimit=5
syncLimit=2

#autopurge.snapRetainCount=3
snapRetainCount=3


#12个小时清理一次
#autopurge.purgeInterval=12
purgeInterval=12

#默认60个连接
maxClientCnxns=180

#观察者模式
#peerType=observer

#如果同一个机器部署，且在容器中运行，网络类型不是host的话需要设置这个参数
#quorumListenOnAllIPs=true

#客户端提交请求的速度可能比ZooKeeper处理的速度快得多，特别是当客户端的数量非常多的时候。
#为了防止ZooKeeper因为排队的请求而耗尽内存，ZooKeeper将会对客户端进行限流，
#即限制系统中未处理的请求数量不超过globalOutstandingLimit设置的值。默认的限制是 1000。
globalOutstandingLimit=1500


leaderPort=2888

electionPort=3888

#ZOO_SERVERS="server.1=172.16.254.29:12888:13888 server.2=172.16.254.29:22888:23888 server.3=172.16.254.29:32888:33888 server.4=172.16.254.29:42888:43888:observer server.5=172.16.254.29:52888:53888:observer"




localhostIp="${currentInstance}"
innerIp=`ip a | grep inet | grep -v inet6 | grep -v docker | grep -v 127 | sed 's/^[ \t]*//g' | cut -d ' ' -f2 | cut -d '/' -f1`
echo "outIp=${localhostIp}-----------------innerIp=${innerIp}"

currentZooId=0
isObserver="n"
zooServers="globalOutstandingLimit=${globalOutstandingLimit}"

loopZooId=${START_ZOOID}
for leaderFollowIp in ${leaderFollowerArray[@]} 
do 
   loopZooId=$[$loopZooId+1]
   if [ "${localhostIp}" = "${leaderFollowIp}" ] ;then
      currentZooId=${loopZooId}
      #本机部署要走内网
      zooServers="${zooServers} server.${loopZooId}=${innerIp}:${leaderPort}:${electionPort}"
   else   
      zooServers="${zooServers} server.${loopZooId}=${leaderFollowIp}:${leaderPort}:${electionPort}"
   fi   
done


loopObserverZooId=${START_OBSERVER_ZOOID}
for observerIp in ${tempArray[@]} 
do
   loopObserverZooId=$[$loopObserverZooId+1]	
   if [ "${localhostIp}" = "${observerIp}" ] ;then
      currentZooId=${loopObserverZooId}
      isObserver="y"
      zooServers="${zooServers} server.${loopObserverZooId}=${innerIp}:${leaderPort}:${electionPort}:observer"
   else
      zooServers="${zooServers} server.${loopObserverZooId}=${observerIp}:${leaderPort}:${electionPort}:observer"
   fi   
done

#如果是观察者模式
if [ "${isObserver}" = "y"  ]; then
	zooServers="${zooServers} peerType=observer"
fi
installFunc "${currentZooId}" "${zooServers}" "${clientPort}" "${DATA_PATH}"


curl -X POST -d '{"ip":"'${innerIp}'","port":'${MON_PORT}',"nodeType":"'zk_exporter'"}' http://consul.prometheus.jiayun.club:8080/registrator

