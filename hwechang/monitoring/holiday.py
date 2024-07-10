import holidays
from datetime import datetime, timedelta
import sys

def main():
    
    # 현재 날짜 가져오기
    today = datetime.now().date()

    # 해당 연도의 미국 공휴일 가져오기
    year = today.year
    us_holidays = holidays.US(years=year)

    # 오늘이 공휴일인지 확인
    is_today_holiday = today in us_holidays

    if is_today_holiday:
        # 공휴일이면 0을 출력하고 종료
        print(0)

if __name__ == "__main__":
    main()
