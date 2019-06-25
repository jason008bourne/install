#!/bin/bash
#1.修改配置文件的mysql连接信息和用户名密码
#2.canal部署,第一个参数绑定的本机ip  第二个参数canal的服务端口 第三个参数 数字 jvm启动的内存 第四个参数zk集群地址
#bash canal.sh 172.16.254.38 21111 1 172.16.254.29:21811,172.16.254.29:21812,172.16.254.29:21813


#echo '[{"job":"product-search-template","last":3800000},{"job":"product-search-etlinfo","last":3000000}]' | jq '.' > product_search.json

#curl -s https://status.github.com/api/status.json | jq '.'
#cat config.json | jq '.'

#lastNum= echo ${jsonConfig} | jq --arg job "${job}" '.[] | select(.job==$job) | .last'
#resp= curl http://127.0.0.1:8081/etl/es/${job}.yml -X POST -d "params=${lastNum}" | jq '.'
#respStatus= echo ${resp} | jq '.succeeded'
#echo ${resp}
#echo ${respStatus}
#if [ "${respStatus}" != "true"  ] ;then
#    echo "job ${job} failed lastNum ${lastNum}" >> ${job}.log
#else
#    respTotal= echo ${resp} | jq '.resultMessage'
#    echo '[{"job":"${job}","last":$((lastNum + respTotal))},{"job":"product-search-etlinfo","last":3000000}]' | jq '.' > ${configFile}
#fi
job="product-search-template"
if [ -z "${1}" ]; then 
    echo "use default config"
else
    job="${1}"
fi
ROOT_DIR="/home/ubuntu/initstart"
configFile="${ROOT_DIR}/${job}.json"
logFile="${ROOT_DIR}/${job}.log"
jsonConfig=$(cat ${configFile})
lastNum=$(echo ${jsonConfig} | jq -r '.last')
resp=$(curl http://127.0.0.1:8081/etl/es/${job}.yml -X POST -d "params=${lastNum}" | jq -r '.')
#curl -X POST -d '{"ip":"'${innerIp}'","port":'${MON_PORT}',"nodeType":"'jmx_exporter'"}' http://consul.prometheus.jiayun.club:8080/registrator
respStatus=$(echo ${resp} | jq -r '.succeeded')
if [ "${respStatus}" != "true"  ] ;then
    echo "job ${job} filed"
else
    respTotal=$(echo ${resp} | jq -r '.resultMessage')
    newLastNum=$((lastNum + respTotal))
    echo "job ${job} success "
    jsonConfigToWrite=$(echo ${jsonConfig} | jq -r ".status |= ${respStatus}" | jq -r ".last |= ${newLastNum}" ) 
    sudo echo "${jsonConfigToWrite}" > ${configFile}
fi
sudo echo "job ${job} isSuccess:${respStatus},oldLastNum:${lastNum},newLastNum:${newLastNum}" >> ${logFile}
curl http://127.0.0.1:8081/count/es/clear

