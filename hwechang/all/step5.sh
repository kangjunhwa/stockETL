#!/bin/bash

###################
### 이메일 전송 ###
###################

HOST=$1

csv_summary=$(cat ./csv_summary.txt)

# 수신자 이메일 주소
recipient="hwechang.jeong@data-dynamics.io"

# 이메일 제목
subject="Stock Data ETL Process Completed"

# 이메일 본문 내용
body="The ETL process has been completed successfully.$csv_summary"

echo "$csv_summary"

# 시작 시간 기록
job_start_time=$(date +'%Y-%m-%d %H:%M:%S')

# 이메일 전송
# body="The ETL process has been completed successfully.\n\nSummary of CSV files processed:\n\n$csv_summary"
sendmail $recipient << EOF
Subject: $subject
$body
EOF

# sendmail의 종료 상태를 확인하여 이메일이 성공적으로 전송되었는지 확인
if [ $? -eq 0 ]; then
    status="success"
    message="Success to send email"
else
    status="failed"
    message="Failed to send email"
fi


# csv파일 정보 삭제
rm ./csv_summary.txt

# 완료 시간 기록
job_end_time=$(date +'%Y-%m-%d %H:%M:%S')

# 시작 시간과 끝 시간의 차이를 초 단위로 계산
elapsed_time=$(($(date -d "$job_end_time" +%s) - $(date -d "$job_start_time" +%s)))

# 로그 기록
psql -h "$DB_HOST" -p "$DB_PORT" -d "$DB_NAME" -U "$DB_USER" << EOF
INSERT INTO etl_logs (log_type, host, ticker, step, data_rows, status, message, from_time, to_time, start_time, end_time, elapsed_time, filesize)
VALUES ('0', '$HOST', 'ALL', 'SENDMAIL', 0, '$status', '$message', '$(date +'%Y-%m-%d') 00:00:00', '$(date -d "$(date +'%Y-%m-%d') +1 day" +'%Y-%m-%d 00:00:00')', '$job_start_time', '$job_end_time', '$elapsed_time', 0);
EOF

if [ "$status" == "success" ]; then
    echo "Email sent to $recipient with subject: $subject"
else
    echo "Failed to send email to $recipient"
fi

