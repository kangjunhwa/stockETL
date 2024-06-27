BEGIN;

-- 임시 테이블에서 실제 테이블로 데이터 적재 (date 형식 변환 포함)
INSERT INTO stock (date, open, high, low, close, adj_close, volume, ticker)
SELECT
    TO_DATE(date, 'YYYY-MM-DD')::DATE,
    open::NUMERIC,
    high::NUMERIC,
    low::NUMERIC,
    close::NUMERIC,
    adj_close::NUMERIC,
    volume::BIGINT,
    ticker::TEXT
FROM stock_temp
ON CONFLICT (date, ticker) DO NOTHING;

-- 임시 테이블 비우기
TRUNCATE stock_temp;

COMMIT;

