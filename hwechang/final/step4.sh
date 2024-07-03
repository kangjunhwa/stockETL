#!/bin/bash

##########################################################
### temp table에 있는 정보를 실제 사용할 테이블에 적재 ###
##########################################################

# 파라미터 설정
HOST=$1
BASE_DIR=$2

# 시작 시간 기록
job_start_time=$(date +'%Y-%m-%d %H:%M:%S')

# SQL 파일 실행
psql -h "$DB_HOST" -p "$DB_PORT" -d "$DB_NAME" -U "$DB_USER" -f "$BASE_DIR/load_data.sql"
status=$?

# 완료 시간 기록
job_end_time=$(date +'%Y-%m-%d %H:%M:%S')

# 시작 시간과 끝 시간의 차이를 초 단위로 계산
elapsed_time=$(( $(date -d "$job_end_time" +%s) - $(date -d "$job_start_time" +%s) ))

# 로그 기록
if [ $status -eq 0 ]; then
    psql -h "$DB_HOST" -p "$DB_PORT" -d "$DB_NAME" -U "$DB_USER" << EOF
INSERT INTO etl_logs (log_type, host, ticker, step, data_rows, status, message, from_time, to_time, start_time, end_time, elapsed_time, filesize)
VALUES ('0', '$HOST', 'ALL', 'LOAD', 0, 'success', '임시 테이블에서 최종 테이블로 데이터 로드 성공', '$(date +'%Y-%m-%d') 00:00:00', '$(date -d "$(date +'%Y-%m-%d') +1 day" +'%Y-%m-%d 00:00:00')', '$job_start_time', '$job_end_time', $elapsed_time, 0);
EOF
else
    psql -h "$DB_HOST" -p "$DB_PORT" -d "$DB_NAME" -U "$DB_USER" << EOF
INSERT INTO etl_logs (log_type, host, ticker, step, data_rows, status, message, from_time, to_time, start_time, end_time, elapsed_time, filesize)
VALUES ('0', '$HOST', 'ALL', 'LOAD', 0, 'failed', '임시 테이블에서 최종 테이블로 데이터 로드 실패', '$(date +'%Y-%m-%d') 00:00:00', '$(date -d "$(date +'%Y-%m-%d') +1 day" +'%Y-%m-%d 00:00:00')',  '$job_start_time', '$job_end_time', $elapsed_time, 0);
EOF
fi
