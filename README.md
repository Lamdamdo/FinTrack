# FinTrack: SQL Financial Data Warehouse

**Objectives**:
* **Set up a financial database**: Create and populate a multi-table database to manage users, categories, and transactions.
* **Data Engineering**: Implement automated auditing and real-time summaries using SQL Triggers.
* **Performance Optimization**: Use B-Tree and Composite Indexing to ensure high-speed data retrieval.
* **Business Analysis**: Use advanced SQL (CTEs, Window Functions) to derive deep financial insights.

---

## **1. Project Structure**

### **Database Creation**
The project begins by establishing the `FinTrack_DB` and defining a normalized schema to maintain data integrity.

```sql
CREATE DATABASE FinTrack_DB;
USE FinTrack_DB;

CREATE TABLE Users (
    user_id INT PRIMARY KEY AUTO_INCREMENT,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    email VARCHAR(100) UNIQUE,
    joining_date DATE,
    credit_limit DECIMAL(10, 2) DEFAULT 5000.00
);
```

## **2. Automation & Data Engineering**

### **Audit Logging & Real-time Summaries (Triggers)**
I implemented SQL Triggers to handle critical backend logic automatically, ensuring data consistency and security without requiring manual application-layer updates.

* **`after_credit_limit_update`**: This trigger creates an immutable audit trail. Every time a user's credit limit is modified, the old and new values are logged in the `Audit_Log` table for security compliance.
* **`after_transaction_insert`**: To provide instant feedback in the UI, this trigger updates the `User_Spending_Summary` table immediately after a new purchase is recorded.

```sql
-- Trigger for automated auditing
DELIMITER $$
CREATE TRIGGER after_credit_limit_update
AFTER UPDATE ON Users
FOR EACH ROW
BEGIN
    IF OLD.credit_limit <> NEW.credit_limit THEN
        INSERT INTO Audit_Log (user_id, old_credit_limit, new_credit_limit)
        VALUES (OLD.user_id, OLD.credit_limit, NEW.credit_limit);
    END IF;
END $$
DELIMITER ;
```

## **3.Data Sanitization (Stored Procedure)**
I developed the CleanAndValidateData() procedure to handle common "dirty data" scenarios found in production environments.
The Logic: It automatically fills NULL credit values with a safe default (5000.00), standardizes user names to Proper Case, and generates a real-time flag report for transactions that exceed credit limits.

```sql
DELIMITER $$
CREATE PROCEDURE CleanAndValidateData()
BEGIN
    -- 1. Handling NULL Credit Limits (The Industry Requirement)
    IF EXISTS (SELECT 1 FROM Users WHERE credit_limit IS NULL) THEN
        UPDATE Users 
        SET credit_limit = 5000.00 
        WHERE credit_limit IS NULL;
        SELECT 'CLEANUP: NULL credit limits updated to 5000.00' AS Log;
    ELSE
        SELECT 'CLEANUP: No NULL values found' AS Log;
    END IF;

    -- 2. Standardizing Names (Capitalizing first letter)
    -- This shows you can handle "dirty" text data
    UPDATE Users 
    SET first_name = CONCAT(UPPER(LEFT(first_name, 1)), LOWER(SUBSTRING(first_name, 2)));

    -- 3. Flagging high-value transactions
    -- Let's see if any transaction exceeds a limit (Data Analysis)
    SELECT u.first_name, u.last_name, t.amount, u.credit_limit
    FROM Users u
    JOIN Transactions t ON u.user_id = t.user_id
    WHERE t.amount > u.credit_limit;
    
END $$

DELIMITER ;
```
## **4.Performance Tuning (Indexing)**
To ensure the platform remains responsive as transaction volume scales, I implemented B-Tree Indexing strategies.
### **Composite Indexing**: I created idx_user_date_composite on (user_id, transaction_date). This is specifically optimized for time-series queries, allowing the engine to skip millions of irrelevant rows when searching for a specific user's monthly activity.

```sql
-- Optimizing time-series retrieval
CREATE INDEX idx_user_date_composite ON Transactions(user_id, transaction_date);
```

## **3. Business Analysis & Key Findings**
The following queries represent the analytical core of the project, developed to provide actionable financial insights:

### **Q4: Monthly Momentum (The February Report)**
Business Question: What was the total spending for every user in February 2025, including those who were inactive? Technical Skill: Utilizes CTEs and LEFT JOINs to ensure "zero-spenders" are represented in the report as 0 instead of being filtered out.

```sql
WITH Monthly_Sale AS (
    SELECT user_id, SUM(amount) AS total_spent
    FROM Transactions
    WHERE MONTH(transaction_date) = 2 AND YEAR(transaction_date) = 2025
    GROUP BY user_id
)
SELECT 
    CONCAT(u.first_name, ' ', u.last_name) AS USER_NAME,
    COALESCE(cte.total_spent, 0) AS feb_total_spent
FROM Users u 
LEFT JOIN Monthly_Sale cte USING (user_id);
```
### **Q5: Intra-Category Ranking (Top 2 Transactions)**
Business Question: What are the top 2 highest individual transactions for every product
```sql
WITH RankedSales AS (
    SELECT 
        category_id, amount,
        DENSE_RANK() OVER(PARTITION BY category_id ORDER BY amount DESC) as rnk
    FROM Transactions
)
SELECT c.category_name, rs.amount
FROM RankedSales rs
JOIN Categories c ON rs.category_id = c.category_id
WHERE rs.rnk <= 2;
```
** FOR Full Analytical Report check Analytical_queries inside sql_scripts Folder
