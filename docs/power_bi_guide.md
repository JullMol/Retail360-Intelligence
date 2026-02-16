# Power BI Dashboard — Complete Step-by-Step Guide

## STEP 1: Connect Power BI ke PostgreSQL

1. Buka **Power BI Desktop**
2. Klik **Get Data** → cari **PostgreSQL database**
3. Isi:
   - **Server:** `localhost`
   - **Database:** `retail360_dwh`
4. Pilih **Database** (bukan Windows) untuk authentication
   - **Username:** `postgres`
   - **Password:** *(password kamu)*
5. Pilih mode **Import** (bukan DirectQuery) untuk performa lebih cepat

## STEP 2: Pilih Tables/Views

Centang **semua views** berikut ini:

### Power BI Optimized Views (4 views)
| View | Fungsi |
|---|---|
| `vw_executive_summary` | KPI bulanan (revenue, orders, customers, AOV, reviews, OTD rate) |
| `vw_customer_segments` | RFM segmentation (93K customers) dengan segment_group & recommended_action |
| `vw_geo_performance` | Metrics per state (revenue, orders, delivery, reviews, lat/long untuk map) |
| `vw_monthly_trends` | Time-series: revenue, orders, MoM growth, YTD accumulation |

### Business Analytics Views (6 views tambahan)
| View | Fungsi |
|---|---|
| `view_cohort_retention` | Cohort retention analysis (customer return rate per bulan) |
| `view_customer_ltv` | Customer Lifetime Value estimation (CLV 2 tahun) |
| `view_market_basket` | Market basket / co-occurrence analysis antar kategori produk |
| `view_pareto_analysis` | Pareto 80/20 analysis per kategori produk |
| `view_seller_scorecard` | Seller performance scoring (Gold/Silver/Bronze tier) |
| `view_payment_analysis` | Payment method breakdown, installment behavior |
| `view_category_performance` | BCG Matrix classification (Star/Cash Cow/Question Mark/Dog) |

### Dimension Tables (untuk slicer/filter)
- `dim_date`
- `dim_product`
- `dim_customer`
- `dim_seller`

Klik **Load**.

## STEP 3: Buat Relationships

Di tab **Model**, pastikan relationships ini ada (biasanya auto-detect):

```
vw_executive_summary.year ──── dim_date.year
vw_executive_summary.month ──── dim_date.month
vw_monthly_trends.year ──── dim_date.year
vw_monthly_trends.month ──── dim_date.month
```

Kalau tidak auto-detect, drag-drop manual di Model view.

## STEP 4: Buat DAX Measures

Klik **New Measure** di tab Modeling, lalu buat measures berikut satu per satu:

### KPI Measures
```dax
Total Revenue = SUM(vw_executive_summary[net_revenue])
```

```dax
Total Orders = SUM(vw_executive_summary[total_orders])
```

```dax
Avg Order Value = DIVIDE([Total Revenue], [Total Orders], 0)
```

```dax
Unique Customers = SUM(vw_executive_summary[unique_customers])
```

```dax
Avg Review Score = AVERAGE(vw_executive_summary[avg_satisfaction_score])
```

```dax
OTD Rate Overall = AVERAGE(vw_executive_summary[on_time_delivery_rate])
```

### Growth Measures
```dax
Revenue MoM % = 
VAR _current = SUM(vw_monthly_trends[revenue])
VAR _prev = SUM(vw_monthly_trends[prev_month_revenue])
RETURN DIVIDE(_current - _prev, _prev, 0)
```

```dax
YTD Revenue = SUM(vw_monthly_trends[ytd_revenue])
```

### Customer Segment Measures
```dax
High Value Count = 
CALCULATE(
    COUNTROWS(vw_customer_segments),
    vw_customer_segments[segment_group] = "High Value"
)
```

```dax
At Risk Count = 
CALCULATE(
    COUNTROWS(vw_customer_segments),
    vw_customer_segments[segment_group] = "At Risk"
)
```

```dax
Growth Segment Count = 
CALCULATE(
    COUNTROWS(vw_customer_segments),
    vw_customer_segments[segment_group] = "Growth"
)
```

### Seller Measures
```dax
Gold Sellers = 
CALCULATE(
    COUNTROWS(view_seller_scorecard),
    view_seller_scorecard[seller_tier] = "Gold"
)
```

```dax
Total Active Sellers = COUNTROWS(view_seller_scorecard)
```

### Pareto Measures
```dax
Star Categories = 
CALCULATE(
    COUNTROWS(view_pareto_analysis),
    view_pareto_analysis[pareto_classification] = "Star (Top 80%)"
)
```

---

## STEP 5: Buat Dashboard Pages (7 Pages)

---

### PAGE 1: Executive Summary
> **Data source utama:** `vw_executive_summary` + `vw_monthly_trends` + `vw_geo_performance`

```
┌──────────────────────────────────────────────────────────────┐
│  RETAIL360 COMMAND CENTER                    [Year] [Qtr]   │
├──────┬──────┬──────┬──────┬──────┬───────────────────────────┤
│  💰  │  📦  │  👥  │  ⭐  │  🚚  │                           │
│ Net  │Total │Unique│ Avg  │ OTD  │    Revenue Trend          │
│ Rev  │Orders│Cust  │Review│ Rate │    (Area Chart)           │
│ CARD │ CARD │ CARD │ CARD │ CARD │    vw_monthly_trends      │
├──────┴──────┴──────┴──────┴──────┤    X: month_date          │
│                                  │    Y: revenue             │
│  Revenue by Quarter              ├───────────────────────────┤
│  (Clustered Column Chart)        │  Top 10 States            │
│  X: quarter  Y: net_revenue      │  (Horizontal Bar Chart)   │
│  dari vw_executive_summary       │  vw_geo_performance       │
│                                  │  Y: state                 │
├──────────────────────────────────┤  X: total_revenue         │
│  Orders vs Satisfaction Trend    │                           │
│  (Combo Chart)                   │                           │
│  Columns: total_orders           │                           │
│  Line: avg_satisfaction_score    │                           │
└──────────────────────────────────┴───────────────────────────┘
```

**Step-by-step:**

1. **5 KPI Cards** (baris atas):
   - Klik **Card visual** → drag `net_revenue` dari `vw_executive_summary` → format sebagai Currency (R$)
   - Ulangi untuk `total_orders`, `unique_customers`, `avg_satisfaction_score`, `on_time_delivery_rate`
   - Tambahkan icon emoji atau conditional formatting (hijau jika naik, merah jika turun)

2. **Area Chart — Revenue Trend** (kanan atas):
   - Insert → **Area Chart**
   - X-axis: `month_date` dari `vw_monthly_trends`
   - Y-axis: `revenue` dari `vw_monthly_trends`
   - Tambahkan secondary Y-axis: `ytd_revenue` sebagai Line
   - Format: gradient fill area

3. **Clustered Column Chart — Revenue by Quarter** (kiri tengah):
   - X-axis: `quarter` dari `vw_executive_summary`
   - Y-axis: `net_revenue`
   - Legend: `year` (untuk compare 2017 vs 2018)

4. **Horizontal Bar Chart — Top 10 States** (kanan bawah):
   - Y-axis: `state` dari `vw_geo_performance`
   - X-axis: `total_revenue`
   - Filter: Top N = 10 by `total_revenue`
   - Data labels: ON

5. **Combo Chart — Orders vs Satisfaction** (kiri bawah):
   - X-axis: `month_name` dari `vw_executive_summary`
   - Column Y-axis: `total_orders`
   - Line Y-axis: `avg_satisfaction_score`

6. **Slicers** (pojok kanan atas):
   - Slicer 1: `year` dari `dim_date` → style: Dropdown
   - Slicer 2: `quarter` dari `dim_date` → style: Buttons

---

### PAGE 2: Customer Intelligence
> **Data source utama:** `vw_customer_segments`

```
┌──────────────────────────────────────────────────────────────┐
│  CUSTOMER INTELLIGENCE                       [Year] [State] │
├──────┬──────┬──────┬──────┬──────────────────────────────────┤
│ High │Growth│ At   │ Low  │                                  │
│Value │ Seg  │Risk  │Prior.│   RFM Segment Distribution       │
│ CARD │ CARD │ CARD │ CARD │   (Donut Chart)                  │
├──────┴──────┴──────┴──────┤   Legend: customer_segment       │
│                           │   Values: COUNT of rows          │
│  Customer Value Treemap   ├──────────────────────────────────┤
│  (Treemap Visual)         │   Segment Detail Table           │
│  Group: segment_group     │   (Table Visual)                 │
│  Details: customer_segment│   Columns:                       │
│  Values: SUM(monetary)    │   - customer_segment             │
│                           │   - COUNT (jumlah)               │
├───────────────────────────┤   - AVG monetary                 │
│  RFM Score Distribution   │   - AVG avg_order_value          │
│  (Scatter Plot)           │   - recommended_action           │
│  X: frequency             │                                  │
│  Y: monetary              │                                  │
│  Size: rfm_score          │                                  │
│  Legend: segment_group    │                                  │
└───────────────────────────┴──────────────────────────────────┘
```

**Step-by-step:**

1. **4 KPI Cards** (baris atas):
   - Gunakan DAX measures: `High Value Count`, `Growth Segment Count`, `At Risk Count`
   - Card ke-4: `CALCULATE(COUNTROWS(vw_customer_segments), vw_customer_segments[segment_group] = "Low Priority")`
   - Warna card: 🟢 High Value, 🔵 Growth, 🟡 At Risk, 🔴 Low Priority

2. **Donut Chart — Segment Distribution** (kanan atas):
   - Legend: `customer_segment`
   - Values: Count of `customer_unique_id`
   - Tips: Gunakan 6-8 warna berbeda agar mudah dibedakan

3. **Treemap — Customer Value** (kiri tengah):
   - Group: `segment_group`
   - Details: `customer_segment`
   - Values: `SUM(monetary)`
   - Colors: sesuaikan per segment_group

4. **Table — Segment Detail** (kanan bawah):
   - Columns: `customer_segment`, Count, `AVG(monetary)`, `AVG(avg_order_value)`, `recommended_action`
   - Format: Alternating row colors, header bold
   - Sort by: Count descending

5. **Scatter Plot — RFM Distribution** (kiri bawah):
   - X-axis: `frequency`
   - Y-axis: `monetary`
   - Size: `rfm_score`
   - Color/Legend: `segment_group`
   - Detail: `customer_unique_id` (set ke "Don't summarize")

6. **Slicer:**
   - `customer_state` → Dropdown multi-select

---

### PAGE 3: Revenue Deep-Dive
> **Data source utama:** `vw_monthly_trends` + `view_revenue_trends`

```
┌──────────────────────────────────────────────────────────────┐
│  REVENUE ANALYSIS                            [Year] [Qtr]   │
├──────┬──────┬──────┬─────────────────────────────────────────┤
│ YTD  │ Best │ MoM  │                                         │
│ Rev  │Month │Growth│   Monthly Revenue vs YTD                │
│ CARD │ CARD │ CARD │   (Combo Chart)                         │
├──────┴──────┴──────┤   Columns: revenue                     │
│                    │   Line: ytd_revenue                     │
│  MoM Growth %      │   X: month_date                        │
│  (Waterfall Chart) ├─────────────────────────────────────────┤
│  Category: month   │   Revenue Composition                   │
│  Y: mom_growth_pct │   (Stacked Column Chart)               │
│  dari               │   X: quarter                           │
│  view_revenue_trends│   Y: gross_revenue, total_shipping_cost│
│                    │   Legend: year                          │
├────────────────────┼─────────────────────────────────────────┤
│  Quarterly KPI     │   Revenue vs Customers Scatter          │
│  (Matrix Visual)   │   (Scatter Plot)                        │
│  Rows: year+quarter│   X: unique_customers                  │
│  Values: revenue,  │   Y: total_revenue                      │
│  orders, AOV, MoM% │   Size: total_orders                   │
│                    │   Detail: month_name                    │
└────────────────────┴─────────────────────────────────────────┘
```

**Step-by-step:**

1. **3 KPI Cards:**
   - YTD Revenue: gunakan DAX `YTD Revenue` measure
   - Best Month: `MAXX(vw_monthly_trends, vw_monthly_trends[revenue])`
   - Latest MoM Growth: ambil dari `view_revenue_trends[mom_growth_pct]`

2. **Combo Chart — Revenue vs YTD** (kanan atas):
   - X-axis: `month_date` dari `vw_monthly_trends`
   - Column Y-axis: `revenue`
   - Line Y-axis: `ytd_revenue`
   - Tips: Gunakan secondary axis untuk YTD

3. **Waterfall Chart — MoM Growth** (kiri tengah):
   - Category: `month_name` dari `view_revenue_trends`
   - Values: `mom_growth_pct`
   - Warna: hijau untuk positive, merah untuk negative

4. **Stacked Column — Revenue Composition** (kanan tengah):
   - X-axis: `quarter`
   - Y-axis: `gross_revenue` dan `total_shipping_cost` (stacked)
   - Legend: `year`

5. **Matrix Visual — Quarterly KPI** (kiri bawah):
   - Rows: `year`, `quarter`
   - Values: `total_revenue`, `total_orders`, `avg_order_value`, `mom_growth_pct`
   - Conditional formatting: data bars untuk revenue, icon sets untuk growth

6. **Scatter Plot — Revenue vs Customers** (kanan bawah):
   - X: `unique_customers`, Y: `total_revenue`, Size: `total_orders`
   - Detail: `month_name`

---

### PAGE 4: Logistics & Geo Performance
> **Data source utama:** `vw_geo_performance` + `view_logistics_performance`

```
┌──────────────────────────────────────────────────────────────┐
│  LOGISTICS PERFORMANCE                       [Year] [State] │
├──────┬──────┬──────┬─────────────────────────────────────────┤
│ OTD  │ Avg  │ Late │                                         │
│ Rate │Deliv.│ Del. │   Brazil Map                            │
│  %   │ Days │Count │   (Filled Map / Shape Map)              │
│ CARD │ CARD │ CARD │   Location: state                       │
├──────┴──────┴──────┤   Color saturation: total_revenue       │
│                    │   Tooltips: avg_delivery_days,           │
│  OTD Rate by State │             late_delivery_pct,          │
│  (Bar Chart)       │             avg_review_score            │
│  Y: state          ├─────────────────────────────────────────┤
│  X: late_delivery  │   State Performance Matrix              │
│     _pct           │   (Matrix Visual)                       │
│  Sort: ascending   │   Rows: state                           │
│  (worst first)     │   Values:                               │
├────────────────────┤   - total_revenue                       │
│  Delivery vs Review│   - total_orders                        │
│  (Scatter Plot)    │   - avg_delivery_days                   │
│  X: avg_delivery   │   - late_delivery_pct                   │
│     _days          │   - avg_review_score                    │
│  Y: avg_review     │   - avg_shipping_cost                   │
│     _score         │   Conditional formatting:               │
│  Size: total_orders│   - 🔴 late_delivery_pct > 10%          │
│  Detail: state     │   - 🟢 avg_review_score >= 4.0          │
└────────────────────┴─────────────────────────────────────────┘
```

**Step-by-step:**

1. **3 KPI Cards:**
   - OTD Rate: `AVERAGE(vw_geo_performance[late_delivery_pct])` → format 100 - pct = OTD
   - Avg Delivery Days: `AVERAGE(vw_geo_performance[avg_delivery_days])`
   - Late Deliveries: total dari `view_logistics_performance[late_deliveries]`

2. **Filled Map — Brazil** (kanan atas):
   - Location: `state` dari `vw_geo_performance`
   - Color saturation: `total_revenue`
   - Tooltips: tambahkan `avg_delivery_days`, `late_delivery_pct`, `avg_review_score`
   - Tips: Di Format → Map settings → pilih "Brazil" sebagai region

3. **Bar Chart — Late Delivery % by State** (kiri tengah):
   - Y-axis: `customer_state` dari `view_logistics_performance`
   - X-axis: `late_delivery_pct`
   - Sort: descending by `late_delivery_pct` (worst state di atas)
   - Reference line: tambahkan average line

4. **Scatter Plot — Delivery vs Review Correlation** (kiri bawah):
   - X-axis: `avg_delivery_days`
   - Y-axis: `avg_review_score`
   - Size: `total_orders`
   - Detail/Legend: `state`
   - Trend line: ON (harusnya menunjukkan korelasi negatif)

5. **Matrix Visual — State Performance** (kanan bawah):
   - Rows: `state`
   - Values: `total_revenue`, `total_orders`, `avg_delivery_days`, `late_delivery_pct`, `avg_review_score`, `avg_shipping_cost`
   - Conditional formatting:
     - `late_delivery_pct`: background color scale (hijau → merah)
     - `avg_review_score`: icon set (bintang)
     - `total_revenue`: data bars

---

### PAGE 5: Product Analytics
> **Data source utama:** `view_pareto_analysis` + `view_category_performance` + `view_market_basket`

```
┌──────────────────────────────────────────────────────────────┐
│  PRODUCT ANALYTICS                           [Year]         │
├──────┬──────┬──────┬─────────────────────────────────────────┤
│ Star │Total │ Top  │                                         │
│ Cat. │Categ.│ Rev  │   Pareto Chart (80/20)                  │
│Count │      │ Cat  │   (Combo Chart)                         │
│ CARD │ CARD │ CARD │   X: category (ranked)                  │
├──────┴──────┴──────┤   Column Y: revenue_share_pct           │
│                    │   Line Y: cumulative_revenue_pct        │
│  BCG Matrix        │   Reference line: 80%                   │
│  (Scatter Plot)    ├─────────────────────────────────────────┤
│  X: market_share   │                                         │
│     _pct           │   Category Revenue Table                │
│  Y: growth_rate    │   (Table Visual)                        │
│     _pct           │   - category                            │
│  Size: total_orders│   - total_revenue                       │
│  Color:            │   - revenue_share_pct                   │
│    bcg_classific.  │   - cumulative_revenue_pct              │
│  Quadrant lines at │   - pareto_classification               │
│  median X & Y      │   - bcg_classification                  │
├────────────────────┤   - avg_review_score                    │
│  Market Basket     │                                         │
│  (Matrix Visual)   │                                         │
│  Rows: product_a   │                                         │
│  Cols: product_b   │                                         │
│  Values:           │                                         │
│  co_occurrence_cnt │                                         │
└────────────────────┴─────────────────────────────────────────┘
```

**Step-by-step:**

1. **3 KPI Cards:**
   - Star Categories: gunakan DAX `Star Categories` measure
   - Total Categories: `COUNTROWS(view_pareto_analysis)`
   - Top Revenue Category: `TOPN(1, view_pareto_analysis, view_pareto_analysis[total_revenue], DESC)`

2. **Combo Chart — Pareto 80/20** (kanan atas):
   - X-axis: `category` dari `view_pareto_analysis` → sort by `rank_position`
   - Column Y: `revenue_share_pct`
   - Line Y: `cumulative_revenue_pct`
   - Tambahkan **Constant Line** di Y = 80 (referensi Pareto)
   - Warna column: beda warna untuk "Star (Top 80%)" vs "Long Tail"

3. **Scatter Plot — BCG Matrix** (kiri tengah):
   - X-axis: `market_share_pct` dari `view_category_performance`
   - Y-axis: `growth_rate_pct`
   - Size: `total_orders`
   - Legend/Color: `bcg_classification`
   - Tambahkan **Reference Lines** di median X dan median Y → membentuk 4 kuadran
   - Label tiap kuadran: Star ⭐, Cash Cow 🐄, Question Mark ❓, Dog 🐕

4. **Table — Category Performance** (kanan bawah):
   - Join data dari `view_pareto_analysis` dan `view_category_performance`
   - Columns: category, total_revenue, revenue_share_pct, cumulative_revenue_pct, pareto_classification, bcg_classification, avg_review_score
   - Conditional formatting: icon untuk bcg_classification

5. **Matrix — Market Basket** (kiri bawah):
   - Rows: `product_a` dari `view_market_basket`
   - Columns: `product_b`
   - Values: `co_occurrence_count`
   - Conditional formatting: heatmap (background color scale)
   - Filter: Top 15 pairs by `co_occurrence_count`

---

### PAGE 6: Seller Performance
> **Data source utama:** `view_seller_scorecard`

```
┌──────────────────────────────────────────────────────────────┐
│  SELLER PERFORMANCE                          [State] [Tier] │
├──────┬──────┬──────┬──────┬──────────────────────────────────┤
│ Gold │Silver│Bronze│Needs │                                  │
│ Sel. │ Sel. │ Sel. │Impr. │   Seller Tier Distribution       │
│ CARD │ CARD │ CARD │ CARD │   (Donut Chart)                  │
├──────┴──────┴──────┴──────┤   Legend: seller_tier            │
│                           │   Values: COUNT sellers          │
│  Seller Score Breakdown   │   Colors: 🥇🥈🥉🔴               │
│  (Stacked Bar Chart)     ├──────────────────────────────────┤
│  Y: seller_id (top 20)   │                                  │
│  X: revenue_score,        │   Seller Detail Table            │
│     review_score_rank,    │   (Table Visual)                 │
│     otd_score             │   - seller_id                    │
│  (stacked components)     │   - seller_city, seller_state    │
├───────────────────────────┤   - total_orders                 │
│  Revenue vs Quality       │   - total_revenue                │
│  (Scatter Plot)           │   - avg_review_score             │
│  X: total_revenue         │   - on_time_delivery_pct         │
│  Y: avg_review_score      │   - composite_score              │
│  Size: total_orders       │   - seller_tier                  │
│  Color: seller_tier       │                                  │
└───────────────────────────┴──────────────────────────────────┘
```

**Step-by-step:**

1. **4 KPI Cards:**
   - Gold Sellers: DAX `Gold Sellers`
   - Silver: `CALCULATE(COUNTROWS(view_seller_scorecard), view_seller_scorecard[seller_tier] = "Silver")`
   - Bronze: sama pattern
   - Needs Improvement: sama pattern
   - Warna: Gold = #FFD700, Silver = #C0C0C0, Bronze = #CD7F32, Needs Impr. = #E94560

2. **Donut Chart — Tier Distribution** (kanan atas):
   - Legend: `seller_tier`
   - Values: Count of `seller_id`
   - Colors: sesuai tier

3. **Stacked Bar Chart — Score Breakdown** (kiri tengah):
   - Y-axis: `seller_id` (Top 20 by composite_score)
   - X-axis: `revenue_score`, `review_score_rank`, `otd_score` (stacked)
   - Gunakan 3 warna berbeda untuk tiap component score

4. **Scatter Plot — Revenue vs Quality** (kiri bawah):
   - X: `total_revenue`
   - Y: `avg_review_score`
   - Size: `total_orders`
   - Color/Legend: `seller_tier`

5. **Table — Seller Detail** (kanan bawah):
   - Columns: seller_id, seller_state, total_orders, total_revenue, avg_review_score, on_time_delivery_pct, composite_score, seller_tier
   - Conditional formatting: color by seller_tier
   - Sort: composite_score DESC

6. **Slicers:**
   - `seller_state` → Dropdown
   - `seller_tier` → Buttons (Gold, Silver, Bronze, Needs Improvement)

---

### PAGE 7: Payment & Cohort Analytics
> **Data source utama:** `view_payment_analysis` + `view_cohort_retention` + `view_customer_ltv`

```
┌──────────────────────────────────────────────────────────────┐
│  PAYMENT & CUSTOMER LIFECYCLE                [Year]         │
├──────────────────────────────┬───────────────────────────────┤
│  Payment Method Share        │   Payment Trend over Time     │
│  (Donut Chart)               │   (Stacked Area Chart)        │
│  Legend: payment_type        │   X: year + month             │
│  Values: total_payment_value │   Y: total_payment_value      │
│                              │   Legend: payment_type         │
├──────────────────────────────┼───────────────────────────────┤
│  Avg Installments by Method  │   Cohort Retention Heatmap    │
│  (Clustered Bar Chart)       │   (Matrix Visual)             │
│  Y: payment_type             │   Rows: cohort_month          │
│  X: avg_installments         │   Columns: month_number       │
│  Data labels: ON             │   Values: retention_rate_pct  │
├──────────────────────────────┤   Conditional Formatting:     │
│  CLV Distribution            │   Background color scale      │
│  (Histogram/Column Chart)    │   (dark green → light → red)  │
│  X: clv_tier (1-5)          │                               │
│  Y: COUNT of customers      │                               │
│  Secondary Y:                │                               │
│    AVG(estimated_clv_2yr)    │                               │
└──────────────────────────────┴───────────────────────────────┘
```

**Step-by-step:**

1. **Donut Chart — Payment Method Share** (kiri atas):
   - Legend: `payment_type` dari `view_payment_analysis`
   - Values: `SUM(total_payment_value)`
   - Tips: Credit card biasanya dominan ~75%

2. **Stacked Area Chart — Payment Trend** (kanan atas):
   - X-axis: buat calculated column `YYYYMM = year * 100 + month`
   - Y-axis: `total_payment_value`
   - Legend: `payment_type`
   - Menunjukkan evolusi preferensi payment method over time

3. **Clustered Bar Chart — Avg Installments** (kiri tengah):
   - Y-axis: `payment_type`
   - X-axis: `AVG(avg_installments)`
   - Data labels: ON
   - Insight: Credit card punya installment tertinggi, boleto = 1

4. **Matrix / Heatmap — Cohort Retention** (kanan tengah + bawah):
   - Rows: `cohort_month` dari `view_cohort_retention`
   - Columns: `month_number` (0, 1, 2, 3, ... sampai 12+)
   - Values: `retention_rate_pct`
   - **Conditional Formatting:** Background color scale
     - 100% = dark green (#00B050)
     - 50% = yellow
     - 0% = red (#E94560)
   - Tips: Month 0 selalu 100%, perhatikan penurunan di month 1-2

5. **Combo Chart — CLV Distribution** (kiri bawah):
   - X-axis: `clv_tier` (1-5) dari `view_customer_ltv`
   - Column Y: `COUNT(customer_unique_id)`
   - Line Y: `AVG(estimated_clv_2yr)` (secondary axis)
   - Insight: Tier 5 punya CLV tertinggi tapi customer count terkecil

---

## STEP 6: Formatting & Theme

### Color Palette (Dark Theme)
| Element | Hex Code | Usage |
|---|---|---|
| Background | `#0F0F23` | Page background |
| Card/Panel | `#1A1A3E` | Visual containers |
| Primary | `#0D47A1` | Primary bars & fills |
| Accent 1 | `#00BFA6` | Positive values, OTD |
| Accent 2 | `#E94560` | Negative values, alerts |
| Accent 3 | `#FFD700` | Gold tier, highlights |
| Accent 4 | `#7C4DFF` | Secondary charts |
| Text Primary | `#FFFFFF` | Headers, labels |
| Text Secondary | `#B0BEC5` | Subtitles, axis |

### Fonts
| Element | Font | Size |
|---|---|---|
| Page Title | Segoe UI Bold | 20pt |
| Section Title | Segoe UI Semibold | 14pt |
| Card Value | Segoe UI Bold | 28pt |
| Card Label | Segoe UI Light | 10pt |
| Body/Axis | Segoe UI | 10pt |
| Table Header | Segoe UI Semibold | 10pt |

### Global Slicer (Tambahkan di setiap page)
- **Year** slicer → Dropdown (dari `dim_date`)
- **Quarter** slicer → Tile/Buttons (dari `dim_date`)
- Taruh di **pojok kanan atas** setiap page, posisi konsisten

### Pro Tips
1. **Sync Slicers**: Format → Sync Slicers → centang semua pages agar Year/Quarter filter apply ke semua page sekaligus
2. **Navigation Buttons**: Tambahkan button row di bagian bawah setiap page untuk navigasi antar page
3. **Tooltips**: Gunakan custom tooltip pages untuk informasi tambahan saat hover
4. **Bookmarks**: Buat bookmark untuk "default view" dan "detail view" per page
5. **Mobile Layout**: Di View → Mobile Layout, susun versi mobile untuk setiap page

---

## STEP 7: Page Navigation

Buat navigation bar di setiap page:

```
┌────────┬────────┬────────┬────────┬────────┬────────┬────────┐
│Executive│Customer│Revenue │Logistic│Product │Seller  │Payment │
│Summary │Intel.  │Deep    │& Geo   │Analytic│Perform.│& Cohort│
└────────┴────────┴────────┴────────┴────────┴────────┴────────┘
```

1. Insert → **Buttons** → Blank
2. Di setiap button, set **Action** → Type: Page Navigation → Destination: target page
3. Style: dark background, white text, hover effect dengan accent color
4. Copy-paste bar ini ke semua 7 pages

---

## STEP 8: Export & Save

1. Save sebagai `dashboard360.pbix` (overwrite yang lama)
2. Untuk screenshot README:
   - File → Export → Export to PDF
   - Atau Print Screen tiap page
3. Commit ke GitHub:
   ```bash
   git add dashboard/dashboard360.pbix
   git commit -m "feat: complete Power BI dashboard with 7 pages"
   git push
   ```

---

## Quick Reference: View ↔ Page Mapping

| Page | Primary View(s) | Secondary View(s) |
|---|---|---|
| 1. Executive Summary | `vw_executive_summary`, `vw_monthly_trends` | `vw_geo_performance` |
| 2. Customer Intelligence | `vw_customer_segments` | — |
| 3. Revenue Deep-Dive | `vw_monthly_trends`, `view_revenue_trends` | `vw_executive_summary` |
| 4. Logistics & Geo | `vw_geo_performance`, `view_logistics_performance` | — |
| 5. Product Analytics | `view_pareto_analysis`, `view_category_performance` | `view_market_basket` |
| 6. Seller Performance | `view_seller_scorecard` | — |
| 7. Payment & Cohort | `view_payment_analysis`, `view_cohort_retention` | `view_customer_ltv` |
