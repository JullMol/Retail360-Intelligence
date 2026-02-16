# Kimball Bus Matrix — Retail360 Intelligence

The Bus Matrix defines which dimension tables connect to which fact tables, ensuring conformed dimensions across the Data Warehouse.

## Bus Matrix

| Fact Table \ Dimension | dim_date | dim_customer | dim_product | dim_seller | dim_geography | dim_payment_type | dim_order_status |
|---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| **fact_orders** | ✔ | ✔ | ✔ | ✔ | ○ | – | ✔ |
| **fact_payments** | ✔ | ✔ | – | – | – | ✔ | – |

**Legend:**
- ✔ = Direct foreign key relationship
- ○ = Indirect relationship (via dim_customer.zip → dim_geography.zip)
- – = No relationship

## Conformed Dimensions

| Dimension | Shared Across | Conformance Notes |
|---|---|---|
| dim_date | fact_orders, fact_payments | YYYYMMDD integer key format, shared calendar |
| dim_customer | fact_orders, fact_payments | Linked via `customer_key` surrogate; `customer_unique_id` used for cross-order dedup |
| dim_geography | fact_orders (indirect) | Linked through `dim_customer.customer_zip_code` → `dim_geography.zip_code_prefix` |

## Data Flow Diagram

```
┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│   dim_date   │    │ dim_customer │    │ dim_product  │
│  (calendar)  │    │  (who buys)  │    │ (what sold)  │
└──────┬───────┘    └──────┬───────┘    └──────┬───────┘
       │                   │                   │
       ├───────────────────┼───────────────────┤
       │           ┌───────┴───────┐           │
       ├───────────┤  fact_orders  ├───────────┤
       │           │   (grain:     │           │
       │           │  order item)  │           │
       │           └───────┬───────┘           │
       │                   │                   │
┌──────┴───────┐    ┌──────┴───────┐    ┌──────┴───────┐
│ dim_order_   │    │  dim_seller  │    │dim_geography │
│   status     │    │ (who sells)  │    │  (where)     │
└──────────────┘    └──────────────┘    └──────────────┘

       ┌───────────────────┐
       │                   │
┌──────┴───────┐    ┌──────┴───────┐
│   dim_date   │    │ dim_customer │
└──────┬───────┘    └──────┬───────┘
       │           ┌───────┴───────┐
       ├───────────┤fact_payments  │
       │           │   (grain:     │
       │           │  transaction) │
       │           └───────┬───────┘
       │                   │
       │           ┌───────┴───────┐
       │           │dim_payment_   │
       │           │    type       │
       │           └───────────────┘
```

## Drill-Down Paths

| Analysis Area | Drill Path |
|---|---|
| Time | Year → Quarter → Month → Day |
| Geography | State → City → Zip Code |
| Product | Category → Product ID |
| Customer | Segment → Customer unique ID |
| Seller | Tier → Seller ID |
