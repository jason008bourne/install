USER_WHO="ubuntu"
INSTALL_ROOT="initstart"
PROGRAM_PATH="/home/${USER_WHO}/${INSTALL_ROOT}/install/bin"
cd ${PROGRAM_PATH}

runModel=${1}

if [[ -z "${runModel}" ]] || [[ "${runModel}" == "1" ]]; then 
    bash canal-stop.sh
    bash canal-adapter.sh 1
fi

if [[ "${runModel}" == "1" ]] || [[ "${runModel}" == "2" ]]; then 
    bash canal-stop.sh 2
    bash canal.sh 172.16.254.38 21111 1 172.16.254.29:21811,172.16.254.29:21812,172.16.254.29:21813
fi


#canal部署
#1.修改配置文件的mysql连接信息和用户名密码
#第一个参数绑定的本机ip  第二个参数canal的服务端口 第三个参数 数字 jvm启动的内存 第四个参数zk集群地址
#bash canal.sh 172.16.254.38 21111 1 172.16.254.29:21811,172.16.254.29:21812,172.16.254.29:21813




#canal-adapter部署
#1.修改配置文件的mysql连接信息和用户名密码
#参数是一个数字 jvm内存大小
#bash canal-adapter.sh 1




#otter manager
#1.修改配置文件的mysql连接信息和用户名密码
#2.manager部署,第一个参数manager host,第二个参数manager rpc端口，第三个参数web端口，第四个参数 启动内存，是一个数字  第5个参数zk集群地址
#bash otter.sh 172.16.254.29 8082 7070 1 172.16.254.29:21811,172.16.254.29:21812,172.16.254.29:21813




#otter node
#第一个参数manager host,第二个参数manager rpc端口，第三个参数nid一个数字，类似于zk的myid，第四个参数一个数字，node启动的内存
#bash otter.sh 172.16.254.29 8082 2 1          




#zookeeper部署
#1.修改配置的jvm内存大小，2.部署
#第一个参数，ip列表，以“,”分割，表示需要以leader/follower模式部署的ip列表
#第二个参数,ip列表以“,”分割，表示需要以observer模式部署的ip列表，z
#第三个参数,单个ip,当前部署实例ip；
#bash zk-install.sh 172.16.254.28,172.16.254.29,172.16.179.61 172.16.254.26,172.16.254.25 172.16.179.61





#zookeeper部署，docker方式
#1.修改配置的jvm内存大小，2.部署
#第一个参数，ip列表，以“,”分割，表示需要以leader/follower模式部署的ip列表（如果集群是部署在单机上，则是这台机器的 ip）

#第二个参数,ip列表或leader/follower模式与observer模式的数量比，如果集群是分布式部署，则传入ip列表，以“,”分割，表示需要以observer模式部署的ip列表，
#leader/follower模式的zoo_myid，按照ip的顺序从1开始递增，observer模式的zoo_myid，按照ip的顺序从1001开始递增
#如果集群是部署在单机上，则传入逗号分割的数字比（比如5,2表示5个投票模式的实例，2个观察者模式的实例），zoo_myid按照整体的实例数量（5+2=7）分别是（1~7）

#第三个参数,单个ip或者zoo_id（数字）。如果集群是分布式部署，则传入当前实例ip
#如果集群是部署在单机上，则传入数字（比如传入5,表示重新部署第五个实例），
#表示单机部署，3个投票模式的实例，2个观察者模式的实例
#bash zk-docker.sh 172.16.254.29 3,2 1
#表示分布式部署,第一个参数leader/follower模式的机器列表，第二个参数是observer模式的机器列表,第三个参数是当前实例的ip
#bash zk-docker.sh 172.16.254.28,172.16.179.61,172.16.254.27 172.16.254.26,172.16.254.25 172.16.179.61 






#kafka部署docker无法直接运行，不知原因，但会打印出命令行，复制docker命令行，再单独执行一次就可以- -！如果有个性化的配置改server-sasl.properties和server-plian.properties，不要直接改server.properties
#部署步骤 1.修改jvm内存大小 2.修改docker安装y or n  3.bash执行，下面是例子
#第一个参数，brokerId 第二个参数,zookeeper集群连接地址 第三个参数,kafka监听的IP 第四个参数 kafka监听的端口 第五个参数 可以为任意值，也可以不传，如果不传则按照非认证模式部署，如果传了则用SASL认证
bash kafka.sh 1 172.16.254.29:21811,172.16.254.29:21812,172.16.254.29:21813 172.16.254.29 9092
