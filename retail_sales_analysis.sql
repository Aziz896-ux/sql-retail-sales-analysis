-- ============================================================
-- Retail Sales Analysis (PostgreSQL)
-- Author: Abdelaziz Dhouib
-- ============================================================

-- ------------------------------------------------------------
-- 1. Database setup
-- ------------------------------------------------------------
-- Run this line once, then connect to the new database
-- before running the rest of the script.
CREATE DATABASE sql_project;

DROP TABLE IF EXISTS retail_sales;
CREATE TABLE retail_sales
(
    transaction_id  INT PRIMARY KEY,
    sale_date       DATE,
    sale_time       TIME,
    customer_id     INT,
    gender          VARCHAR(15),
    age             INT,
    category        VARCHAR(15),
    quantity        INT,
    price_per_unit  FLOAT,
    cogs            FLOAT,
    total_sale      FLOAT
);

-- Load the data. Columns are read by position, so the two typos in the
-- CSV header (transactions_id, quantiy) do not matter.
--   psql:    \copy retail_sales FROM 'retail_sales.csv' WITH (FORMAT csv, HEADER true)
--   pgAdmin: right-click the table > Import/Export Data > retail_sales.csv, header ON


-- ------------------------------------------------------------
-- 2. Data exploration and cleaning
-- ------------------------------------------------------------
SELECT * FROM retail_sales
LIMIT 10;

-- Rows loaded
SELECT COUNT(*) AS total_rows FROM retail_sales;

-- Rows with a missing value in a field the analysis depends on
SELECT * FROM retail_sales
WHERE transaction_id IS NULL
   OR sale_date IS NULL
   OR sale_time IS NULL
   OR gender IS NULL
   OR category IS NULL
   OR quantity IS NULL
   OR cogs IS NULL
   OR total_sale IS NULL;

-- Remove them
DELETE FROM retail_sales
WHERE transaction_id IS NULL
   OR sale_date IS NULL
   OR sale_time IS NULL
   OR gender IS NULL
   OR category IS NULL
   OR quantity IS NULL
   OR cogs IS NULL
   OR total_sale IS NULL;

-- How many sales are left?
SELECT COUNT(*) AS total_sales FROM retail_sales;

-- How many unique customers?
SELECT COUNT(DISTINCT customer_id) AS total_customers FROM retail_sales;

-- Which product categories?
SELECT DISTINCT category FROM retail_sales;


-- ------------------------------------------------------------
-- 3. Business questions
-- ------------------------------------------------------------

-- Q1. All sales made on 2022-11-05
SELECT *
FROM retail_sales
WHERE sale_date = '2022-11-05';

-- Q2. Clothing transactions in November 2022 with 4 or more units
--     (4 is the largest quantity in the data, so "more than 4" returns nothing)
SELECT *
FROM retail_sales
WHERE category = 'Clothing'
  AND TO_CHAR(sale_date, 'YYYY-MM') = '2022-11'
  AND quantity >= 4;

-- Q3. Total sales and number of orders for each category
SELECT
    category,
    SUM(total_sale) AS net_sale,
    COUNT(*)        AS total_orders
FROM retail_sales
GROUP BY category
ORDER BY net_sale DESC;

-- Q4. Average age of customers who bought from the Beauty category
SELECT ROUND(AVG(age), 2) AS avg_age
FROM retail_sales
WHERE category = 'Beauty';

-- Q5. Transactions with a total sale above 1000
SELECT *
FROM retail_sales
WHERE total_sale > 1000;

-- Q6. Number of transactions by gender in each category
SELECT
    category,
    gender,
    COUNT(*) AS total_trans
FROM retail_sales
GROUP BY category, gender
ORDER BY category, gender;

-- Q7. Average sale per month, and the best month of each year
SELECT year, month, avg_sale
FROM (
    SELECT
        EXTRACT(YEAR FROM sale_date)  AS year,
        EXTRACT(MONTH FROM sale_date) AS month,
        AVG(total_sale)               AS avg_sale,
        RANK() OVER (
            PARTITION BY EXTRACT(YEAR FROM sale_date)
            ORDER BY AVG(total_sale) DESC
        ) AS rnk
    FROM retail_sales
    GROUP BY 1, 2
) AS t1
WHERE rnk = 1;

-- Q8. Top 5 customers by total sales
SELECT
    customer_id,
    SUM(total_sale) AS total_sales
FROM retail_sales
GROUP BY customer_id
ORDER BY total_sales DESC
LIMIT 5;

-- Q9. Unique customers per category
SELECT
    category,
    COUNT(DISTINCT customer_id) AS cnt_unique_cs
FROM retail_sales
GROUP BY category;

-- Q10. Orders per shift (Morning < 12h, Afternoon 12h to 17h, Evening after 17h)
WITH hourly_sale AS (
    SELECT *,
        CASE
            WHEN EXTRACT(HOUR FROM sale_time) < 12 THEN 'Morning'
            WHEN EXTRACT(HOUR FROM sale_time) BETWEEN 12 AND 17 THEN 'Afternoon'
            ELSE 'Evening'
        END AS shift
    FROM retail_sales
)
SELECT
    shift,
    COUNT(*) AS total_orders
FROM hourly_sale
GROUP BY shift
ORDER BY total_orders DESC;


-- ------------------------------------------------------------
-- 4. Going further
-- ------------------------------------------------------------

-- Q11. Seasonality: what share of each year's revenue does each quarter bring?
SELECT
    year,
    quarter,
    revenue,
    ROUND((100.0 * revenue / SUM(revenue) OVER (PARTITION BY year))::numeric, 1) AS pct_of_year
FROM (
    SELECT
        EXTRACT(YEAR FROM sale_date)    AS year,
        EXTRACT(QUARTER FROM sale_date) AS quarter,
        SUM(total_sale)                 AS revenue
    FROM retail_sales
    GROUP BY 1, 2
) AS q
ORDER BY year, quarter;

-- Q12. Customer concentration: how much of total revenue comes from the top 5 customers?
WITH customer_sales AS (
    SELECT
        customer_id,
        SUM(total_sale) AS revenue,
        RANK() OVER (ORDER BY SUM(total_sale) DESC) AS rnk
    FROM retail_sales
    GROUP BY customer_id
)
SELECT
    SUM(revenue) FILTER (WHERE rnk <= 5) AS top5_revenue,
    SUM(revenue)                         AS total_revenue,
    ROUND((100.0 * SUM(revenue) FILTER (WHERE rnk <= 5) / SUM(revenue))::numeric, 1) AS top5_pct
FROM customer_sales;

-- Q13. Orders, revenue and average order value by age group
SELECT
    CASE
        WHEN age <= 25 THEN '18-25'
        WHEN age <= 35 THEN '26-35'
        WHEN age <= 45 THEN '36-45'
        WHEN age <= 55 THEN '46-55'
        ELSE '56+'
    END AS age_group,
    COUNT(*)                            AS total_orders,
    SUM(total_sale)                     AS revenue,
    ROUND(AVG(total_sale)::numeric, 0)  AS avg_order_value
FROM retail_sales
WHERE age IS NOT NULL
GROUP BY 1
ORDER BY 1;

-- End of project
