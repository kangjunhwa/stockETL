#!/bin/bash

source /home/hwet/datalake/db_config.sh
source /home/hwet/datalake/ticker.info


#현재 연도 구하기
current_year=$(date +'%Y')

# python execute
is_holiday=$(python ./holi.py "$current_year")

# 사용자 정보
HOST=$(whoami)

#ticker.info 파일 
ticker_file="/home/hwet/datalake/ticker.info"


if [ "$is_holiday" == "0" ]; then
	echo "fail"
	psql -h $DB_HOST -p $DB_PORT -d $DB_NAME -U $DB_USER << EOF
    INSERT INTO etl_logs (log_type, host, ticker, step, data_rows, status, message, from_time, to_time, start_time, end_time, elapsed_time, filesize)
    VALUES ('0', '$HOST', 'ALL', 'START', 0, 'fail', 'market closed', '$(date +'%Y-%m-%d') 00:00:00', '$(date +'%Y-%m-%d') 00:00:00', '$current_time', '$current_time', 0, 0);
EOF

echo "START fail"
else 
	# python 결과값 이전날짜 가져오기 
	previous_date="$is_holiday"
	
	# 현재시간 
	current_time=$(date +'%Y-%m-%d %H:%M:%S')
	

	# 데이터베이스에 접속하여 SQL 쿼리 실행 (STEP1 로그)
	psql -h $DB_HOST -p $DB_PORT -d $DB_NAME -U $DB_USER << EOF
    INSERT INTO etl_logs (log_type, host, ticker, step, data_rows, status, message, from_time, to_time, start_time, end_time, elapsed_time, filesize)
    VALUES ('0', '$HOST', 'ALL', 'START', 0, 'success', 'market open', '${previous_date} 00:00:00', '$(date +'%Y-%m-%d') 00:00:00', '$current_time', '$current_time', 0, 0);
EOF

	echo "START success"

	# 파일에서 각 줄을 읽어와서 처리
	while IFS= read -r ticker || [[ -n "$ticker" ]]; do

    csv_result=$(python ./stock_downloader.py "$previous_date" "$ticker")

    echo "$csv_result"

    csv_job_time=$(date +'%Y-%m-%d %H:%M:%S')  # 현재 시간을 csv_job_time 변수에 저장

    if [ "$csv_result" == "file_already_exist" ]; then
        psql -h $DB_HOST -p $DB_PORT -d $DB_NAME -U $DB_USER << EOF
INSERT INTO etl_logs (log_type, host, ticker, step, data_rows, status, message, from_time, to_time, start_time, end_time, elapsed_time, filesize)
VALUES ('0', '$HOST', '$ticker', 'CSV', 0, 'warning', 'file_already_exist', '${previous_date} 00:00:00', '$(date +'%Y-%m-%d') 00:00:00', '$csv_job_time', '$csv_job_time', 0, 0);
EOF
    elif [ "$csv_result" == "no_data" ]; then
        psql -h $DB_HOST -p $DB_PORT -d $DB_NAME -U $DB_USER << EOF
INSERT INTO etl_logs (log_type, host, ticker, step, data_rows, status, message, from_time, to_time, start_time, end_time, elapsed_time, filesize)
VALUES ('0', '$HOST', '$ticker', 'CSV', 0, 'failed', 'no_data', '${previous_date} 00:00:00', '$(date +'%Y-%m-%d') 00:00:00', '$csv_job_time', '$csv_job_time', 0, 0);
EOF
    else
        psql -h $DB_HOST -p $DB_PORT -d $DB_NAME -U $DB_USER << EOF
INSERT INTO etl_logs (log_type, host, ticker, step, data_rows, status, message, from_time, to_time, start_time, end_time, elapsed_time, filesize)
VALUES ('0', '$HOST', '$ticker', 'CSV', '$csv_result', 'success', 'save', '${previous_date} 00:00:00', '$(date +'%Y-%m-%d') 00:00:00', '$csv_job_time', '$csv_job_time', 0, 0);
EOF
    fi


	done < "$ticker_file"


fi
