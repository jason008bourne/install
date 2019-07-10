SHELL_FOLDER=$(dirname $(readlink -f "$0"))
echo "${SHELL_FOLDER}"
cd ${SHELL_FOLDER}/bin
runModel=${1}

if [[ -z "${runModel}" ]] || [[ "${runModel}" == "1" ]]; then 
    bash canal-clean.sh
    bash canal-adapter.sh 1
fi

if [[ "${runModel}" == "1" ]] || [[ "${runModel}" == "2" ]]; then 
    bash canal-clean.sh 2
    bash canal.sh 172.16.254.29:21811,172.16.254.29:21812,172.16.254.29:21813 1 172.16.254.29:9092 bob bob-pwd
fi


#canal部署
#1.修改配置文件的mysql连接信息和用户名密码,canal默认取内网ip，端口21111,看是否需要调整,
#2.canal部署,第一个参数 zk集群地址 第二个数字 jvm启动的内存 第三个参数kafka集群地址，可以不传，不传canal按照TCP方式运行 第四个参数kafka user 第五个参数kafka password 
#如果第四个参数开始都不传，表示kafka不需要认证，如果传了第四个（任意值）,不传第五个表示kafka开启了默认认证，但使用bob和bob-pwd这组默认账户密码（主要为了测试环境方便
#，测试环境很多人都是设置这组官方默认密码），如果第四个和第五个参数都传了，就完整传入的账户密码
#bash canal.sh 172.16.254.29:21811,172.16.254.29:21812,172.16.254.29:21813 1 172.16.254.29:9092 bob bob-pwd




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






#部署步骤 1.修改jvm内存大小 2.修改docker安装y or n  3.如果kafka开启了认证，看是否需要修改认证账户 4.bash执行，下面是例子
#bash kafka.sh 172.16.254.29:21811,172.16.254.29:21812 1 1 a
#第一个参数，brokerId
#第二个参数,JVM内存大小
#第三个参数,zookeeper集群连接地址
#第四个参数 可以为任意值，也可以不传，如果不传则按照非认证模式部署，如果传了则用SASL认证
#docker运行需要先运行命令行，然后docker rm -f kafka1,然后去掉KAFKA_OPTS和JXM_PORT这两个变量,大坑，原因不明
#bash kafka.sh 172.16.254.29:21811,172.16.254.29:21812,172.16.254.29:21813 172.16.254.29 1 1 a
