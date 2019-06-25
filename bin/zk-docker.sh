#!/bin/bash
#1.修改配置的jvm内存大小，2.部署
#第一个参数，ip列表，以“,”分割，表示需要以leader/follower模式部署的ip列表（如果集群是部署在单机上，则是这台机器的 ip）

#第二个参数,ip列表或leader/follower模式与observer模式的数量比，如果集群是分布式部署，则传入ip列表，以“,”分割，表示需要以observer模式部署的ip列表，
#leader/follower模式的zoo_myid，按照ip的顺序从1开始递增，observer模式的zoo_myid，按照ip的顺序从1001开始递增
#如果集群是部署在单机上，则传入逗号分割的数字比（比如5,2表示5个投票模式的实例，2个观察者模式的实例），zoo_myid按照整体的实例数量（5+2=7）分别是（1~7）

#第三个参数,单个ip或者zoo_id（数字）。如果集群是分布式部署，则传入当前实例ip
#如果集群是部署在单机上，则传入数字（比如传入5,表示重新部署第五个实例），
#bash zk-docker.sh 172.16.254.29 3,2 1     表示单机部署，3个投票模式的实例，2个观察者模式的实例
#bash zk-docker.sh 172.16.254.28,172.16.179.61,172.16.254.27 172.16.254.26,172.16.254.25 172.16.179.61 表示分布式部署,第一个参数leader/follower模式的机器列表，第二个参数是observer模式的机器列表,第三个参数是当前实例的ip


leaderFollowerIps=$1
observerIps=$2
currentInstance=$3

leaderFollowerArray=(${leaderFollowerIps//,/ })
leaderFollowerNum=${#leaderFollowerArray[@]} 

tempArray=(${observerIps//,/ })


ZK_DATA_DIR_NAME="otter-zk"
ZK_DATA_PATH="/home/ubuntu/data/docker/${ZK_DATA_DIR_NAME}"

#leader_follower的起始myid
START_ZOOID=0

#observer的起始myid
START_OBSERVER_ZOOID=1000

#内存，单位g
JVM_MEMORY=3


#参数$1是zooId,$2是zooServer参数,$3是client端口，$4挂载volumn根目录
function installZk(){
	echo "$1--$2--$3--$4"
	if [ $1 -le 0 ] ;then
	  return
	fi	
	sudo rm -f $4/conf/* && sudo rm -f $4/data/myid
    sudo mkdir -p $4/conf && sudo cp ../zk/log4j.properties $4/conf/log4j.properties
	echo `docker rm -f ${ZK_DATA_DIR_NAME}$1`
	docker run --name ${ZK_DATA_DIR_NAME}$1 -e ZOO_MY_ID=$1 -e ZOO_LOG4J_PROP="INFO,ROLLINGFILE" -e ZOO_AUTOPURGE_SNAPRETAINCOUNT="${snapRetainCount}" \
	-e ZOO_AUTOPURGE_PURGEINTERVAL="${purgeInterval}" -e ZOO_TICK_TIME="${tickTime}" -e ZOO_INIT_LIMIT="${initLimit}" \
	-e ZOO_SYNC_LIMIT="${syncLimit}" -e ZOO_MAX_CLIENT_CNXNS="${maxClientCnxns}" -e ZOO_SERVERS="$2" -e ZOO_PORT="$3" -e JVMFLAGS="-Xms$[JVM_MEMORY*1024]m -Xmx$[JVM_MEMORY*1024]m" \
	-d --restart always --net=host \
	-v $4/conf:/conf -v $4/logs:/logs -v $4/data:/data -v $4/dataLog:/datalog \
	zookeeper:3.4.14
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

#默认单机模式
DEPLOY_MODE="y"


#如果传入了 zoo_id且leaderFollowerNum>1，则必然是分布式部署

if [ ${leaderFollowerNum} -gt 1 ] ;then
  DEPLOY_MODE="n"
  echo "DEPLOY_MODE=${DEPLOY_MODE}"
fi


currentZooId=0
isObserver="n"
localhostIp="${currentInstance}"
innerIp=`ip a | grep inet | grep -v inet6 | grep -v docker | grep -v 127 | sed 's/^[ \t]*//g' | cut -d ' ' -f2 | cut -d '/' -f1`
echo "outIp=${localhostIp}-----------------innerIp=${innerIp}"
zooServers="globalOutstandingLimit=${globalOutstandingLimit}"


#如果是分布式模式
if [ "${DEPLOY_MODE}" = "n"  ]; then
	loopZooId=${START_ZOOID}
	for leaderFollowIp in ${leaderFollowerArray[@]} 
	do 
	   loopZooId=$[$loopZooId+1]
	   if [ "${localhostIp}" = "${leaderFollowIp}" ] ;then
		currentZooId=${loopZooId}
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
#如果是单机模式	
else
	observerNum=${tempArray[1]}
	zkHostIp=${leaderFollowerArray[0]}
	loopZooId=${START_ZOOID}
	tempNum=${tempArray[0]}
	for((i=1; i<=${tempNum}; i++))
	do 
	   loopZooId=$[$loopZooId+1]
	   zooServers="${zooServers} server.${loopZooId}=${zkHostIp}:${leaderPort}${loopZooId}:${electionPort}${loopZooId}"
	   if [[ -n "${currentInstance}" && "${loopZooId}" = "${currentInstance}" ]] ;then
		  currentZooId=${loopZooId}  
	   fi  	   
	done
	
	for((j=0;j<${observerNum};j++))
	do
	   loopZooId=$[$loopZooId+1]	
	   zooServers="${zooServers} server.${loopZooId}=${zkHostIp}:${leaderPort}${loopZooId}:${electionPort}${loopZooId}:observer"
	   if [[ -n "${currentInstance}" && "${loopZooId}" = "${currentInstance}" ]] ;then
		  currentZooId=${loopZooId}
		  isObserver="y"		  
	   fi	   
	done	
fi


#如果是观察者模式
if [ "${isObserver}" = "y"  ]; then
	zooServers="${zooServers} peerType=observer"
fi

#如果是单机部署
if [ "${DEPLOY_MODE}" = "y"  ]; then
	installZk "${currentZooId}" "${zooServers}" "${clientPort}${currentZooId}" "${ZK_DATA_PATH}/${currentZooId}"
#如果是分布式部署	
else
	installZk "${currentZooId}" "${zooServers}" "${clientPort}" "${ZK_DATA_PATH}"
fi



