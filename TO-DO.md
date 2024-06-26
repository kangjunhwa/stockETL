아래에 완료 여부를 입력하세요.
1. linux 설치
   
   이병훈 : 완료
   
   정회창 : 완료
   
   김이화 : 완료
   
3. postgresql 설치
   
   이병훈 : 완료
   
   정회창 : 완료
   
   김이화 : 완료
   
5. python 설치
   
   이병훈 :
   
   정회창 : 완료
   
   김이화 :
   
7. yfinance 설치
   
   이병훈 :
   
   정회창 : 완료
   
   김이화 :
   
9. pgfutter 설치
    
   이병훈 :

   정회창 : 완료
   
   김이화 :    
   
12. csv 파일 생성
    
   이병훈 :
   
   정회창 : 완료
   
   김이화 :
   
14. db 및 스키마 생성
    
   이병훈 : 
   
   정회창 : 
   
   김이화 :
16. pgfutter를 이용한 임시테이블 생성

   이병훈 : 
   
   정회창 : 완료
   
   김이화 :   

2024-06-25 :
1. readProperties.sh
   
	stock.properties파일을 읽어서 변수를 선언

3. stockInfo.sh
   
   readProperties.sh 파일을 호출해줄 shell 프로그램
   
   holiday_check function을 만드세요.
   
   오늘 날짜가 휴장일이면 exit 하도록 구현하세요.
   
   HOLIDAY 변수의 (,)로 분리된 날짜를 tr 함수를 사용 하여 (,)를 \n 줄바꿈 문자로 치환하여 LOOP문을 실행해야 합니다.
   
   TICKERS 변수의 (,)로 분리된 날짜를 tr 함수를 사용 하여 (,)를 \n 줄바꿈 문자로 치환하여 python 프로그램 호출
   
   python 프로그램 호출 다음 단계에 pgfutter를 이용하여 임시테이블 생성
   
5. csv_gen.py
   TICKERS 정보를 파라메터를 받도록 설계한다.
   \n 줄바꿈 문자를 이용하여 loop를 돌려서 yfinance를 호출한다.
   
   
   TICKERS_LINES=$(echo $TICKERS | tr "," "\n")

	for TICKER in $TICKERS_LINES
	do
		echo "[$TICKER]"
	done

