# Vehicle Service Center Database

A fully normalized MySQL database system for managing a vehicle service center — covering customers, vehicles, job cards, parts inventory, service history, and employee records.

---

## Group 4 — Team Members

| Name | Role |
|------|------|
| Touseef Subhani | Admin / Project Lead |
| Abubakar Ilyas | Database Developer |
| Adil Shahzad | Database Developer |
| Zubair Saeed | Database Developer |
| Noman | Database Developer |

---

## Project Overview

This database system is designed to manage the complete workflow of a vehicle service center:

- Register customers and their vehicles
- Create and track job cards for each service visit
- Record which services were performed and by which mechanic
- Issue parts from inventory and automatically update stock
- Generate reports on revenue, mechanic performance, and service history

---

## Technology Stack

| Component | Details |
|-----------|---------|
| Database | MySQL 8.0+ |
| Engine | InnoDB (all tables) |
| Charset | utf8mb4 / utf8mb4_unicode_ci |
| Normalization | Third Normal Form (3NF) |
| Tool | MySQL Workbench / CLI |

---

## Database Schema

### Tables (10 total)

| Table | Description | Rows (sample) |
|-------|-------------|---------------|
| `customers` | Customer master data — name, phone, email, city | 25 |
| `vehicle_makes` | Lookup table for car brands (Toyota, Honda, etc.) | 10 |
| `vehicle_models` | Models linked to makes (Corolla, Civic, etc.) | 23 |
| `vehicles` | Vehicle records linked to customers | 25 |
| `employees` | Mechanics, advisors, supervisors, parts managers | 10 |
| `service_types` | Service catalogue with standard labor costs | 15 |
| `parts` | Parts inventory with stock levels and pricing | 25 |
| `job_cards` | One record per service visit (header) | 25 |
| `job_services` | Services performed on each job card | 32 |
| `job_parts` | Parts used on each job card | 30 |

### Normalization

- **1NF** — All columns are atomic; no repeating groups
- **2NF** — No partial dependencies on composite keys
- **3NF** — No transitive dependencies; lookup tables used for makes/models/service types

### Entity Relationships

```
customers     ──< vehicles      : one customer owns many vehicles
vehicle_makes ──< vehicle_models: one make has many models
vehicle_models──< vehicles      : one model used by many vehicles
vehicles      ──< job_cards     : one vehicle has many job cards
employees     ──< job_cards     : one advisor handles many jobs
employees     ──< job_services  : one mechanic performs many services
job_cards     ──< job_services  : one job card has many services
job_cards     ──< job_parts     : one job card uses many parts
service_types ──< job_services  : one service type used in many jobs
parts         ──< job_parts     : one part issued across many jobs
```

> To view the full ER Diagram visually, open MySQL Workbench → **Database → Reverse Engineer** → select `vehicle_service_center`.

---

## Indexes

| Index | Table | Column(s) | Purpose |
|-------|-------|-----------|---------|
| `idx_vehicles_reg` | vehicles | reg_number | Fast vehicle lookup |
| `idx_vehicles_customer` | vehicles | customer_id | Customer's vehicles |
| `idx_job_cards_status` | job_cards | status | Filter by Open/Completed |
| `idx_job_cards_date_in` | job_cards | date_in | Date range queries |
| `idx_parts_stock` | parts | stock_qty | Low stock alerts |
| `idx_parts_number` | parts | part_number | Part lookup |
| `idx_customers_phone` | customers | phone | Customer search |
| `idx_job_services_job` | job_services | job_id | Job detail lookups |

---

## Views (5 total)

| View | Description |
|------|-------------|
| `vw_job_summary` | Full job card with customer, vehicle, advisor, and totals |
| `vw_low_stock_parts` | Parts at or below reorder level |
| `vw_monthly_revenue` | Revenue, job count, and discounts grouped by month |
| `vw_mechanic_performance` | Services done and labor earned per mechanic |
| `vw_vehicle_history` | All services performed on each vehicle |

---

## Stored Procedures & Functions (12 total)

### Stored Procedures

| Procedure | Parameters | Description |
|-----------|-----------|-------------|
| `sp_get_customer_profile` | `customer_id` | Returns customer info + all their vehicles |
| `sp_create_job_card` | `vehicle_id, advisor_id, complaint` | Opens a new job card |
| `sp_add_service_to_job` | `job_id, service_type_id, mechanic_id, labor_cost, notes` | Adds a service and auto-updates labor total |
| `sp_issue_part` | `job_id, part_id, qty` | Issues a part, validates stock, updates inventory |
| `sp_complete_job` | `job_id, discount` | Closes a job card with optional discount |
| `sp_search_vehicle` | `keyword` | Search vehicles by reg number or customer name |
| `sp_top_customers` | `limit` | Returns top N customers by total spend |
| `sp_restock_part` | `part_id, qty_to_add` | Adds stock to a part |

### Functions

| Function | Parameters | Returns |
|----------|-----------|---------|
| `fn_revenue_in_range` | `start_date, end_date` | Total revenue for a date range |
| `fn_vehicle_job_count` | `vehicle_id` | Number of job cards for a vehicle |

---

## How to Run

### MySQL Workbench (Recommended)

1. Open MySQL Workbench and connect to `localhost:3306`
2. Go to **File → Open SQL Script…** and select `vehicle_service_center.sql`
3. Press **Ctrl + Shift + Enter** to execute the entire script
4. Check the **Output** pane at the bottom for green checkmarks ✅
5. Expand **Schemas → vehicle_service_center** in the left panel to browse all tables

### Command Line

```bash
mysql -u root -p < vehicle_service_center.sql
```

### Verify Installation

```sql
USE vehicle_service_center;
SHOW TABLES;
SELECT COUNT(*) FROM customers;   -- should return 25
SELECT COUNT(*) FROM job_cards;   -- should return 25
```

---

## Sample Queries

```sql
-- All job cards with customer and vehicle info
SELECT * FROM vw_job_summary ORDER BY job_id;

-- Monthly revenue report
SELECT * FROM vw_monthly_revenue;

-- Top 5 spending customers
CALL sp_top_customers(5);

-- Parts that need restocking
SELECT * FROM vw_low_stock_parts;

-- Mechanic performance report
SELECT * FROM vw_mechanic_performance ORDER BY total_labor_earned DESC;

-- Vehicle service history
SELECT * FROM vw_vehicle_history ORDER BY reg_number, date_in;

-- Revenue for first half of 2024
SELECT fn_revenue_in_range('2024-01-01', '2024-06-30') AS h1_2024_revenue;

-- Search a vehicle by registration or owner name
CALL sp_search_vehicle('LHR');

-- Open a new job card
CALL sp_create_job_card(1, 2, 'Engine making noise');

-- Issue a part from inventory
CALL sp_issue_part(1, 10, 4);  -- job_id=1, part_id=10 (spark plug), qty=4
```

---

## Project Files

| File | Description |
|------|-------------|
| `vehicle_service_center.sql` | Complete database script — tables, data, views, procedures |
| `README.md` | This file |
| `vehicle_service_center.mwb` | MySQL Workbench ER Diagram model *(generate via Reverse Engineer)* |

---

## Requirements

- MySQL 8.0 or higher
- MySQL Workbench 8.0+ *(recommended)* or any MySQL client

---

## License

This project was created for academic purposes as part of a university database course assignment.
