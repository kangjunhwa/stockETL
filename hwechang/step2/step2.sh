#!/bin/bash

# DB 정보 가져오기
source /home/hwet/datalake/db_config.sh

# 파라미터 가져오기
ticker_file=$1
HOST=$2
current_time=$3

# 파일에서 각 줄을 읽어와서 처리
while IFS= read -r ticker || [[ -n "$ticker" ]]; do
    echo "step2 $previous_date"
      
    # file_already_exist, no_data, (Row_Count) 반환
    csv_result=$(python ./stock_downloader.py "$previous_date" "$ticker")
    
    # 현재 시간을 csv_job_time 변수에 저장
    csv_job_time=$(date +'%Y-%m-%d %H:%M:%S')
    
    # csv 반환값에 따라 log 설정 (STEP2)
    if [ "$csv_result" == "file_already_exist" ]; then
        psql -h "$DB_HOST" -p "$DB_PORT" -d "$DB_NAME" -U "$DB_USER" << EOF
INSERT INTO etl_logs (log_type, host, ticker, step, data_rows, status, message, from_time, to_time, start_time, end_time, elapsed_time, filesize)
VALUES ('0', '$HOST', '$ticker', 'CSV', 0, 'warning', 'file_already_exist', '${previous_date} 00:00:00', '$(date +'%Y-%m-%d') 00:00:00', '$csv_job_time', '$csv_job_time', 0, 0);
EOF
    elif [ "$csv_result" == "no_data" ]; then
        psql -h "$DB_HOST" -p "$DB_PORT" -d "$DB_NAME" -U "$DB_USER" << EOF
INSERT INTO etl_logs (log_type, host, ticker, step, data_rows, status, message, from_time, to_time, start_time, end_time, elapsed_time, filesize)
VALUES ('0', '$HOST', '$ticker', 'CSV', 0, 'failed', 'no_data', '${previous_date} 00:00:00', '$(date +'%Y-%m-%d') 00:00:00', '$csv_job_time', '$csv_job_time', 0, 0);
EOF
    else
        psql -h "$DB_HOST" -p "$DB_PORT" -d "$DB_NAME" -U "$DB_USER" << EOF
INSERT INTO etl_logs (log_type, host, ticker, step, data_rows, status, message, from_time, to_time, start_time, end_time, elapsed_time, filesize)
VALUES ('0', '$HOST', '$ticker', 'CSV', '$csv_result', 'success', 'save', '${previous_date} 00:00:00', '$(date +'%Y-%m-%d') 00:00:00', '$csv_job_time', '$csv_job_time', 0, 0);
EOF
    fi
done < "$ticker_file"
