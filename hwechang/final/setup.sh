#!/bin/bash

######################################
#### properties_file에서 변수 읽기 ###
######################################

while IFS='=' read -r key value; do 
	# 빈줄과 주석 무시
	if [[ ! -z "$key" && ! "$key" =~ ^# ]]; then
		# 공백 제거후 환경 변수로 설정
        	export "$key=$(echo $value | sed 's/^"//;s/"$//')"

	fi 
done < stock.properties

