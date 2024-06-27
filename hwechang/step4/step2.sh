#!/bin/bash

# DB 정보 가져오기
source /home/hwet/datalake/db_config.sh

# 파라미터 가져오기
ticker_file=$1
HOST=$2
current_time=$3

# 파일에서 각 줄을 읽어와서 처리
while IFS= read -r ticker || [[ -n "$ticker" ]]; do
    # Job 시작 시간 기록
    job_start_time=$(date +'%Y-%m-%d %H:%M:%S')
    
    # csv_result 설정
    csv_result=$(python ./stock_downloader.py "$previous_date" "$ticker")

    # Job 종료 시간 기록
    job_end_time=$(date +'%Y-%m-%d %H:%M:%S')

    # 시작 시간과 끝 시간의 차이를 초 단위로 계산
    elapsed_time=$(($(date -d "$job_end_time" +%s) - $(date -d "$job_start_time" +%s)))

    # 파일 경로 설정
    csv_file="/home/hwet/datalake/csv/$(date +'%Y-%m-%d')/stock_${ticker}_$(date +'%Y-%m-%d').csv"

    # 파일 크기 계산
    if [ -f "$csv_file" ]; then
        filesize=$(stat -c%s "$csv_file")
    else
        filesize=0
    fi
    
    # csv 반환값에 따라 log 설정 (STEP2)
    if [ "$csv_result" == "file_already_exist" ]; then
        psql -h "$DB_HOST" -p "$DB_PORT" -d "$DB_NAME" -U "$DB_USER" << EOF
INSERT INTO etl_logs (log_type, host, ticker, step, data_rows, status, message, from_time, to_time, start_time, end_time, elapsed_time, filesize)
VALUES ('0', '$HOST', '$ticker', 'CSV', 0, 'warning', 'file_already_exist', '${previous_date} 00:00:00', '$(date +'%Y-%m-%d') 00:00:00', '$job_start_time', '$job_end_time', '$elapsed_time', $filesize);
EOF
    elif [ "$csv_result" == "no_data" ]; then
        psql -h "$DB_HOST" -p "$DB_PORT" -d "$DB_NAME" -U "$DB_USER" << EOF
INSERT INTO etl_logs (log_type, host, ticker, step, data_rows, status, message, from_time, to_time, start_time, end_time, elapsed_time, filesize)
VALUES ('0', '$HOST', '$ticker', 'CSV', 0, 'failed', 'no_data', '${previous_date} 00:00:00', '$(date +'%Y-%m-%d') 00:00:00', '$job_start_time', '$job_end_time', '$elapsed_time', $filesize);
EOF
    else
        psql -h "$DB_HOST" -p "$DB_PORT" -d "$DB_NAME" -U "$DB_USER" << EOF
INSERT INTO etl_logs (log_type, host, ticker, step, data_rows, status, message, from_time, to_time, start_time, end_time, elapsed_time, filesize)
VALUES ('0', '$HOST', '$ticker', 'CSV', '$csv_result', 'success', 'save', '${previous_date} 00:00:00', '$(date +'%Y-%m-%d') 00:00:00', '$job_start_time', '$job_end_time', '$elapsed_time', $filesize);
EOF
    fi
done < "$ticker_file"
