# Business Metrics Glossary — Retail360 Intelligence

## Customer Analytics

### RFM Segmentation
Segments customers based on purchasing behavior using three dimensions:

| Dimension | Definition | Formula |
|---|---|---|
| **Recency (R)** | Days since last purchase | `reference_date - MAX(purchase_date)` |
| **Frequency (F)** | Number of distinct orders | `COUNT(DISTINCT order_id)` |
| **Monetary (M)** | Total spend amount | `SUM(total_order_value)` |

**Scoring:** Each dimension scored 1–5 using `NTILE(5)` percentile bucketing.

| Segment | Criteria | Recommended Action |
|---|---|---|
| Champions | R≥4, F≥4, M≥4 | Reward & Retain |
| Loyal Customers | R≥4, F≥3 | Upsell premium products |
| New Customers | R≥4, F≤2 | Onboarding campaign |
| At Risk | R=2, F≥3 | Win-back campaign |
| Cannot Lose Them | R=1, F≥3 | Urgent retention offer |
| Hibernating | R=1, F≤2 | Re-engagement email |

---

### Cohort Retention
Tracks percentage of customers from a given acquisition month who return in subsequent months.

**Formula:**
```
Retention Rate = Active Customers in Month N / Cohort Size × 100
```
- **Cohort Month:** Month of a customer's first purchase
- **Month Number:** Months elapsed since first purchase
- **Benchmark:** >10% retention at Month 6 is considered healthy for e-commerce

---

### Customer Lifetime Value (CLV)
Estimated total revenue a customer will generate over their relationship lifecycle.

**Formula:**
```
CLV (2yr) = Avg Order Value × (Annual Purchase Frequency) × 2
Annual Purchase Frequency = Total Orders / (Customer Lifespan in Days / 365.25)
```
- **CLV Tier:** 1–5 scale based on historical total revenue (NTILE bucketing)
- **Use Case:** Prioritize marketing spend on High-CLV customers

---

## Revenue Analytics

### Month-over-Month (MoM) Growth
Percentage change in revenue compared to the previous month.

**Formula:**
```
MoM Growth % = (Current Month Revenue - Previous Month Revenue) / Previous Month Revenue × 100
```

### Year-over-Year (YoY) Growth
Percentage change in revenue compared to the same month last year.

**Formula:**
```
YoY Growth % = (Current Month Revenue - Same Month Last Year Revenue) / Same Month Last Year Revenue × 100
```

### Year-to-Date (YTD) Revenue
Cumulative revenue from January 1st to the current month within the same year.

---

## Product Analytics

### Pareto Analysis (80/20 Rule)
Identifies which small percentage of product categories generates the majority of revenue.

**Formula:**
```
Cumulative Revenue % = Running Sum of Revenue / Total Revenue × 100
```
- **Star (Top 80%):** Categories within the cumulative 80% threshold
- **Long Tail:** Remaining categories

### BCG Category Matrix
Classifies product categories into four quadrants based on market share and growth:

| Quadrant | Market Share | Growth | Strategy |
|---|---|---|---|
| **Star** | High | High | Invest & grow |
| **Cash Cow** | High | Low | Maintain & harvest |
| **Question Mark** | Low | High | Evaluate potential |
| **Dog** | Low | Low | Consider discontinuing |

---

## Logistics Analytics

### On-Time Delivery (OTD) Rate
Percentage of orders delivered on or before the estimated delivery date.

**Formula:**
```
OTD Rate = Orders Delivered On-Time / Total Delivered Orders × 100
```
- is_late_delivery = `delivered_timestamp > estimated_delivery_date`

### Delivery Delay Days
Number of days beyond the estimated delivery date.

**Formula:**
```
Delay = delivered_timestamp - estimated_delivery_date (in days)
```

### Shipping Cost Ratio
Percentage of total order value consumed by shipping costs.

**Formula:**
```
Shipping Cost Ratio = AVG(shipping_cost / price) × 100
```

---

## Seller Analytics

### Seller Composite Score
Weighted score combining three performance pillars:

| Component | Weight | Source |
|---|---|---|
| Revenue | 40% | NTILE(5) of total revenue |
| Review Rating | 30% | NTILE(5) of average review score |
| On-Time Delivery | 30% | NTILE(5) of OTD percentage |

**Tier Classification:**

| Tier | Score Range |
|---|---|
| Gold | ≥ 4.0 |
| Silver | 3.0 – 3.9 |
| Bronze | 2.0 – 2.9 |
| Needs Improvement | < 2.0 |

---

## Payment Analytics

### Payment Share
Percentage of total transaction value by each payment method.

**Formula:**
```
Payment Share % = Payment Type Value / Total Value in Period × 100
```

### Average Installments
Mean number of installments chosen by customers per payment method — indicates credit behavior and affordability sensitivity.

---

## Market Basket Analytics

### Co-occurrence (Support)
Frequency at which two product categories appear together in the same order.

**Formula:**
```
Support % = Orders containing both A and B / Total Orders × 100
```
- **Minimum threshold:** 10 co-occurrences (to filter noise)
- **Use Case:** Bundling strategies and cross-sell recommendations
