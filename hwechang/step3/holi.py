import holidays
from datetime import datetime, timedelta
import sys

def main():
    if len(sys.argv) < 2:
        print("Usage: python example.py <year>")
        return
    
    year = int(sys.argv[1])
    
    # 현재 날짜 가져오기
    today = datetime.now().date()

    # 해당 연도의 미국 공휴일 가져오기
    us_holidays = holidays.US(years=year)

    # 오늘이 공휴일인지 확인
    is_today_holiday = today in us_holidays

    if is_today_holiday:
        # 공휴일이면 0을 출력하고 종료
        print(0)
    else:
        # 공휴일 및 주말이 아닌 이전 날짜 찾기
        previous_date = today - timedelta(days=1)
        while previous_date in us_holidays or previous_date.weekday() >= 5:  # 5는 토요일, 6은 일요일
            previous_date -= timedelta(days=1)

        # 이전 날짜 출력
        print(previous_date)

if __name__ == "__main__":
    main()
