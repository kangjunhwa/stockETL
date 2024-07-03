import datetime
import yfinance as yf
import os
import sys
import time
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler
from threading import Timer
import pandas as pd

class CsvFileCreatedHandler(FileSystemEventHandler):
    def __init__(self, expected_file, observer, timer):
        self.expected_file = expected_file  # 생성될 것으로 예상되는 파일의 경로
        self.observer = observer  # 감시자 객체
        self.timer = timer  # 타이머 객체

    def on_created(self, event):
        if event.is_directory:
            return
        if event.src_path == self.expected_file and os.path.exists(self.expected_file):
            # 파일이 생성되었을 때, 감시 중지 및 타이머 취소
            self.observer.stop()
            self.timer.cancel()

def stop_observer(observer):
    print("타임아웃 발생: 파일 생성 감시 종료")
    observer.stop()  # 타임아웃 발생 시 감시 중지

# yfinance는 최소 5분 단위의 주식 정보를 제공하는듯함. 우선 1일 단위 고정으로 진행 
# 특정 이유로 인해 다운로드가 실패할 경우를 대비하여 재시도 코드 입력
def download_stock_data(ticker, start, end, interval='1d', max_retries=3, retry_interval=10):
    attempt = 0
    while attempt < max_retries:
        try:
            # 주식 데이터를 다운로드
            df = yf.download(ticker, start=start, end=end, progress=False, interval=interval)
            df['ticker'] = ticker  # 데이터프레임에 티커 추가
            return df
        except Exception as e:
            print(f"Error downloading data for {ticker}: {e}")
            attempt += 1
            if attempt < max_retries:
                print(f"Retry attempt {attempt} in {retry_interval} seconds...")
                time.sleep(retry_interval)

    # 모든 재시도 실패 시 빈 데이터프레임 반환
    return pd.DataFrame()

def process_ticker(ticker, csv_dir):
    today = datetime.datetime.now().strftime("%Y-%m-%d")  # 오늘 날짜 설정

    # 날짜별 디렉토리 생성
    date_dir = os.path.join(csv_dir, f"csv/{today}")
    os.makedirs(date_dir, exist_ok=True)

    # 생성될 파일명 지정
    file_name = os.path.join(date_dir, f"stock_{ticker}.csv")

    # 이미 파일이 존재하는지 확인
    if os.path.exists(file_name):
        print("file_already_exist")
        return "file_already_exist"

    observer = Observer()
    timer = Timer(20, stop_observer, [observer])  # 타이머 생성
    event_handler = CsvFileCreatedHandler(file_name, observer, timer)
    observer.schedule(event_handler, path=date_dir, recursive=False)
    observer.start()
    timer.start()  # 타이머 시작

    try:
        df = download_stock_data(ticker, today, today, interval='1d')

        if not df.empty:
            df.to_csv(file_name)
            num_rows = len(df)  # 데이터프레임의 행 수
            print(num_rows)
            return num_rows
        else:
            print("no_data")
            return "no_data"

        observer.join()
    except KeyboardInterrupt:
        observer.stop()
    observer.join()

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python stock_downloader.py <ticker> <csv_dir>")
        sys.exit(1)
    
    ticker = sys.argv[1]
    csv_dir = sys.argv[2]
    process_ticker(ticker, csv_dir)

