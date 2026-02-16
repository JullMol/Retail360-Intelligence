# Retail360 Intelligence

**End-to-End Modern Data Stack for Omni-Channel Retail Analytics**

An enterprise-grade capstone project demonstrating the full data lifecycle — from raw transactional data through a properly modeled Data Warehouse to actionable Business Intelligence dashboards.

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                        RETAIL360 ARCHITECTURE                       │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌─────────┐    ┌──────────────┐    ┌──────────────┐    ┌────────┐ │
│  │ Raw CSV │───>│  Staging     │───>│  Star Schema │───>│Power BI│ │
│  │ (9 files)│    │  (stg_*)     │    │  DWH         │    │Dashboard│ │
│  └─────────┘    └──────────────┘    └──────────────┘    └────────┘ │
│                                                                     │
│  DATA SOURCE     EXTRACT            TRANSFORM & LOAD   VISUALIZE   │
│  Brazilian       Python ETL         7 Dimensions        DAX        │
│  E-Commerce      Pandas + SQL       2 Fact Tables       Power Query│
│  (Olist)         Data Validation    Surrogate Keys      14 Views   │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

## Tech Stack

| Layer | Technology | Purpose |
|---|---|---|
| Database | PostgreSQL | Relational store for staging + DWH |
| ETL Pipeline | Python (Pandas, SQLAlchemy) | Extract, validate, transform, load |
| Data Modeling | Kimball Star Schema | 7 dimension + 2 fact tables |
| Analytics | SQL (Window Functions, CTEs) | 10 business intelligence views |
| Visualization | Power BI (DAX, Power Query) | Interactive executive dashboard |

## Data Warehouse Design

### Star Schema

**Dimension Tables:**
- `dim_date` — Calendar with fiscal year/quarter support
- `dim_customer` — Customer demographics and geography
- `dim_product` — Product catalog with English category names
- `dim_seller` — Seller/vendor directory
- `dim_geography` — Deduplicated geolocation by zip code
- `dim_payment_type` — Payment method reference
- `dim_order_status` — Order lifecycle states

**Fact Tables:**
- `fact_orders` — Order item-level granularity (sales + logistics + reviews)
- `fact_payments` — Payment transaction-level (installment analysis)

### Bus Matrix

| Fact \ Dimension | Date | Customer | Product | Seller | Geography | Payment Type | Order Status |
|---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| fact_orders | ✔ | ✔ | ✔ | ✔ | ○ | – | ✔ |
| fact_payments | ✔ | ✔ | – | – | – | ✔ | – |

## Business Analytics (10 Views)

| # | View | Business Question |
|---|---|---|
| 1 | RFM Segmentation | Who are Champions vs Hibernating customers? |
| 2 | Cohort Retention | What % of Jan customers return in June? |
| 3 | Customer LTV | What is each customer's 2-year predicted value? |
| 4 | Market Basket | Which product categories are bought together? |
| 5 | Pareto Analysis | Do 20% of categories drive 80% of revenue? |
| 6 | Logistics Performance | Which states have worst delivery delays? |
| 7 | Seller Scorecard | Which sellers are Gold/Silver/Bronze tier? |
| 8 | Revenue Trends | What is MoM and YoY revenue growth? |
| 9 | Payment Analysis | Which payment methods dominate by value? |
| 10 | Category BCG Matrix | Which categories are Stars vs Dogs? |

## Project Structure

```
Retail360-Intelligence/
├── data/
│   └── raw/                          # 9 Olist CSV datasets
├── sql/
│   ├── ddl/
│   │   └── create_star_schema.sql    # Full DWH schema (7 dim + 2 fact + staging)
│   ├── transformations/
│   │   └── business_metrics.sql      # 10 analytical views
│   └── views/
│       └── power_bi_views.sql        # 4 Power BI-optimized views
├── scripts/
│   ├── etl_pipeline.py               # 3-layer ETL pipeline
│   └── utils.py                      # Data validation & helpers
├── notebooks/
│   └── exploration.ipynb             # Exploratory Data Analysis
├── dashboard/
│   └── dashboard360.pbix             # Power BI dashboard
├── docs/
│   ├── data_dictionary.md            # Column-level documentation
│   ├── bus_matrix.md                 # Kimball Bus Matrix
│   └── metrics_glossary.md           # Business metrics & formulas
└── README.md
```

## How to Run

### Prerequisites
- PostgreSQL 14+
- Python 3.9+
- Power BI Desktop

### Steps

**1. Create the database:**
```bash
createdb retail360_dwh
```

**2. Create all tables (staging + dimensions + facts):**
```bash
psql -d retail360_dwh -f sql/ddl/create_star_schema.sql
```

**3. Run the ETL pipeline:**
```bash
# Set database URL (optional, defaults to localhost)
export RETAIL360_DB_URL="postgresql://user:pass@localhost:5432/retail360_dwh"

# Execute the pipeline
python scripts/etl_pipeline.py
```

**4. Create analytical views:**
```bash
psql -d retail360_dwh -f sql/transformations/business_metrics.sql
psql -d retail360_dwh -f sql/views/power_bi_views.sql
```

**5. Connect Power BI:**
Open `dashboard/dashboard360.pbix` and point the data source to your PostgreSQL instance.

## Dataset

**Source:** [Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)

| File | Records | Description |
|---|---|---|
| olist_orders_dataset.csv | ~100K | Order header (status, timestamps) |
| olist_order_items_dataset.csv | ~113K | Order items (price, shipping) |
| olist_customers_dataset.csv | ~99K | Customer demographics |
| olist_products_dataset.csv | ~33K | Product catalog |
| olist_sellers_dataset.csv | ~3K | Seller directory |
| olist_order_payments_dataset.csv | ~104K | Payment transactions |
| olist_order_reviews_dataset.csv | ~100K | Customer reviews |
| olist_geolocation_dataset.csv | ~1M | Brazilian zip code locations |
| product_category_name_translation.csv | 71 | PT→EN category mapping |

## Key Insights Demonstrated

- **Customer Segmentation:** RFM analysis identifies that ~5% of customers (Champions) generate disproportionate revenue
- **Retention Patterns:** Cohort analysis reveals monthly retention trends and churn points
- **Pareto Principle:** Validates whether 20% of product categories generate 80% of revenue
- **Logistics Impact:** Correlates late deliveries with lower review scores by geographic region
- **Seller Quality:** Composite scoring enables data-driven vendor management decisions
- **Payment Behavior:** Installment patterns reveal credit dependency and affordability signals

## License

This project uses the [Olist Brazilian E-Commerce dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) under the CC BY-NC-SA 4.0 license.
