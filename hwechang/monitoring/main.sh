#!/bin/bash
###################
## 전체 파일 실행##
###################


# 현재 스크립트가 실행된 디렉토리 경로 가져오기
CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# 기본 경로 설정 (현재 스크립트가 위치한 디렉토리 기준으로 설정)
BASE_DIR="$CURRENT_DIR"



# DB 정보 및 ticker 정보 가져오기
source "$BASE_DIR/setup.sh"

# 현재 연도 구하기
current_year=$(date +'%Y')

# 사용자 정보(Log에 찍기위함)
HOST=$(whoami)

# 변동 % 설정
PERCENTAGE=5


# Step 1: 휴장일 확인 및 로그 기록
source "$BASE_DIR/step1.sh" "$HOST" "$BASE_DIR"

# Step 2: 각 티커에 대해 데이터 다운로드 및 로그 기록
sleep 1
"$BASE_DIR/step2.sh" "$HOST" "$BASE_DIR" "PERCENTAGE"

# Step 3: CSV 데이터 삽입 및 로그 기록
sleep 1
"$BASE_DIR/step3.sh" "$HOST" "$BASE_DIR"

# Step 4 : 임시테이블에서 실제테이블로 데이터 이동
sleep 1
"$BASE_DIR/step4.sh" "$HOST" "$BASE_DIR"

# Step 5 : 이메일 전송 (이후 조건에 따라 전송)
sleep 1
output_file="$BASE_DIR/stock_changes.txt"
if [ -s "$output_file" ]; then
    "$BASE_DIR/step5.sh" "$HOST" "$output_file"
	sleep 1
	rm "$output_file"
else
    "$BASE_DIR/step5_x.sh" "$HOST"
fi

