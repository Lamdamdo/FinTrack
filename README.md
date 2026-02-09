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
