-- 1. Data Cleaning
CREATE TABLE IF NOT EXISTS data_mart.clean_weekly_sales as 
SELECT
    week_date::DATE
    ,DATE_PART('week',week_date::DATE) as week_number
    ,DATE_PART('month', week_date::DATE) as month_number
    ,DATE_PART('year', week_date::DATE) as calendar_year
    ,region
    ,platform
    ,CASE WHEN segment IS NULL OR segment = 'null' THEN 'unknown'
          ELSE segment
          END AS segment
    ,CASE WHEN RIGHT(segment, 1) = '1' THEN 'Young Adults'
          WHEN RIGHT(segment, 1) = '2' THEN 'Middle Aged'
          WHEN RIGHT(segment, 1) = '3' OR RIGHT(segment, 1) = '4' THEN 'Retirees'
          ELSE 'unknown'
          END AS age_band
    ,CASE WHEN LEFT(segment, 1) = 'C' THEN 'Couples'
          WHEN LEFT(segment, 1) = 'F' THEN 'Families'
          ELSE 'unknown'
          END AS demographic
    ,customer_type
    ,transactions
    ,sales
    ,sales/transactions as avg_transaction
FROM data_mart.weekly_sales




-- 2. Data Exploration

-- 1. What day of the week is used for each week_date value?
SELECT
    DISTINCT DATE_PART('isodow',week_date)
FROM data_mart.clean_weekly_sales
-- Monday

-- 2. What range of week numbers are missing from the dataset?
WITH weeks as (
    SELECT
        DISTINCT week_number
        ,calendar_year
    FROM data_mart.clean_weekly_sales
    ORDER BY 2, 1)

SELECT
    *
    ,LEAD(week_number) OVER (PARTITION BY calendar_year ORDER BY week_number)
    ,LEAD(week_number) OVER (PARTITION BY calendar_year ORDER BY week_number) - week_number
FROM weeks
WHERE calendar_year = 2019
-- Weeks 1 - 12 and 37 - 52

-- 3. How many total transactions were there for each year in the dataset?
SELECT
    calendar_year
    ,SUM(transactions)
FROM data_mart.clean_weekly_sales
GROUP BY calendar_year
ORDER BY calendar_year

-- 4. What is the total sales for each region for each month?
SELECT
    region
    ,month_number
    ,SUM(sales)
FROM data_mart.clean_weekly_sales
GROUP BY region, month_number
ORDER BY region, month_number

-- 5. What is the total count of transactions for each platform?
SELECT
    platform
    ,SUM(transactions)
FROM data_mart.clean_weekly_sales
GROUP BY platform

-- 6. What is the percentage of sales for Retail vs Shopify for each month?
WITH cte as (
    SELECT
        month_number
        ,platform
        ,SUM(sales) as sales_by_platform
        ,t2.sales_by_month 
    FROM data_mart.clean_weekly_sales t1
    LEFT JOIN (SELECT month_number, SUM(sales) as sales_by_month FROM data_mart.clean_weekly_sales GROUP BY month_number) t2
    USING(month_number)
    GROUP BY month_number, platform, t2.sales_by_month
    ORDER BY month_number, platform
)

SELECT
    month_number
    ,platform
    ,sales_by_platform
    ,sales_by_month
    ,ROUND(sales_by_platform * 100.0 /sales_by_month, 2) as perc
FROM cte

-- 7. What is the percentage of sales by demographic for each year in the dataset?
WITH cte as (
    SELECT
        calendar_year
        ,demographic
        ,SUM(sales) as sales_by_demo
        ,sales_by_year
    FROM data_mart.clean_weekly_sales t1
    LEFT JOIN (SELECT calendar_year, SUM(sales) as sales_by_year FROM data_mart.clean_weekly_sales GROUP BY calendar_year) t2
    USING(calendar_year)
    GROUP BY 1, 2, 4
    ORDER BY 1, 2
)
SELECT
    calendar_year
    ,demographic
    ,sales_by_demo
    ,sales_by_year
    ,ROUND(sales_by_demo * 100.0/sales_by_year, 2) as perc
FROM cte





-- 8. Which age_band and demographic values contribute the most to Retail sales?
SELECT
    age_band
    ,demographic
    ,SUM(sales)
FROM data_mart.clean_weekly_sales
WHERE platform = 'Retail'
GROUP BY 1,2
ORDER BY 3 DESC;

SELECT
    age_band
    ,SUM(sales)
FROM data_mart.clean_weekly_sales
WHERE platform = 'Retail'
GROUP BY 1
ORDER BY 2 DESC;

SELECT
    demographic
    ,SUM(sales)
FROM data_mart.clean_weekly_sales
WHERE platform = 'Retail'
GROUP BY 1
ORDER BY 2 DESC;

-- 9. Can we use the avg_transaction column to find the average transaction size for each year for Retail vs Shopify? If not - how would you calculate it instead?
SELECT
    calendar_year
    ,platform
    ,SUM(transactions) sum_trans
    ,SUM(sales) sum_sales
    ,SUM(sales)*1.0/SUM(transactions) as avg_trans
    ,AVG(avg_transaction) avg_trans2
FROM data_mart.clean_weekly_sales
GROUP BY 1,2
ORDER BY 1,2

-- 3. Before and after analysis

-- 1. What is the total sales for the 4 weeks before and after 2020-06-15? What is the growth or reduction rate in actual values and percentage of sales?
WITH cte as (
    SELECT
        week_number
        ,SUM(sales) sales_per_week
    FROM data_mart.clean_weekly_sales
    WHERE week_number BETWEEN 21 AND 28
      AND calendar_year = 2020
    GROUP BY 1
    ORDER BY 1
    ),
    cte2 as  (
    SELECT
        *
        ,sales_per_week - LAG(sales_per_week) OVER (ORDER BY week_number) wow_growth
    FROM cte
    )

SELECT
    *
    ,ROUND(wow_growth*100.0/LAG(sales_per_week) OVER (ORDER BY week_number), 2) wow_growth_perc
FROM cte2




-- 2. What about the entire 12 weeks before and after?
WITH cte as (
    SELECT
        week_number
        ,SUM(sales) sales_per_week
    FROM data_mart.clean_weekly_sales
    WHERE calendar_year = 2020
    GROUP BY 1
    ORDER BY 1
    ),
    cte2 as  (
    SELECT
        *
        ,sales_per_week - LAG(sales_per_week) OVER (ORDER BY week_number) wow_growth
    FROM cte
    )

SELECT
    *
    ,ROUND(wow_growth*100.0/LAG(sales_per_week) OVER (ORDER BY week_number), 2) wow_growth_perc
FROM cte2

-- 3. How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019?

WITH cte as (
    SELECT
        calendar_year
        ,week_number
        ,SUM(sales) sales_per_week
    FROM data_mart.clean_weekly_sales
    WHERE calendar_year = 2018
    GROUP BY 1, 2
    ORDER BY 1, 2
    ),
    cte2 as  (
    SELECT
        *
        ,sales_per_week - LAG(sales_per_week) OVER (ORDER BY calendar_year, week_number) wow_growth
    FROM cte
    )

SELECT
    *
    ,ROUND(wow_growth*100.0/LAG(sales_per_week) OVER (ORDER BY calendar_year, week_number), 2) wow_growth_perc
FROM cte2
ORDER BY 1, 2

-- Year over year sales

WITH w_18 as (
    SELECT
        week_number
        ,SUM(sales) as s_18
    FROM data_mart.clean_weekly_sales
    WHERE calendar_year = 2018
    GROUP BY week_number
),
w_19 as (
    SELECT
        week_number
        ,SUM(sales) as s_19
    FROM data_mart.clean_weekly_sales
    WHERE calendar_year = 2019
    GROUP BY week_number
),
w_20 as (
    SELECT
        week_number
        ,SUM(sales) as s_20
    FROM data_mart.clean_weekly_sales
    WHERE calendar_year = 2020
    GROUP BY week_number
)

SELECT
    week_number
    ,s_18
    ,ROUND((s_19-s_18)*100.0/s_18,2) as growth1
    ,s_19
    ,ROUND((s_20-s_19)*100.0/s_19,2) as growth2
    ,s_20
FROM w_18
JOIN w_19 USING(week_number)
JOIN w_20 USING(week_number)



-- 4. Impact analysis
SELECT
    week_number
    ,region
    ,SUM(sales) sales_per_week
FROM data_mart.clean_weekly_sales
WHERE calendar_year = 2020
GROUP BY 1, 2
ORDER BY 2, 1