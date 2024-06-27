#!/bin/bash

# DB 정보 가져오기
source /home/hwet/datalake/db_config.sh

# 사용자 정보(Log에 찍기위함)
HOST=$(whoami)

# 현재 시간
current_time=$(date +'%Y-%m-%d %H:%M:%S')

# 시작 시간 기록
job_start_time=$(date +'%Y-%m-%d %H:%M:%S')

# SQL 파일 실행
psql -h "$DB_HOST" -p "$DB_PORT" -d "$DB_NAME" -U "$DB_USER" -f /home/hwet/datalake/load_data.sql

# 완료 시간 기록
job_end_time=$(date +'%Y-%m-%d %H:%M:%S')

# 시작 시간과 끝 시간의 차이를 초 단위로 계산
elapsed_time=$(($(date -d "$job_end_time" +%s) - $(date -d "$job_start_time" +%s)))

# 로그 기록
psql -h "$DB_HOST" -p "$DB_PORT" -d "$DB_NAME" -U "$DB_USER" << EOF
INSERT INTO etl_logs (log_type, host, ticker, step, data_rows, status, message, from_time, to_time, start_time, end_time, elapsed_time, filesize)
VALUES ('0', '$HOST', 'ALL', 'LOAD', 0, 'success', 'Data loaded from temp to final table', '${previous_date} 00:00:00', '$(date +'%Y-%m-%d') 00:00:00', '$job_start_time', '$job_end_time', $elapsed_time, 0);
EOF
