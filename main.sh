SHELL_FOLDER=$(dirname $(readlink -f "$0"))
echo "${SHELL_FOLDER}"
cd ${SHELL_FOLDER}/bin


#启动命令参数解释，总共五个参数，如果中间件团队的zk和kafka集群地址和账户信息什么的没变，可以直接用，如果有改，改成相应参数即可
#第一个参数是zk集群地址，第二个参数是一个数字，代表JVM启动内容，单位是GB 第三个参数是kafka集群地址 第四个参数是kafka账户， 第五个参数是kafka密码
#测试kafka环境的启动命令
bash canal.sh 172.16.174.104:2181,172.16.174.104:2182,172.16.176.97:2181 1 172.16.174.104:2093,172.16.174.104:2093,172.16.176.97:2093 bob bob-pwd

#线上kafka环境的启动命令
#bash canal.sh 172.16.254.29:21811,172.16.254.29:21812,172.16.254.29:21813 3 172.16.254.29:9092 bob bob-pwd
