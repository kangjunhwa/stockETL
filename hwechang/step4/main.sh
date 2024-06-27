#!/bin/bash

# DB 정보 및 ticker 정보 가져오기
source /home/hwet/datalake/db_config.sh
source /home/hwet/datalake/ticker.info

# 현재 연도 구하기
current_year=$(date +'%Y')

# 사용자 정보(Log에 찍기위함)
HOST=$(whoami)

# ticker.info 파일 
ticker_file="/home/hwet/datalake/ticker.info"

# 현재시간 
current_time=$(date +'%Y-%m-%d %H:%M:%S')

# Step 1: 휴장일 확인 및 로그 기록
source ./step1.sh "$current_year" "$HOST" "$current_time"

# Step 2: 각 티커에 대해 데이터 다운로드 및 로그 기록
sleep 1
./step2.sh "$ticker_file" "$HOST" "$current_time"

# Step 3: CSV 데이터 삽입 및 로그 기록
sleep 1
./step3.sh "$ticker_file" "$current_time"

# Step 4 : 임시테이블에서 실제테이블로 데이터 이동
sleep 1
./step4.sh

