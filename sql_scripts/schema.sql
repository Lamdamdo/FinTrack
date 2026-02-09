-- Creating or Droping a databse if it pre-exists
DROP DATABASE IF EXISTS FinTrack_DB;
CREATE DATABASE FinTrack_DB;
USE FinTrack_DB;

-- 1. Users Table
CREATE TABLE Users (
    user_id INT PRIMARY KEY AUTO_INCREMENT,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    email VARCHAR(100) UNIQUE,
    joining_date DATE,
    credit_limit DECIMAL(10, 2) DEFAULT 5000.00
);

-- 2. Categories Table
CREATE TABLE Categories (
    category_id INT PRIMARY KEY AUTO_INCREMENT,
    category_name VARCHAR(50)
);

-- 3. Transactions (The 'Fact' Table)
CREATE TABLE Transactions (
    transaction_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT,
    category_id INT,
    amount DECIMAL(10, 2),
    transaction_date DATE,
    description VARCHAR(255),
    FOREIGN KEY (user_id) REFERENCES Users(user_id),
    FOREIGN KEY (category_id) REFERENCES Categories(category_id)
);

-- 4.Audit-log table
CREATE TABLE Audit_Log (
    audit_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT,
    old_credit_limit DECIMAL(10, 2),
    new_credit_limit DECIMAL(10, 2),
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 5.User_Spending_Summary Tale
CREATE TABLE User_Spending_Summary (
    user_id INT PRIMARY KEY,
    total_spent DECIMAL(15, 2) DEFAULT 0.00,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Inserting data into Categories Table
INSERT INTO Categories (category_name) VALUES 
('Salary'), ('Rent'), ('Food'), ('Entertainment'), ('Utilities'), ('Investment'), ('Shopping'), ('Healthcare');

INSERT INTO Users (first_name, last_name, email, joining_date, credit_limit) VALUES 
('Ishan', 'Sharma', 'ishan@test.com', '2025-01-01', 15000),
('Anjali', 'Verma', 'anjali@test.com', '2025-01-05', 8000),
('Rahul', 'Singh', 'rahul@test.com', '2025-01-10', 5000),
('Sneha', 'Kapoor', 'sneha@test.com', '2025-01-15', 12000),
('Vikram', 'Mehta', 'vikram@test.com', '2025-01-20', NULL), -- Our 'Dirty Data'
('Priya', 'Das', 'priya@test.com', '2025-01-25', 9000),
('Amit', 'Goel', 'amit@test.com', '2025-02-01', 10000),
('Sonia', 'Khan', 'sonia@test.com', '2025-02-05', 7000),
('Rohan', 'Jain', 'rohan@test.com', '2025-02-10', NULL), -- More 'Dirty Data'
('Tara', 'Iyer', 'tara@test.com', '2025-02-15', 11000);

-- Inserting data into Transaction Table
INSERT INTO Transactions (user_id, category_id, amount, transaction_date, description)
SELECT 
    u.user_id,
    (u.user_id % 8) + 1, -- Cycles through the 8 categories
    (RAND() * 500) + 50, -- Random amount between 50 and 550
    DATE_ADD('2025-01-01', INTERVAL (u.user_id * t.n) DAY),
    CONCAT('Automated Transaction ', t.n)
FROM Users u
CROSS JOIN (
    SELECT 1 AS n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 
    UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10
    UNION SELECT 11 UNION SELECT 12 UNION SELECT 13 UNION SELECT 14 UNION SELECT 15
) t;

-- Checking the tables after creatinon and insertion
SELECT 
    (SELECT COUNT(*) FROM Users) as Total_Users,
    (SELECT COUNT(*) FROM Categories) as Total_Categories,
    (SELECT COUNT(*) FROM Transactions) as Total_Transactions;
    
-- Making a Stored Procedure to-
--1. Check for NULLs: Search for missing credit limits and update it with 5000 if found NULL
--2. Data Integrity Check: Ensuring no transaction is larger than a user's credit limit (a key business rule).
  
DELIMITER $$
CREATE PROCEDURE CleanAndValidateData()
BEGIN
    --  Handling NULL Credit Limits
    IF EXISTS (SELECT 1 FROM Users WHERE credit_limit IS NULL) THEN
        UPDATE Users 
        SET credit_limit = 5000.00 
        WHERE credit_limit IS NULL;
        SELECT 'CLEANUP: NULL credit limits updated to 5000.00' AS Log;
    ELSE
        SELECT 'CLEANUP: No NULL values found' AS Log;
    END IF;

    --  Standardizing Names (Capitalizing first letter)
    UPDATE Users 
    SET first_name = CONCAT(UPPER(LEFT(first_name, 1)), LOWER(SUBSTRING(first_name, 2)));

    -- 3. Flagging high-value transactions
    SELECT u.first_name, u.last_name, t.amount, u.credit_limit
    FROM Users u
    JOIN Transactions t ON u.user_id = t.user_id
    WHERE t.amount > u.credit_limit;
    
END $$

DELIMITER ;
CALL CleanAndValidateData();

-- This creates a Non-Clustered Index on the Foreign Keys
-- It prevents "Full Table Scans" when joining Users and Transactions
CREATE INDEX idx_user_id ON Transactions(user_id);
CREATE INDEX idx_trans_date ON Transactions(transaction_date);

-- This creates a composite index on BOTH user_id and transaction_date
-- It is much faster for queries that use both in the WHERE clause
CREATE INDEX idx_user_date_composite ON Transactions(user_id, transaction_date);

-- Making a triggers to update the Audit_log table if change occurs
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



--Every time a new transaction is added, this trigger updates the summary table automatically.

DELIMITER $$
CREATE TRIGGER after_transaction_insert
AFTER INSERT ON Transactions
FOR EACH ROW
BEGIN
    -- This ensures the user exists in the summary table
    INSERT INTO User_Spending_Summary (user_id, total_spent)
    VALUES (NEW.user_id, NEW.amount)
    ON DUPLICATE KEY UPDATE total_spent = total_spent + NEW.amount ;
END $$

DELIMITER ;


