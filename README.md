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
---

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

