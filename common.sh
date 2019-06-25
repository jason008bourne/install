export USER_WHO="admin"
export INSTALL_ROOT="program"
export PROGRAM_PATH="/home/${USER_WHO}/${INSTALL_ROOT}/deploy"
export DOCKER_DATA_PATH_ROOT="/home/${USER_WHO}/docker"
export DATA_PATH_ROOT="/home/${USER_WHO}/${INSTALL_ROOT}/data"
export JAVA_CONFIG_ROOT="/java-common-config"
sudo mkdir -p ${JAVA_CONFIG_ROOT} && sudo cp ../java/* ${JAVA_CONFIG_ROOT} && sudo mv ${JAVA_CONFIG_ROOT}/jmx_prometheus_javaagent-0.11.0.jar ${JAVA_CONFIG_ROOT}/jmx_prometheus_javaagent.jar
#prometheus监控agent到配置文件根目录，后面直接跟上配置文件名字即可

