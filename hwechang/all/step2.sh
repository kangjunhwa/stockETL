#!/bin/bash

#####################
### csv 파일 저장 ###
#####################

# 파라미터 가져오기
HOST=$1
BASE_DIR=$2 

# 어떤 정보들이 저장되었는지, 이후에 모니터링에 사용 가능할듯 
csv_summary=""

# , 로 구분되어있는 TICKERS 를 배열화
IFS=',' read -r -a ticker_array <<< "$TICKERS"

# 파일에서 각 줄을 읽어와서 처리
for ticker in "${ticker_array[@]}"; do

    	# Job 시작 시간 기록
		job_start_time=$(date +'%Y-%m-%d %H:%M:%S')
    
    	# csv_result 설정
    	csv_result=$(python "$BASE_DIR/stock_downloader.py" "$ticker" "$BASE_DIR")

    	# Job 종료 시간 기록
    	job_end_time=$(date +'%Y-%m-%d %H:%M:%S')

    	# 시작 시간과 끝 시간의 차이를 초 단위로 계산
    	elapsed_time=$(($(date -d "$job_end_time" +%s) - $(date -d "$job_start_time" +%s)))

    	# 파일 경로 설정
    	csv_file="$BASE_DIR/csv/$(date +'%Y-%m-%d')/stock_${ticker}.csv"

    	# 파일 크기 계산
    	if [ -f "$csv_file" ]; then

        	filesize=$(stat -c%s "$csv_file")
	
			csv_content=$(cat "$csv_file")
        	csv_summary+="\nTicker: $ticker\nSize: $filesize bytes\n$csv_content\n"	

    	else
			# 파일이 존재하지 않으면 파일크기 0 
        	filesize=0
    	fi
    
    	# csv 반환값에 따라 log 설정 (STEP2)
    	if [ "$csv_result" == "file_already_exist" ]; then
        	psql -h "$DB_HOST" -p "$DB_PORT" -d "$DB_NAME" -U "$DB_USER" << EOF
INSERT INTO etl_logs (log_type, host, ticker, step, data_rows, status, message, from_time, to_time, start_time, end_time, elapsed_time, filesize)
VALUES ('0', '$HOST', '$ticker', 'CSV', 0, 'warning', 'file_already_exist', '$(date +'%Y-%m-%d') 00:00:00', '$(date -d "$(date +'%Y-%m-%d') +1 day" +'%Y-%m-%d 00:00:00')', '$job_start_time', '$job_end_time', '$elapsed_time', $filesize);
EOF
    	elif [ "$csv_result" == "no_data" ]; then
        	psql -h "$DB_HOST" -p "$DB_PORT" -d "$DB_NAME" -U "$DB_USER" << EOF
INSERT INTO etl_logs (log_type, host, ticker, step, data_rows, status, message, from_time, to_time, start_time, end_time, elapsed_time, filesize)
VALUES ('0', '$HOST', '$ticker', 'CSV', 0, 'failed', 'no_data', '$(date +'%Y-%m-%d') 00:00:00', '$(date -d "$(date +'%Y-%m-%d') +1 day" +'%Y-%m-%d 00:00:00')', '$job_start_time', '$job_end_time', '$elapsed_time', $filesize);
EOF
    	else
        	psql -h "$DB_HOST" -p "$DB_PORT" -d "$DB_NAME" -U "$DB_USER" << EOF
INSERT INTO etl_logs (log_type, host, ticker, step, data_rows, status, message, from_time, to_time, start_time, end_time, elapsed_time, filesize)
VALUES ('0', '$HOST', '$ticker', 'CSV', '$csv_result', 'success', 'save', '$(date +'%Y-%m-%d') 00:00:00', '$(date -d "$(date +'%Y-%m-%d') +1 day" +'%Y-%m-%d 00:00:00')', '$job_start_time', '$job_end_time', '$elapsed_time', $filesize);
EOF

    	fi

	

done 

# csv 파일 내용 파일에 저장
echo -e "$csv_summary" > ./csv_summary.txt

