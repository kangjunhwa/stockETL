#!/bin/bash

# DB 정보 가져오기
source /home/hwet/datalake/db_config.sh

# 파라미터 가져오기
current_year=$1
HOST=$2
current_time=$3

# 휴장일 확인
is_holiday=$(python ./holi.py "$current_year")

# 휴장일인지 판별
if [ "$is_holiday" == "0" ]; then
    # 휴장일
    psql -h "$DB_HOST" -p "$DB_PORT" -d "$DB_NAME" -U "$DB_USER" << EOF
    INSERT INTO etl_logs (log_type, host, ticker, step, data_rows, status, message, from_time, to_time, start_time, end_time, elapsed_time, filesize)
    VALUES ('0', '$HOST', 'ALL', 'START', 0, 'fail', 'market closed', '$(date +'%Y-%m-%d') 00:00:00', '$(date +'%Y-%m-%d') 00:00:00', '$current_time', '$current_time', 0, 0);
EOF

    # echo "START fail"
    exit 1
else
    # 개장일
    previous_date="$is_holiday"

    # 데이터베이스에 접속하여 SQL 쿼리 실행 (STEP1)
    psql -h "$DB_HOST" -p "$DB_PORT" -d "$DB_NAME" -U "$DB_USER" << EOF
    INSERT INTO etl_logs (log_type, host, ticker, step, data_rows, status, message, from_time, to_time, start_time, end_time, elapsed_time, filesize)
    VALUES ('0', '$HOST', 'ALL', 'START', 0, 'success', 'market open', '${previous_date} 00:00:00', '$(date +'%Y-%m-%d') 00:00:00', '$current_time', '$current_time', 0, 0);
EOF

    # echo "START success"
    # previous_date 변수를 export하여 step2.sh에서 접근할 수 있도록 설정
    export previous_date
fi
