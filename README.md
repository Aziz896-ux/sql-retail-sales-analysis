# Retail Sales Analysis with SQL

Analysis of two years of retail transactions in PostgreSQL: building the table, cleaning the data, and answering 13 business questions about categories, customers and timing.

**Tools:** PostgreSQL, SQL (aggregations, CTEs, window functions, CASE, date functions)

## Key findings

The cleaned dataset holds **1,997 transactions** from **155 customers** between January 2022 and December 2023, for **911,720** in total sales.

- **The last quarter carries the year.** October to December brought 46.4% of revenue in 2022 and 40.1% in 2023. The first quarter brought about 15% in both years.
- **Most orders come in the evening.** 1,062 of 1,997 orders (53%) were placed from 18:00 onwards, against 558 in the morning and 377 in the afternoon.
- **The three categories are almost level.** Electronics 313,810 (34.4%), Clothing 311,070 (34.1%), Beauty 286,840 (31.5%).
- **Younger customers spend more per order.** Average order value falls steadily with age, from 503 for the 18-25 group to 413 for customers aged 56 and over.
- **Revenue is concentrated in a few customers.** The top 5 of 155 customers account for 16.3% of total sales.
- **Beauty is the only category with a gender gap.** 330 purchases by women against 282 by men. Clothing and Electronics are split almost evenly.

## Files

| File | Content |
|---|---|
| `retail_sales.csv` | Source data: 2,000 transactions, 11 columns |
| `retail_sales_analysis.sql` | Table creation, cleaning and all 13 queries |

## How to run

1. Create a PostgreSQL database and connect to it.
2. Run the `CREATE TABLE` statement from `retail_sales_analysis.sql`.
3. Load the CSV. In psql:
   ```sql
   \copy retail_sales FROM 'retail_sales.csv' WITH (FORMAT csv, HEADER true)
   ```
4. Run the rest of the script.

## Data

| Column | Description |
|---|---|
| `transaction_id` | Unique ID of the transaction |
| `sale_date`, `sale_time` | When the sale took place |
| `customer_id` | Customer identifier |
| `gender`, `age` | Customer profile |
| `category` | Clothing, Beauty or Electronics |
| `quantity` | Units sold (1 to 4) |
| `price_per_unit` | Unit price |
| `cogs` | Cost of goods sold |
| `total_sale` | Transaction amount |

## Cleaning

3 of the 2,000 rows have no quantity, price, cost or total, so they cannot be used and are deleted. That leaves 1,997 rows. 10 other rows have no age; they are kept, and left out only where age is used.

```sql
DELETE FROM retail_sales
WHERE transaction_id IS NULL
   OR sale_date IS NULL
   OR sale_time IS NULL
   OR gender IS NULL
   OR category IS NULL
   OR quantity IS NULL
   OR cogs IS NULL
   OR total_sale IS NULL;
```

## Business questions

| # | Question | Result |
|---|---|---|
| 1 | Sales made on 2022-11-05 | 11 transactions |
| 2 | Clothing transactions in Nov 2022 with 4 or more units | 17 transactions |
| 3 | Total sales per category | Electronics 313,810, Clothing 311,070, Beauty 286,840 |
| 4 | Average age of Beauty customers | 40.42 |
| 5 | Transactions above 1,000 | 306 (15% of all transactions) |
| 6 | Transactions by gender and category | Even split, except Beauty (330 women, 282 men) |
| 7 | Best month of each year by average sale | July 2022 (541) and February 2023 (536) |
| 8 | Top 5 customers by total sales | Customers 3, 1, 5, 2 and 4, from 38,440 down to 23,580 |
| 9 | Unique customers per category | Clothing 149, Electronics 144, Beauty 141 |
| 10 | Orders per shift | Evening 1,062, Morning 558, Afternoon 377 |
| 11 | Share of yearly revenue per quarter | Q4: 46.4% in 2022, 40.1% in 2023 |
| 12 | Share of revenue from the top 5 customers | 16.3% |
| 13 | Average order value by age group | 503 (18-25) down to 413 (56+) |

All queries are in [`retail_sales_analysis.sql`](retail_sales_analysis.sql). Three of them:

**Best month of each year (window function)**

```sql
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
```

**Orders per shift (CTE and CASE)**

```sql
WITH hourly_sale AS (
    SELECT *,
        CASE
            WHEN EXTRACT(HOUR FROM sale_time) < 12 THEN 'Morning'
            WHEN EXTRACT(HOUR FROM sale_time) BETWEEN 12 AND 17 THEN 'Afternoon'
            ELSE 'Evening'
        END AS shift
    FROM retail_sales
)
SELECT shift, COUNT(*) AS total_orders
FROM hourly_sale
GROUP BY shift
ORDER BY total_orders DESC;
```

**Share of yearly revenue per quarter (window aggregate)**

```sql
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
```

## What this suggests for the business

- Stock and staffing should be planned around the last quarter, which brings more than 40% of yearly sales.
- Evening is the busiest period, so it is the natural slot for promotions and for the strongest staffing.
- With the three categories level, no single one drives growth. Beauty has the clearest target audience.
- A small group of customers generates a large share of sales, which makes a loyalty programme worth testing.

## Author

Abdelaziz Dhouib, Master's student in Business Analytics. [LinkedIn](https://www.linkedin.com/in/abdelaziz-dhouib)
