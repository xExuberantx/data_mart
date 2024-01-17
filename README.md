# data_mart
Step by step solution to 'Data with Danny's case study no. 5

Database schema can be found under https://8weeksqlchallenge.com/case-study-5/

![image](https://github.com/xExuberantx/data_mart/assets/131042937/4b5e9e3c-cd26-46b6-9008-950e4766dfc9)

The key business question to answer are the following:

1. What was the quantifiable impact of the changes introduced in June 2020?
2. Which platform, region, segment and customer types were the most impacted by this change?
3. What can we do about future introduction of similar sustainability updates to the business to minimise impact on sales?


# Data Cleansing

In a single query, perform the following operations and generate a new table in the data_mart schema named clean_weekly_sales:
- Convert the week_date to a DATE format
- Add a week_number as the second column for each week_date value, for example any value from the 1st of January to 7th of January will be 1, 8th to 14th will be 2 etc
- Add a month_number with the calendar month for each week_date value as the 3rd column
- Add a calendar_year column as the 4th column containing either 2018, 2019 or 2020 values
- Add a new column called age_band after the original segment column using the following mapping on the number inside the segment value
- Add a new demographic column using the following mapping for the first letter in the segment values
- Ensure all null string values with an "unknown" string value in the original segment column as well as the new age_band and demographic columns
- Generate a new avg_transaction column as the sales value divided by transactions rounded to 2 decimal places for each record

```
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
    ,ROUND(sales/transactions,2) as avg_transaction
FROM data_mart.weekly_sales
```
![image](screens/cleansing.png)
