# Solar Energy SQL Analysis

## Project Overview

This project analyzes solar power plant performance using SQL.

The goal is to explore energy production, plant efficiency, maintenance downtime, monthly production trends, and the impact of maintenance activities on solar plant performance.

The project is structured into three SQL files, progressing from database creation and basic analysis to more advanced analytical queries.

## Database Structure

The database contains three main tables:

* `solar_plants` — information about each solar plant, including location, capacity, and launch date.
* `energy_generation` — monthly energy production data for each plant.
* `maintenance` — maintenance events, downtime, and maintenance type.

### Relationships

```text
solar_plants
     │
     ├──────────────< energy_generation
     │
     └──────────────< maintenance
```

## Project Structure

```text
solar-plant-sql-analysis/
│
├── README.md
├── 01_database_setup.sql
├── 02_basic_analysis.sql
└── 03_advanced_analysis.sql
```

### 01 — Database Setup

Creates the database, tables, relationships, and sample dataset.

The dataset contains:

* 10 solar plants
* 120 monthly energy generation records
* 20 maintenance records

### 02 — Basic Analysis

The second section focuses on fundamental SQL analysis, including:

* Total energy production per plant
* Highest-producing plant
* Energy production per MW
* Monthly energy production
* Monthly production changes
* Plants above average production
* Plant production rankings
* Top 3 plants by total production
* High-capacity, low-production-per-MW plants

### 03 — Advanced Analysis

The third section focuses on more advanced SQL techniques and performance analysis.

It includes:

* Total maintenance downtime per plant
* Estimated energy loss during downtime
* Production before and after maintenance
* Downtime versus energy production
* Above-average downtime and below-average production per MW
* Monthly production rankings
* Month-over-month production changes and growth rates
* Rolling 3-month production averages
* Production increase after maintenance
* Overall plant performance classification

## SQL Concepts Demonstrated

This project demonstrates practical use of:

* `SELECT`
* `WHERE`
* `JOIN`
* `GROUP BY`
* `ORDER BY`
* `LIMIT`
* Aggregate functions such as `SUM()` and `AVG()`
* `CASE WHEN`
* Common Table Expressions (`CTEs`)
* Window functions
* `LAG()`
* `DENSE_RANK()`
* Window frames
* Rolling averages
* `CROSS JOIN`
* Date functions such as `EXTRACT()`
* Calculated metrics
* Percentage change calculations


## Purpose
This project was created as a practical SQL portfolio project to develop and demonstrate data analysis skills using a realistic energy-sector dataset.
