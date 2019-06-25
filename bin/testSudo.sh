#!/bin/bash
bc=ddddddd
JVM_MEMORY=3
sudo -u root -E /d/wps/chinaqq的云文档/notebook/shell/hadoop/bin/test.sh
sudo -u root "ZOO_LOG_DIR=-Xms$[JVM_MEMORY*1024]m -Xmx$[JVM_MEMORY*1024]m" "HOME=${bc}" /d/wps/chinaqq的云文档/notebook/shell/hadoop/bin/test.sh
