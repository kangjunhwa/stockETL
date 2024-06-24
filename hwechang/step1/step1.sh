#!/bin/bash

# PostgreSQL 서버 정보 설정(파일을 불러와서 실행할 예쩡)
DB_HOST="localhost"
DB_PORT="5432"
DB_NAME="stockdb"
DB_USER="stockuser"
DB_PASSWORD="stockuser"

#현재 연도 구하기
current_year=$(date +'%Y')

# python execute
result=$(python ./holi.py "$current_year")

# 사용자 정보
HOST=$(whoami)
	
if [ "$result" == "0" ]; then
	echo "fail"
	psql -h $DB_HOST -p $DB_PORT -d $DB_NAME -U $DB_USER << EOF
    INSERT INTO etl_logs (log_type, host, ticker, step, data_rows, status, message, from_time, to_time, start_time, end_time, elapsed_time, filesize)
    VALUES ('0', '$HOST', 'ALL', 'START', 0, 'fail', 'market closed', '$(date +'%Y-%m-%d') 00:00:00', '$(date +'%Y-%m-%d') 00:00:00', '$current_time', '$current_time', 0, 0);
EOF

echo "START fail"
else 
	# python 결과값 이전날짜 가져오기 
	previous_date="$result"
	
	# 현재시간 
	current_time=$(date +'%Y-%m-%d %H:%M:%S')
	

	# 데이터베이스에 접속하여 SQL 쿼리 실행 (STEP1 로그)
	psql -h $DB_HOST -p $DB_PORT -d $DB_NAME -U $DB_USER << EOF
    INSERT INTO etl_logs (log_type, host, ticker, step, data_rows, status, message, from_time, to_time, start_time, end_time, elapsed_time, filesize)
    VALUES ('0', '$HOST', 'ALL', 'START', 0, 'success', 'market open', '${previous_date} 00:00:00', '$(date +'%Y-%m-%d') 00:00:00', '$current_time', '$current_time', 0, 0);
EOF

	echo "START success"

fi