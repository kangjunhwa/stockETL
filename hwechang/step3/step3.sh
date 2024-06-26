#!/bin/bash

# DB 정보 가져오기
source /home/hwet/datalake/db_config.sh

# 파라미터 가져오기
ticker_file=$1
current_time=$2

# 현재 연도 구하기
current_year=$(date +'%Y')

# 사용자 정보(Log에 찍기위함)
HOST=$(whoami)

# 파일에서 각 줄을 읽어와서 처리
while IFS= read -r ticker || [[ -n "$ticker" ]]; do
    # CSV 파일 경로 설정
    csv_file="/home/hwet/datalake/csv/$(date +'%Y-%m-%d')/stock_${ticker}_$(date +'%Y-%m-%d').csv"

    # pgfutter를 사용하여 CSV 데이터 삽입
    pgfutter --host "$DB_HOST" --port "5432" --db "$DB_NAME" --schema "public" --user "$DB_USER" --pass "$DB_PASS" --table "$DB_TABLE_TEMP" csv "$csv_file"

    # 삽입 완료 후 성공 또는 실패에 따라 로그 기록
    if [ $? -eq 0 ]; then
        echo "CSV data inserted successfully for ticker: $ticker"
        # 성공적으로 데이터 삽입한 경우, 로그 기록
        psql -h "$DB_HOST" -p "$DB_PORT" -d "$DB_NAME" -U "$DB_USER" << EOF
INSERT INTO etl_logs (log_type, host, ticker, step, data_rows, status, message, from_time, to_time, start_time, end_time, elapsed_time, filesize)
VALUES ('0', '$HOST', '$ticker', 'TEMP', 0, 'success', 'inserted into temp', '${previous_date} 00:00:00', '$(date +'%Y-%m-%d') 00:00:00', '$current_time', '$current_time', 0, 0);
EOF
    else
        echo "Failed to insert CSV data for ticker: $ticker"
        # 데이터 삽입 실패 시, 에러 메시지 로그 기록
        psql -h "$DB_HOST" -p "$DB_PORT" -d "$DB_NAME" -U "$DB_USER" << EOF
INSERT INTO etl_logs (log_type, host, ticker, step, data_rows, status, message, from_time, to_time, start_time, end_time, elapsed_time, filesize)
VALUES ('0', '$HOST', '$ticker', 'TEMP', 0, 'failed', 'insert failed', '${previous_date} 00:00:00', '$(date +'%Y-%m-%d') 00:00:00', '$current_time', '$current_time', 0, 0);
EOF
    fi

done < "$ticker_file"

