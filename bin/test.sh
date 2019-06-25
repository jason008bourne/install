#!/bin/bash
configFile="../syn/product-search-template.json"
#configFile="/home/ubuntu/initstart/product_search.json"
bc='{"status":"true","last":9000}'
jsonConfig=$(echo ${bc} | jq -r '.' ) 
echo ${jsonConfig}
qq=100
jsonConfig=$(echo ${bc} | jq -r ".status |= true" | jq -r ".last |= ${qq}" ) 
echo ${jsonConfig}


