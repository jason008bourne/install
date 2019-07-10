#!/bin/bash
#默认只删除adapter，显示传入1则删除全部,传入2只删除canal

PROGRAM_VERSION="1.1.3"
source ../common.sh
runModel=${1}

if [[ -z "${runModel}" ]] || [[ "${runModel}" == "1" ]]; then 
    PROGRAM_NAME="canal"
    PROGRAM_DIR="${PROGRAM_PATH}/${PROGRAM_NAME}-adapter"
    PROGRAM_FILE="${PROGRAM_NAME}.adapter-${PROGRAM_VERSION}.tar.gz"
    DOWN_URL="https://github.com/alibaba/${PROGRAM_NAME}/releases/download/${PROGRAM_NAME}-${PROGRAM_VERSION}/${PROGRAM_FILE}"


    sudo bash ${PROGRAM_DIR}/bin/stop.sh
    sudo rm -rf ${PROGRAM_DIR}
    if [ ! -d "${PROGRAM_DIR}" ]; then
       sudo mkdir -p "${PROGRAM_DIR}"
       #如果文件已经存在，解压
       if [ ! -f ~/${PROGRAM_FILE} ]; then
   	  #wget -c -P ~ ${DOWN_URL}
	  rclone copy -P hz-jump:hz-jump/${PROGRAM_FILE} ~
       fi
       sudo tar zxvf ~/${PROGRAM_FILE} -C ${PROGRAM_DIR}
    fi
    sudo cp ../${PROGRAM_NAME}/adapter/stop.sh ${PROGRAM_DIR}/bin/stop.sh && sudo chmod 755 ${PROGRAM_DIR}/bin/stop.sh
fi

if [[ "${runModel}" == "1" ]] || [[ "${runModel}" == "2" ]]; then 
    PROGRAM_NAME="canal"
    PROGRAM_DIR="${PROGRAM_PATH}/${PROGRAM_NAME}"
    PROGRAM_FILE="${PROGRAM_NAME}.deployer-${PROGRAM_VERSION}.tar.gz"
    DOWN_URL="https://github.com/alibaba/${PROGRAM_NAME}/releases/download/${PROGRAM_NAME}-${PROGRAM_VERSION}/${PROGRAM_FILE}"
    sudo bash ${PROGRAM_DIR}/bin/stop.sh
    sudo rm -rf ${PROGRAM_DIR}
    if [ ! -d "${PROGRAM_DIR}" ]; then
       sudo mkdir -p "${PROGRAM_DIR}"
       #如果文件已经存在，解压
       if [ ! -f ~/${PROGRAM_FILE} ]; then
   	  #wget -c -P ~ ${DOWN_URL}
	  rclone copy -P hz-jump:hz-jump/${PROGRAM_FILE} ~
       fi
       sudo tar zxvf ~/${PROGRAM_FILE} -C ${PROGRAM_DIR}
    fi
    sudo cp ../${PROGRAM_NAME}/stop.sh ${PROGRAM_DIR}/bin/stop.sh && sudo chmod 755 ${PROGRAM_DIR}/bin/stop.sh

fi
