#!/bin/bash

##################
### 휴장일 체크###
##################

# 파라미터 가져오기
HOST=$1
BASE_DIR=$2

# 휴장일 확인
is_holiday=$(python "$BASE_DIR/holiday.py")

# 휴장일인지 판별
if [ "$is_holiday" == "0" ]; then
    # 휴장일 (실패 로그)
    psql -h "$DB_HOST" -p "$DB_PORT" -d "$DB_NAME" -U "$DB_USER" << EOF
INSERT INTO etl_logs (log_type, host, ticker, step, data_rows, status, message, from_time, to_time, start_time, end_time, elapsed_time, filesize)
VALUES ('0', '$HOST', 'ALL', 'START', 0, 'fail', 'market closed', '$(date +'%Y-%m-%d') 00:00:00', '$(date -d "+1 day $(date +'%Y-%m-%d')" +'%Y-%m-%d 00:00:00')', '$(date +'%Y-%m-%d %H:%M:%S')', '$(date +'%Y-%m-%d %H:%M:%S')', 0, 0);
EOF

    # echo "START fail"
    exit 1
else
    # 데이터베이스에 접속하여 SQL 쿼리 실행 (STEP1)
    psql -h "$DB_HOST" -p "$DB_PORT" -d "$DB_NAME" -U "$DB_USER" << EOF
INSERT INTO etl_logs (log_type, host, ticker, step, data_rows, status, message, from_time, to_time, start_time, end_time, elapsed_time, filesize)
VALUES ('0', '$HOST', 'ALL', 'START', 0, 'success', 'market open', '$(date +'%Y-%m-%d') 00:00:00', '$(date -d "+1 day $(date +'%Y-%m-%d')" +'%Y-%m-%d 00:00:00')', '$(date +'%Y-%m-%d %H:%M:%S')', '$(date +'%Y-%m-%d %H:%M:%S')', 0, 0);
EOF

    # echo "START success"
fi
