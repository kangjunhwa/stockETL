#!/bin/bash

#####################
### csv 파일 저장 ###
#####################

# 파라미터 가져오기
HOST=$1
BASE_DIR=$2 
PERCENTAGE=5

# TICKERS 정보를 배열로 변환
IFS=',' read -r -a ticker_array <<< "$TICKERS"

today=$(date +'%Y-%m-%d')
yesterday=$(date -d "$today -1 day" +'%Y-%m-%d')

# 변동이 발생한 티커 정보를 저장할 파일
output_file="$BASE_DIR/stock_changes.txt"
> "$output_file"

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
    csv_file="$BASE_DIR/csv/$today/stock_${ticker}.csv"

    # 파일 크기 계산 및 csv 파일 읽기
    if [ -f "$csv_file" ]; then
        filesize=$(stat -c%s "$csv_file")
        current_close=$(awk -F',' 'NR==2 {print $5}' "$csv_file")
	
		echo "현재 종가 $current_close"

        # 이전 종가를 DB에서 가져오기
		previous_close=$(psql -h "$DB_HOST" -p "$DB_PORT" -d "$DB_NAME" -U "$DB_USER" -t -c "SELECT close FROM stock WHERE ticker='$ticker' AND date < '$yesterday' ORDER BY date DESC LIMIT 1" | xargs)
        echo "이전 종가 $previous_close"

        if [ -n "$previous_close" ]; then
            # 변동률 계산
            change=$(echo "scale=2; (($current_close - $previous_close) / $previous_close) * 100" | bc)

            # 변동률이 ±PERCENTAGE를 초과하는지 확인
            if (( $(echo "$change > $PERCENTAGE" | bc -l) || $(echo "$change < -$PERCENTAGE" | bc -l) )); then
                echo -e "Ticker: $ticker\nPrevious Close: $previous_close\nCurrent Close: $current_close\nChange: $change%" >> "$output_file"
            fi
        fi
    else
        filesize=0
    fi
    
    # csv 반환값에 따라 log 설정 (STEP2)
    if [ "$csv_result" == "file_already_exist" ]; then
        psql -h "$DB_HOST" -p "$DB_PORT" -d "$DB_NAME" -U "$DB_USER" << EOF
INSERT INTO etl_logs (log_type, host, ticker, step, data_rows, status, message, from_time, to_time, start_time, end_time, elapsed_time, filesize)
VALUES ('0', '$HOST', '$ticker', 'CSV', 0, 'warning', 'file_already_exist', '$today 00:00:00', '$(date -d "$today +1 day" +'%Y-%m-%d 00:00:00')', '$job_start_time', '$job_end_time', '$elapsed_time', $filesize);
EOF
    elif [ "$csv_result" == "no_data" ]; then
        psql -h "$DB_HOST" -p "$DB_PORT" -d "$DB_NAME" -U "$DB_USER" << EOF
INSERT INTO etl_logs (log_type, host, ticker, step, data_rows, status, message, from_time, to_time, start_time, end_time, elapsed_time, filesize)
VALUES ('0', '$HOST', '$ticker', 'CSV', 0, 'failed', 'no_data', '$today 00:00:00', '$(date -d "$today +1 day" +'%Y-%m-%d 00:00:00')', '$job_start_time', '$job_end_time', '$elapsed_time', $filesize);
EOF
    else
        psql -h "$DB_HOST" -p "$DB_PORT" -d "$DB_NAME" -U "$DB_USER" << EOF
INSERT INTO etl_logs (log_type, host, ticker, step, data_rows, status, message, from_time, to_time, start_time, end_time, elapsed_time, filesize)
VALUES ('0', '$HOST', '$ticker', 'CSV', '$csv_result', 'success', 'save', '$today 00:00:00', '$(date -d "$today +1 day" +'%Y-%m-%d 00:00:00')', '$job_start_time', '$job_end_time', '$elapsed_time', $filesize);
EOF
    fi
done

