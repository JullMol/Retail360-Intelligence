# Retail360 Power BI Dashboard Guide
## Light Theme — DataFlip-Inspired Design

---

## 🎨 DESIGN SYSTEM (Baca Dulu!)

### Color Palette — Light Theme
| Element | Hex | Usage |
|---|---|---|
| Canvas Background | `#F5F5F0` | Page background (cream/off-white) |
| Card Background | `#FFFFFF` | Semua visual cards |
| Card Border | `#E0E0E0` | Border tipis semua cards |
| Primary Accent | `#1565C0` | Bars, lines utama (dark blue) |
| Accent Green | `#00897B` | Positive metrics, OTD |
| Accent Red | `#C62828` | Negative metrics, alerts |
| Accent Orange | `#E65100` | Highlight, secondary bars |
| Accent Purple | `#6A1B9A` | Tertiary charts |
| Text Primary | `#212121` | Judul, nilai utama |
| Text Secondary | `#757575` | Subtitle, axis labels |
| Text Muted | `#BDBDBD` | Grid lines, borders |

### Typography
| Element | Font | Size | Weight |
|---|---|---|---|
| Page Title | Segoe UI | 20pt | Bold |
| Visual Title | Segoe UI | 12pt | Semibold |
| Card Value | Segoe UI | 28pt | Bold |
| Card Label | Segoe UI | 10pt | Regular |
| Axis / Body | Segoe UI | 9pt | Regular |
| Table Header | Segoe UI | 10pt | Semibold |

### Card Design Standard
Untuk **semua** cards dan visuals di setiap page:
- Background: `#FFFFFF`
- Border: **On** → Color `#E0E0E0`, Width 1px
- Rounded corners: **8px**
- Shadow: **On** → Preset "Bottom right" (subtle)
- Title font color: `#212121`
- Title font size: 12pt, Semibold

### Left Sidebar Navigation
Di setiap page, buat sidebar kiri:
1. **Insert** → **Rectangle shape**
   - Width: 160px, Height: full page
   - Fill: `#1565C0` (dark blue)
   - Taruh di sisi kiri
2. **Insert** → **Text Box** untuk logo/title:
   - "RETAIL360" → font Segoe UI Bold 14pt, white
   - Taruh di atas sidebar
3. **Insert** → **Buttons** (4 buttons navigasi):
   - "📊 Overview"
   - "👥 Customers"
   - "🚚 Logistics"
   - "💰 Revenue"
   - Style: transparent background, white text, 12pt
   - **Action** → Page Navigation → masing-masing page
4. **Insert** → **Slicer** di bawah buttons:
   - `year` dari `vw_executive_summary`
   - Style: Dropdown
   - Label: "Select Year"
   - Background: semi-transparent white

---

## ⚙️ SETUP: Import Data & Relationships

### Tables yang Diimport
| Table/View | Fungsi |
|---|---|
| `vw_executive_summary` | KPI bulanan (revenue, orders, customers, OTD) |
| `vw_customer_segments` | RFM segmentation 93K customers |
| `vw_geo_performance` | Metrics per state (revenue, delivery, review) |
| `vw_monthly_trends` | Time-series: revenue, MoM, YTD |
| `dim_date` | Dimensi tanggal untuk slicer |
| `fact_orders` | Fact table untuk State Revenue measure |
| `dim_customer` | Dimensi customer (customer_state) |

### Relationships (di Model View)
Drag-drop di tab **Model**:

| From | To | Cardinality | Direction |
|---|---|---|---|
| `vw_executive_summary[year]` | `vw_monthly_trends[year]` | Many-to-many | Both |
| `vw_executive_summary[month]` | `vw_monthly_trends[month]` | Many-to-many | Both |
| `fact_orders[purchase_date_key]` | `dim_date[date_key]` | Many-to-one | Single |
| `fact_orders[customer_key]` | `dim_customer[customer_key]` | Many-to-one | Single |

### DAX Measures (Buat di tab Modeling → New Measure)

**Simpan semua measures ke table `vw_executive_summary`** (select table-nya dulu sebelum klik New Measure):

```dax
Total Revenue = SUM(vw_executive_summary[net_revenue])
```
```dax
Total Orders = SUM(vw_executive_summary[total_orders])
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
```dax
Avg Order Value = DIVIDE([Total Revenue], [Total Orders], 0)
```
```dax
Revenue MoM % =
VAR _current = SUM(vw_monthly_trends[revenue])
VAR _prev = SUM(vw_monthly_trends[prev_month_revenue])
RETURN DIVIDE(_current - _prev, _prev, 0)
```
```dax
YTD Revenue = SUM(vw_monthly_trends[ytd_revenue])
```
```dax
State Revenue =
CALCULATE(
    SUM(fact_orders[total_order_value]),
    fact_orders[order_status_raw] = "delivered"
)
```

**Measures untuk Customer page** (simpan ke `vw_customer_segments`):
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
Growth Count =
CALCULATE(
    COUNTROWS(vw_customer_segments),
    vw_customer_segments[segment_group] = "Growth"
)
```
```dax
Low Priority Count =
CALCULATE(
    COUNTROWS(vw_customer_segments),
    vw_customer_segments[segment_group] = "Low Priority"
)
```

---

## 📊 PAGE 1: Executive Summary

### Layout
```
┌────────┬────────────────────────────────────────────────────┐
│        │  RETAIL360 COMMAND CENTER          [Last Updated]  │
│ LEFT   ├──────┬──────┬──────┬──────┬───────────────────────┤
│ SIDE   │ 💰   │ 📦   │ 👥   │ ⭐   │ 🚚                    │
│ BAR    │ Rev  │Order │Cust  │Review│ OTD                   │
│        │ CARD │ CARD │ CARD │ CARD │ CARD                  │
│ 📊     ├──────┴──────┴──────┴──────┴───────────────────────┤
│ Over.  │                           │                        │
│ 👥     │  Revenue by Quarter       │  Revenue Trend         │
│ Cust.  │  (Clustered Column)       │  (Area Chart)          │
│ 🚚     │  X: quarter               │  X: month_date         │
│ Logi.  │  Y: net_revenue           │  Y: revenue            │
│ 💰     │  Legend: year             │  (+ ytd as line)       │
│ Rev.   ├───────────────────────────┼────────────────────────┤
│        │  Orders vs Satisfaction   │  Top 10 States         │
│ [Year] │  (Line Chart)             │  (Bar Chart)           │
│ Slicer │  X: month_name            │  Y: customer_state     │
│        │  Y: total_orders          │  X: State Revenue      │
└────────┴───────────────────────────┴────────────────────────┘
```

### Step-by-Step Build

**A. Canvas Setup:**
1. Klik area kosong → **Format page** → Canvas background → `#F5F5F0`
2. Buat sidebar kiri (lihat Design System di atas)
3. **Insert** → **Text Box** di header area (kanan sidebar):
   - Text: `RETAIL360 COMMAND CENTER`
   - Font: Segoe UI Bold, 20pt, color `#212121`

**B. 5 KPI Cards (baris atas):**

> Icon: Baris 4, kolom 1 di panel Visualizations

Untuk setiap card:
- Klik **Card** visual
- Drag field ke **Fields**
- Format → General → Title: **On**, text sesuai label
- Format → Callout value → Font size: **28pt**, color `#1565C0`
- Format → General → Effects → Background: `#FFFFFF`
- Format → General → Effects → Visual border: `#E0E0E0`, rounded 8px
- Format → General → Effects → Shadow: **On**

| Card | Field | Label | Value Color |
|---|---|---|---|
| 1 | `net_revenue` dari `vw_executive_summary` | Total Revenue | `#1565C0` |
| 2 | `total_orders` dari `vw_executive_summary` | Total Orders | `#1565C0` |
| 3 | `unique_customers` dari `vw_executive_summary` | Unique Customers | `#1565C0` |
| 4 | `avg_satisfaction_score` → **Average** | Avg Review Score | `#00897B` |
| 5 | `on_time_delivery_rate` → **Average** | OTD Rate % | `#00897B` |

> ⚠️ Untuk Card 4 & 5: klik dropdown field di visual → pilih **Average** (bukan Sum)

**C. Clustered Column Chart — Revenue by Quarter:**

> Icon: Baris 1, kolom 1 di panel Visualizations (bars vertikal)

1. Klik **Clustered column chart**
2. **X-axis:** `quarter` dari `vw_executive_summary`
3. **Y-axis:** `net_revenue` dari `vw_executive_summary`
4. **Legend:** `year` dari `vw_executive_summary`
5. Format:
   - Title: `Revenue by Quarter`
   - Data colors: 2016=`#BBDEFB`, 2017=`#1565C0`, 2018=`#E65100`
   - Background: `#FFFFFF`, border `#E0E0E0`, rounded 8px
   - X-axis color: `#757575`, Y-axis color: `#757575`
   - Grid lines: color `#F0F0F0` (very subtle)
6. Taruh di **kiri tengah**

**D. Area Chart — Revenue Trend:**

> Icon: Baris 2, kolom 2 di panel Visualizations

1. Klik **Area chart**
2. **X-axis:** `month_date` dari `vw_monthly_trends`
3. **Y-axis:** `revenue` dari `vw_monthly_trends`
4. Format:
   - Title: `Revenue Trend`
   - Line color: `#1565C0`
   - Area fill: `#BBDEFB` (light blue, 50% transparency)
   - Background: `#FFFFFF`, border, rounded 8px
5. Taruh di **kanan tengah**

**E. Line Chart — Orders vs Satisfaction:**

> Icon: Baris 2, kolom 1 di panel Visualizations

1. Klik **Line chart**
2. **X-axis:** `month_name` dari `vw_executive_summary`
3. **Y-axis:** `total_orders`
4. **Secondary Y-axis:** `avg_satisfaction_score`
5. Fix sorting: klik `...` → Sort axis → `month` ascending
6. Format:
   - Title: `Orders vs Satisfaction Trend`
   - Orders line: `#1565C0`
   - Satisfaction line: `#E65100` (dotted)
   - Background: `#FFFFFF`, border, rounded 8px
7. Taruh di **kiri bawah**

**F. Bar Chart — Top 10 States:**

> Icon: Baris 1, kolom 2 di panel Visualizations (bars horizontal)

1. Klik **Clustered bar chart** (horizontal)
2. **Y-axis:** `customer_state` dari `dim_customer`
3. **X-axis:** measure `State Revenue`
4. Filter Top 10:
   - Panel Filters → drag `State Revenue` → Filter type: **Top N**
   - Show items: **10**, By value: `State Revenue` → Apply
5. Format:
   - Title: `Top 10 States by Revenue`
   - Bar color: `#1565C0`
   - Data labels: **On**, color `#212121`
   - Background: `#FFFFFF`, border, rounded 8px
   - Sort: descending by `State Revenue`
6. Taruh di **kanan bawah**

**G. Apply ke Semua Visual:**
- Pastikan semua 5 cards + 4 charts punya background `#FFFFFF` dan border `#E0E0E0`
- Semua title font: Segoe UI Semibold, 12pt, color `#212121`
- Semua axis labels: color `#757575`, 9pt

---

## 👥 PAGE 2: Customer Intelligence

### Layout
```
┌────────┬────────────────────────────────────────────────────┐
│        │  CUSTOMER INTELLIGENCE                             │
│ LEFT   ├──────┬──────┬──────┬──────┬───────────────────────┤
│ SIDE   │ High │Growth│ At   │ Low  │                        │
│ BAR    │ Value│ Seg  │ Risk │Prior.│  RFM Segment Donut     │
│        │ CARD │ CARD │ CARD │ CARD │  (Donut Chart)         │
│        ├──────┴──────┴──────┴──────┤  Legend: segment       │
│        │                           │  Values: Count         │
│        │  Customer Value Treemap   ├────────────────────────┤
│        │  Group: segment_group     │  Segment Detail Table  │
│        │  Details: customer_segment│  - customer_segment    │
│        │  Values: SUM(monetary)    │  - Count               │
│        ├───────────────────────────┤  - AVG monetary        │
│        │  RFM Scatter Plot         │  - recommended_action  │
│        │  X: frequency             │                        │
│        │  Y: monetary              │                        │
│        │  Size: rfm_score          │                        │
└────────┴───────────────────────────┴────────────────────────┘
```

### Step-by-Step Build

**A. Canvas & Sidebar:**
- Canvas background: `#F5F5F0`
- Copy sidebar dari Page 1 (Ctrl+C di Page 1, Ctrl+V di Page 2)
- Title: `CUSTOMER INTELLIGENCE`

**B. 4 KPI Cards (baris atas):**

| Card | Measure | Label | Value Color |
|---|---|---|---|
| 1 | `High Value Count` | High Value | `#00897B` (green) |
| 2 | `Growth Count` | Growth Segment | `#1565C0` (blue) |
| 3 | `At Risk Count` | At Risk | `#E65100` (orange) |
| 4 | `Low Priority Count` | Low Priority | `#757575` (grey) |

Format sama seperti Page 1 (white background, border, shadow).

**C. Donut Chart — RFM Segment Distribution:**

> Icon: Baris 4, kolom 5 di panel Visualizations (lingkaran dengan lubang)

1. Klik **Donut chart**
2. **Legend:** `customer_segment` dari `vw_customer_segments`
3. **Values:** `customer_unique_id` → ganti ke **Count**
4. Format:
   - Title: `RFM Segment Distribution`
   - Detail labels: **On**, Position: **Outside**, font 9pt, color `#212121`
   - Leader lines: **On**
   - Legend: **Right**, font 9pt
   - Background: `#FFFFFF`, border `#E0E0E0`, rounded 8px
5. Taruh di **kanan atas** (ukuran besar)

**D. Treemap — Customer Value:**

> Icon: Baris 4, kolom 3 di panel Visualizations

1. Klik **Treemap**
2. **Group:** `segment_group` dari `vw_customer_segments`
3. **Details:** `customer_segment`
4. **Values:** `monetary` → **Sum**
5. Format:
   - Title: `Customer Value by Segment`
   - Data colors:
     - High Value: `#1565C0`
     - Growth: `#00897B`
     - At Risk: `#E65100`
     - Low Priority: `#BDBDBD`
   - Category labels: **On**, font 10pt, color white
   - Background: `#FFFFFF`, border, rounded 8px
6. Taruh di **kiri tengah**

**E. Scatter Plot — RFM Distribution:**

> Icon: Baris 3, kolom 3 di panel Visualizations (titik-titik tersebar)

1. Klik **Scatter chart**
2. **X-axis:** `frequency` dari `vw_customer_segments`
3. **Y-axis:** `monetary` dari `vw_customer_segments`
4. **Size:** `rfm_score`
5. **Legend:** `segment_group`
6. **Details:** `customer_unique_id` → set "Don't summarize"
7. Format:
   - Title: `RFM Score Distribution`
   - Grid lines: **Off** (X dan Y)
   - Markers size: **8**
   - Data colors: sama seperti treemap (per segment_group)
   - Background: `#FFFFFF`, border, rounded 8px
8. Taruh di **kiri bawah**

**F. Table — Segment Detail:**

> Icon: Baris 5, kolom 1 di panel Visualizations

1. Klik **Table**
2. Columns:
   - `customer_segment`
   - `customer_unique_id` → **Count** → rename "Customers"
   - `monetary` → **Average** → rename "Avg Monetary"
   - `recommended_action`
3. Format:
   - Title: `Segment Details & Actions`
   - Grid → Alternating rows: **On**, even row color `#F5F5F5`
   - Column headers: bold, color `#212121`, background `#E3F2FD`
   - Values font: 9pt, color `#212121`
   - Background: `#FFFFFF`, border, rounded 8px
   - Sort: "Customers" descending
4. Taruh di **kanan bawah**

---

## 🚚 PAGE 3: Logistics & Geo

### Layout
```
┌────────┬────────────────────────────────────────────────────┐
│        │  LOGISTICS & GEO PERFORMANCE                       │
│ LEFT   ├──────┬──────┬──────┬──────────────────────────────┤
│ SIDE   │ OTD  │ Avg  │ Late │                              │
│ BAR    │ Rate │Deliv.│ Del. │   Brazil Filled Map           │
│        │  %   │ Days │  %   │   Location: state             │
│        │ CARD │ CARD │ CARD │   Color: total_revenue        │
│        ├──────┴──────┴──────┤   Tooltip: delivery_days,    │
│        │                    │            late_pct, review   │
│        │  Late Delivery %   │                              │
│        │  by State          ├──────────────────────────────┤
│        │  (Bar Chart)       │  State Performance Matrix    │
│        │  Y: state          │  Rows: state                 │
│        │  X: late_delivery  │  Values: revenue, orders,    │
│        │     _pct           │  delivery_days, late_pct,    │
│        │  Sort: desc        │  review_score                │
└────────┴────────────────────┴──────────────────────────────┘
```

### Step-by-Step Build

**A. Canvas & Sidebar:**
- Canvas background: `#F5F5F0`
- Copy sidebar dari Page 1
- Title: `LOGISTICS & GEO PERFORMANCE`

**B. 3 KPI Cards:**

Buat DAX measures dulu (simpan ke `vw_geo_performance`):
```dax
Avg Delivery Days = AVERAGE(vw_geo_performance[avg_delivery_days])
```
```dax
Avg Late Delivery Pct = AVERAGE(vw_geo_performance[late_delivery_pct])
```
```dax
OTD Rate Geo = 100 - [Avg Late Delivery Pct]
```

| Card | Measure | Label | Value Color |
|---|---|---|---|
| 1 | `OTD Rate Geo` | OTD Rate % | `#00897B` |
| 2 | `Avg Delivery Days` | Avg Delivery Days | `#1565C0` |
| 3 | `Avg Late Delivery Pct` | Late Delivery % | `#C62828` |

**C. Filled Map — Brazil:**

> Icon: Baris 5, kolom 4 di panel Visualizations (icon peta)

1. Klik **Filled map**
2. **Location:** `state` dari `vw_geo_performance`
3. **Color saturation:** `total_revenue`
4. **Tooltips:** tambahkan `avg_delivery_days`, `late_delivery_pct`, `avg_review_score`
5. Format:
   - Title: `Revenue by State`
   - Map styles: Light (sesuai light theme)
   - Color scale: light blue → dark blue
   - Background: `#FFFFFF`, border, rounded 8px
6. Taruh di **kanan atas** (ukuran besar)

**D. Bar Chart — Late Delivery % by State:**
1. Klik **Clustered bar chart** (horizontal)
2. **Y-axis:** `state` dari `vw_geo_performance`
3. **X-axis:** `late_delivery_pct`
4. Sort: descending (worst state di atas)
5. Format:
   - Title: `Late Delivery % by State`
   - Bar color: `#C62828` (red — bad metric)
   - Data labels: **On**
   - Background: `#FFFFFF`, border, rounded 8px
6. Taruh di **kiri tengah**

**E. Matrix — State Performance:**
1. Klik **Matrix** visual
2. **Rows:** `state` dari `vw_geo_performance`
3. **Values:**
   - `total_revenue` → rename "Revenue"
   - `total_orders` → rename "Orders"
   - `avg_delivery_days` → rename "Avg Days"
   - `late_delivery_pct` → rename "Late %"
   - `avg_review_score` → rename "Review"
4. **Conditional Formatting** pada `late_delivery_pct`:
   - Background color scale: Green (0%) → Yellow (10%) → Red (20%+)
5. Format:
   - Title: `State Performance Metrics`
   - Row padding: Compact
   - Header: bold, background `#E3F2FD`
   - Alternating rows: **On**
   - Background: `#FFFFFF`, border, rounded 8px
6. Taruh di **kanan bawah**

---

## 💰 PAGE 4: Revenue Deep-Dive

### Layout
```
┌────────┬────────────────────────────────────────────────────┐
│        │  REVENUE DEEP-DIVE                                 │
│ LEFT   ├──────┬──────┬──────┬──────────────────────────────┤
│ SIDE   │ YTD  │ Best │ MoM  │                              │
│ BAR    │ Rev  │Month │Growth│   Monthly Revenue vs YTD     │
│        │ CARD │ CARD │ CARD │   (Area + Line Combo)        │
│        ├──────┴──────┴──────┤   X: month_date              │
│        │                    │   Area: revenue              │
│        │  Quarterly Revenue │   Line: ytd_revenue          │
│        │  Comparison        ├──────────────────────────────┤
│        │  (Clustered Bar)   │  YTD Accumulation            │
│        │  X: quarter        │  (Area Chart)                │
│        │  Y: net_revenue    │  X: month                    │
│        │  Legend: year      │  Y: ytd_revenue              │
└────────┴────────────────────┴──────────────────────────────┘
```

### Step-by-Step Build

**A. Canvas & Sidebar:**
- Canvas background: `#F5F5F0`
- Copy sidebar dari Page 1
- Title: `REVENUE DEEP-DIVE`

**B. 3 KPI Cards:**

Buat DAX measures:
```dax
Best Month Revenue =
MAXX(vw_monthly_trends, vw_monthly_trends[revenue])
```
```dax
Latest MoM Growth =
VAR LastMonth = MAX(vw_monthly_trends[month_date])
RETURN
    CALCULATE(
        MAX(vw_monthly_trends[mom_growth_pct]),
        vw_monthly_trends[month_date] = LastMonth
    )
```

| Card | Measure | Label | Value Color |
|---|---|---|---|
| 1 | `YTD Revenue` | YTD Revenue | `#1565C0` |
| 2 | `Best Month Revenue` | Best Month Revenue | `#00897B` |
| 3 | `Latest MoM Growth` | Latest MoM Growth % | Conditional |

Untuk Card 3 (MoM Growth), tambahkan conditional formatting:
- Format → Callout value → fx → Rules
- If value >= 0 → color `#00897B` (green)
- If value < 0 → color `#C62828` (red)

**C. Area Chart — Revenue vs YTD:**
1. Klik **Area chart**
2. **X-axis:** `month_date` dari `vw_monthly_trends`
3. **Y-axis:** `revenue`
4. **Secondary Y-axis:** `ytd_revenue` (drag ke Y-axis juga, lalu set secondary)
5. Format:
   - Title: `Monthly Revenue vs YTD Accumulation`
   - Revenue area: `#BBDEFB` fill, `#1565C0` line
   - YTD line: `#E65100` (orange dotted)
   - Background: `#FFFFFF`, border, rounded 8px
6. Taruh di **kanan atas** (ukuran besar, lebar)

**D. Clustered Bar Chart — Quarterly Comparison:**
1. Klik **Clustered bar chart** (horizontal)
2. **Y-axis:** `quarter` dari `vw_executive_summary`
3. **X-axis:** `net_revenue`
4. **Legend:** `year`
5. Format:
   - Title: `Revenue by Quarter (Year Comparison)`
   - Colors: 2016=`#BBDEFB`, 2017=`#1565C0`, 2018=`#E65100`
   - Data labels: **On**
   - Background: `#FFFFFF`, border, rounded 8px
6. Taruh di **kiri bawah**

**E. Area Chart — YTD Accumulation:**
1. Klik **Area chart**
2. **X-axis:** `month` dari `vw_monthly_trends`
3. **Y-axis:** `ytd_revenue`
4. Format:
   - Title: `Year-to-Date Revenue Accumulation`
   - Area fill: `#E8F5E9` (light green)
   - Line color: `#00897B` (green)
   - Background: `#FFFFFF`, border, rounded 8px
5. Taruh di **kanan bawah**

---

## 🔗 SYNC SLICERS (Wajib!)

Setelah semua 4 pages selesai:

1. Klik **View** → **Sync slicers**
2. Klik **Year slicer** di Page 1
3. Di panel Sync slicers (kanan):
   - Centang **semua 4 pages** di kolom "Sync"
   - Centang **semua 4 pages** di kolom "Visible"
4. Sekarang Year slicer apply ke semua pages sekaligus

---

## ✅ FINAL CHECKLIST

### Per Page:
- [ ] Canvas background: `#F5F5F0`
- [ ] Sidebar kiri: `#1565C0` dengan 4 navigation buttons
- [ ] Title text box: Segoe UI Bold 20pt, `#212121`
- [ ] Semua cards: background `#FFFFFF`, border `#E0E0E0`, rounded 8px, shadow
- [ ] Semua chart titles: Segoe UI Semibold 12pt, `#212121`
- [ ] Semua axis labels: `#757575`, 9pt
- [ ] Grid lines: `#F0F0F0` (sangat subtle) atau Off

### Global:
- [ ] Slicers synced across all 4 pages
- [ ] Navigation buttons work (test klik)
- [ ] File saved: `dashboard/dashboard360.pbix`

### Commit ke GitHub:
```bash
git add dashboard/dashboard360.pbix
git commit -m "feat: complete Power BI dashboard - light theme, 4 pages"
git push
```
