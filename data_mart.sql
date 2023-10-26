-- 1. Data Cleaning
--CREATE TABLE IF NOT EXISTS clean_weekly_sales as 
SELECT
    week_date::DATE
    ,DATE_PART('week',week_date::DATE) as week_number
    ,DATE_PART('month', week_date::DATE) as month_number
    ,DATE_PART('year', week_date::DATE) as calendar_year
    ,region
    ,platform
    ,segment
    ,CASE WHEN RIGHT(segment, 1) = '1' THEN 'Young Adults'
          WHEN RIGHT(segment, 1) = '2' THEN 'Middle Aged'
          WHEN RIGHT(segment, 1) = '3' OR RIGHT(segment, 1) = '4' THEN 'Retirees'
          END AS age_band
FROM data_mart.weekly_sales
