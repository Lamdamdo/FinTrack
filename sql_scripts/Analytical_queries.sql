-- =============================================
-- FINTRACK BUSINESS INTELLIGENCE REPORTS
-- Purpose: Advanced analytical queries for 
-- financial insights and risk detection.
-- =============================================

-- Q1: High-Value User Identification
-- Goal: Find users with a credit limit > 10,000 who joined in 2025.
SELECT first_name, last_name, credit_limit 
FROM Users 
WHERE credit_limit > 10000 
  AND YEAR(joining_date) = 2025;

-- Q2: Category Popularity Analysis
-- Goal: Rank spending categories by transaction volume.
SELECT c.category_name, COUNT(t.transaction_id) AS volume
FROM Transactions t
JOIN Categories c ON t.category_id = c.category_name
GROUP BY c.category_name
ORDER BY volume DESC;

-- Q3: Risk Detection (The 5% Rule)
-- Goal: Identify users whose total spending exceeds 5% of their credit limit.
SELECT 
    CONCAT(u.first_name, ' ', u.last_name) AS full_name,
    SUM(t.amount) AS total_spent,
    u.credit_limit
FROM Transactions t
JOIN Users u USING(user_id)
GROUP BY u.user_id, u.first_name, u.last_name, u.credit_limit
HAVING total_spent > (u.credit_limit * 0.05);

-- Q4: Monthly Momentum (February Report)
-- Goal: Total spending for Feb 2025, including users with zero spending.
-- Technical: Uses CTE and LEFT JOIN to prevent data loss.
WITH Monthly_Sale AS (
    SELECT 
        user_id,
        SUM(amount) AS total_spent
    FROM Transactions
    WHERE MONTH(transaction_date) = 2 
      AND YEAR(transaction_date) = 2025
    GROUP BY user_id
)
SELECT 
    CONCAT(u.first_name, ' ', u.last_name) AS USER_NAME,
    COALESCE(cte.total_spent, 0) AS feb_total_spent
FROM Users u 
LEFT JOIN Monthly_Sale cte USING (user_id);

-- Q5: Top-Tier Category Analysis (Boss Level)
-- Goal: Find the top 2 highest transactions in every category.
-- Technical: Uses Window Functions (DENSE_RANK) for Intra-category ranking.
WITH RankedSales AS (
    SELECT 
        category_id,
        amount,
        DENSE_RANK() OVER(PARTITION BY category_id ORDER BY amount DESC) as rnk
    FROM Transactions
)
SELECT 
    c.category_name, 
    rs.amount
FROM RankedSales rs
JOIN Categories c ON rs.category_id = c.category_id
WHERE rs.rnk <= 2;

-- Q6: New User Spotlight
-- Goal: Find users who joined in the first 15 days of the year.
SELECT first_name, joining_date 
FROM Users 
WHERE DAYOFYEAR(joining_date) <= 15;

-- Q7: Weekend Warriors
-- Goal: Sum of all transactions that occurred on weekends.
SELECT SUM(amount) AS weekend_total
FROM Transactions
WHERE DAYNAME(transaction_date) IN ('Saturday', 'Sunday');

-- Q8: Average Daily Spend
-- Goal: Calculate the average spending per day across the whole platform.
SELECT transaction_date, AVG(amount) as daily_avg
FROM Transactions
GROUP BY transaction_date
ORDER BY transaction_date;

-- Q9: Month-over-Month Growth (Tough)
-- Goal: Compare total platform spend between Jan and Feb.
WITH JanTotal AS (
    SELECT SUM(amount) as jan_amt FROM Transactions WHERE MONTH(transaction_date) = 1
),
FebTotal AS (
    SELECT SUM(amount) as feb_amt FROM Transactions WHERE MONTH(transaction_date) = 2
)
SELECT 
    jan_amt, 
    feb_amt, 
    ((feb_amt - jan_amt) / jan_amt) * 100 AS percentage_growth
FROM JanTotal, FebTotal;

-- Q10: Inactive Users (Tough)
-- Goal: Identify users who spent in Jan but nothing in Feb (Churn Analysis).
SELECT DISTINCT u.user_id, u.first_name
FROM Users u
JOIN Transactions t1 ON u.user_id = t1.user_id AND MONTH(t1.transaction_date) = 1
LEFT JOIN Transactions t2 ON u.user_id = t2.user_id AND MONTH(t2.transaction_date) = 2
WHERE t2.transaction_id IS NULL;
