#!/bin/bash
###################
## 전체 파일 실행##
###################

# 기본경로 지정
BASE_DIR="$HOME/stockETL/final"

# DB 정보 및 ticker 정보 가져오기
source "$BASE_DIR/setup.sh"

# 사용자 정보(Log에 찍기위함)
HOST=$(whoami)

# Step 1: 휴장일 확인 및 로그 기록
source "$BASE_DIR/step1.sh" "$HOST" "$BASE_DIR"

# Step 2: 각 티커에 대해 데이터 다운로드 및 로그 기록
sleep 1
"$BASE_DIR/step2.sh" "$HOST" "$BASE_DIR"

# Step 3: CSV 데이터 삽입 및 로그 기록
sleep 1
"$BASE_DIR/step3.sh" "$HOST" "$BASE_DIR"

# Step 4 : 임시테이블에서 실제테이블로 데이터 이동
sleep 1
"$BASE_DIR/step4.sh" "$HOST" "$BASE_DIR"

# Step 5 : 이메일 전송 (이후 조건에 따라 전송)
sleep 1
"$BASE_DIR/step5.sh" "$HOST"
