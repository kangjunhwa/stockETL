#!/bin/bash

####################################
### csv 파일을 temp table에 저장 ###
####################################

# 정보 가져오기
HOST="$1"
BASE_DIR="$2"

IFS=',' read -r -a ticker_array <<< "$TICKERS"

# 파일에서 각 줄을 읽어와서 처리
for ticker in "${ticker_array[@]}"; do

    # 시작 시간 기록
    job_start_time=$(date +'%Y-%m-%d %H:%M:%S')

    # CSV 파일 경로 설정
    csv_file="$BASE_DIR/csv/$(date +'%Y-%m-%d')/stock_${ticker}.csv"

    # 파일 크기 계산
    if [ -f "$csv_file" ]; then
        filesize=$(stat -c%s "$csv_file")
    else
        filesize=0
    fi

    # pgfutter를 사용하여 CSV 데이터 삽입
    pgfutter --host "$DB_HOST" --port "$DB_PORT" --db "$DB_NAME" --schema "$DB_SCHEMA" --user "$DB_USER" --pass "$DB_PASS" --table "$DB_TABLE_TEMP" csv "$csv_file"

    # pgfutter의 종료 코드 확인
    pgfutter_status=$?

    # 완료 시간 기록
    job_end_time=$(date +'%Y-%m-%d %H:%M:%S')

    # 시작 시간과 끝 시간의 차이를 초 단위로 계산
    elapsed_time=$(( $(date -d "$job_end_time" +%s) - $(date -d "$job_start_time" +%s) ))

    # 삽입 완료 후 성공 또는 실패에 따라 로그 기록
    if [ $pgfutter_status -eq 0 ]; then
        echo "CSV data inserted successfully for ticker: $ticker"
        # 성공적으로 데이터 삽입한 경우, 로그 기록
        psql -h "$DB_HOST" -p "$DB_PORT" -d "$DB_NAME" -U "$DB_USER" << EOF
INSERT INTO etl_logs (log_type, host, ticker, step, data_rows, status, message, from_time, to_time, start_time, end_time, elapsed_time, filesize)
VALUES ('0', '$HOST', '$ticker', 'TEMP', 0, 'success', 'inserted into temp', '$(date +'%Y-%m-%d') 00:00:00', '$(date -d "$(date +'%Y-%m-%d') +1 day" +'%Y-%m-%d 00:00:00')', '$job_start_time', '$job_end_time', '$elapsed_time', '$filesize');
EOF
    else
        echo "Failed to insert CSV data for ticker: $ticker"
        # 데이터 삽입 실패 시, 에러 메시지 로그 기록
        psql -h "$DB_HOST" -p "$DB_PORT" -d "$DB_NAME" -U "$DB_USER" << EOF
INSERT INTO etl_logs (log_type, host, ticker, step, data_rows, status, message, from_time, to_time, start_time, end_time, elapsed_time, filesize)
VALUES ('0', '$HOST', '$ticker', 'TEMP', 0, 'failed', 'insert failed', '$(date +'%Y-%m-%d') 00:00:00', '$(date -d "$(date +'%Y-%m-%d') +1 day" +'%Y-%m-%d 00:00:00')', '$job_start_time', '$job_end_time', '$elapsed_time', '$filesize');
EOF
    fi

done
