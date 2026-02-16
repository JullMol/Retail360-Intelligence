# Power BI Dashboard — Complete Build Guide (FROM ZERO)

## ⚙️ SETUP AWAL (Wajib!)

### 1. Import Data ke Power BI

1. Buka **Power BI Desktop**
2. **Get Data** → **PostgreSQL database**
3. Server: `localhost` | Database: `retail360_dwh`
4. Username: `postgres` | Password: `rafizzul00`
5. **Pilih tables berikut:**
   - ✅ `vw_executive_summary`
   - ✅ `vw_customer_segments`
   - ✅ `vw_geo_performance`
   - ✅ `vw_monthly_trends`
   - ✅ `dim_date`
6. Klik **Load**

### 2. Buat Relationships di Model View

1. Klik tab **Model** (icon di sidebar kiri)
2. **Drag and drop** untuk buat 3 relationships:

**Relationship 1:**
- Drag `year` dari **vw_executive_summary**
- Drop ke `year` di **vw_monthly_trends**
- Dialog muncul → set:
  - Cardinality: **Many to many (*:*)**
  - Cross filter direction: **Both**
- Klik **OK**

**Relationship 2:**
- Drag `month` dari **vw_executive_summary**
- Drop ke `month` di **vw_monthly_trends**
- Set: Many to many, Both direction

**Relationship 3:**
- Drag `year` dari **vw_executive_summary**
- Drop ke `fiscal_year` di **dim_date**
- Set: Many to many, Both direction

3. Klik tab **Report** (kembali ke view utama)

---

## 📊 PAGE 1: EXECUTIVE SUMMARY

### Step 1: Rename Page
- Klik kanan tab "Page 1" di bawah → **Rename** → ketik `Executive Summary`

### Step 2: Buat 4 KPI Cards

**Card 1 — Total Revenue:**
1. Klik **Card** visual dari panel Visualizations (kanan)
2. Drag `net_revenue` dari `vw_executive_summary` → drop ke **Fields**
3. Di panel **Format** → **General** → **Title**:
   - Title text: `Total Revenue`
   - Font: Segoe UI Bold, 14pt
4. Format → **Callout value**:
   - Display units: **Millions** (M)
   - Value decimal places: **2**
5. Resize card → taruh **pojok kiri atas**

**Card 2 — Total Orders:**
1. Tambah **Card** baru
2. Drag `total_orders` dari `vw_executive_summary`
3. Title: `Total Orders`
4. Display units: **Thousands** (K)
5. Taruh di **sebelah kanan** Card 1

**Card 3 — Unique Customers:**
1. Tambah **Card** baru
2. Drag `unique_customers` dari `vw_executive_summary`
3. Title: `Unique Customers`
4. Display units: **Thousands** (K)
5. Taruh di **sebelah kanan** Card 2

**Card 4 — Avg Review:**
1. Tambah **Card** baru
2. Drag `avg_satisfaction_score` dari `vw_executive_summary`
3. **PENTING:** Klik dropdown `avg_satisfaction_score` di Fields → ganti dari **Sum** ke **Average**
4. Title: `Avg Review`
5. Display units: **None**
6. Value decimal places: **2**
7. Taruh di **sebelah kanan** Card 3

### Step 3: Line Chart — Revenue Trend

1. Klik **Line chart** dari Visualizations
2. **X-axis:** 
   - Drag `year` dari `vw_monthly_trends` → drop ke X-axis
   - Drag `month_name` dari `vw_monthly_trends` → drop ke X-axis (di bawah year)
3. **Y-axis:**
   - Drag `revenue` dari `vw_monthly_trends`
4. **Format:**
   - Title: `Monthly Revenue Trend`
   - X-axis: hilangkan title (toggle off)
   - Y-axis: change title jadi "Revenue (R$)"
5. Resize → taruh **di tengah/bawah cards** (ukuran horizontal lebar)

### Step 4: Bar Chart — Top 10 States

1. Klik **Clustered bar chart** (horizontal bars)
2. **Y-axis:** `state` dari `vw_geo_performance`
3. **X-axis:** `total_revenue` dari `vw_geo_performance`
4. **Filter visual:**
   - Klik visual → panel Filters → drag `total_revenue` ke **Filters on this visual**
   - Filter type: **Top N**
   - Show items: **Top 10**
   - By value: `total_revenue`
5. **Format:**
   - Title: `Top 10 States by Revenue`
   - Data labels: **On**
   - Sort by: `total_revenue` descending
6. Resize → taruh di **kanan** (sebelah line chart)

### Step 5: Area Chart — Orders per Month

1. Klik **Area chart**
2. **X-axis:** `month_name` dari `vw_executive_summary`
3. **Y-axis:** `total_orders` dari `vw_executive_summary`
4. **PENTING — Fix sorting:**
   - Klik `...` (More options) di pojok visual
   - **Sort axis** → pilih `month` (bukan month_name)
   - **Sort ascending**
5. **Format:**
   - Title: `Orders by Month`
   - Colors → Line: gradient fill
6. Resize → taruh **di bawah line chart**

### Step 6: Slicer — Year Filter

1. Klik **Slicer** visual
2. Drag `year` dari `vw_executive_summary` (BUKAN dari dim_date)
3. **Format:**
   - Slicer settings → Style: **Dropdown**
   - Title: `Year`
4. Taruh di **pojok kanan atas**

### Step 7: Formatting — Dark Theme

**Canvas Background:**
1. Klik area kosong di page
2. **Format page** → **Canvas** → **Canvas background**
3. Color: `#1a1a2e` (dark navy)

**Card Styling (untuk semua 4 cards):**
1. Klik Card 1 → hold **Ctrl** → klik Card 2, 3, 4 (select all)
2. **Format** → **General** → **Effects** → **Background**:
   - Color: `#16213e`
   - Transparency: 0%
3. **Visual border**:
   - Color: `#2a2a4e`
   - Rounded corners: 8px
4. **Title** → Font color: `#ffffff` (white)
5. **Callout value** → Font color: `#00d2d3` (teal)

**Chart Styling (line, bar, area):**
1. Select semua 3 charts (hold Ctrl)
2. **Format** → **General** → **Effects** → **Background**: `#16213e`
3. **Visual border**: sama seperti cards
4. **Title** → Font color: white

**Slicer Styling:**
- Background: `#16213e`
- Border: `#2a2a4e`
- Slicer header font: white

**Title Text Box:**
1. **Insert** → **Text box**
2. Ketik: `RETAIL360 COMMAND CENTER`
3. Font: **Segoe UI Bold**, 20pt
4. Color: `#ffffff`
5. Alignment: **Center**
6. Taruh di **paling atas page**

---

## 👥 PAGE 2: CUSTOMER INTELLIGENCE

### Step 1: Create Page
- Klik **+** (new page) di bawah → rename `Customer Intelligence`

### Step 2: Buat 3 KPI Cards

**Card 1 — High Value Customers:**
1. Klik tab **Modeling** → **New Measure**
2. Ketik DAX:
```dax
High Value Count = 
CALCULATE(
    COUNTROWS(vw_customer_segments),
    vw_customer_segments[segment_group] = "High Value"
)
```
3. Enter → measure muncul di panel Fields
4. Tambah **Card** visual → drag measure `High Value Count`
5. Title: `High Value Customers`
6. Styling: sama seperti Page 1 (background `#16213e`)

**Card 2 — At Risk Customers:**
1. New Measure:
```dax
At Risk Count = 
CALCULATE(
    COUNTROWS(vw_customer_segments),
    vw_customer_segments[segment_group] = "At Risk"
)
```
2. Tambah **Card** → drag `At Risk Count`
3. Title: `At Risk Customers`
4. **Callout value color:** `#e94560` (red — ini warning)

**Card 3 — Growth Segment:**
1. New Measure:
```dax
Growth Count = 
CALCULATE(
    COUNTROWS(vw_customer_segments),
    vw_customer_segments[segment_group] = "Growth"
)
```
2. Tambah **Card** → drag `Growth Count`
3. Title: `Growth Segment`
4. **Callout value color:** `#FFD700` (gold)

### Step 3: Donut Chart — RFM Segment Distribution

1. Klik **Donut chart**
2. **Legend:** `customer_segment` dari `vw_customer_segments`
3. **Values:** `customer_unique_id` dari `vw_customer_segments`
4. **PENTING:** Klik dropdown → change ke **Count** (bukan Sum)
5. **Format:**
   - Title: `Customer Segments`
   - Legend position: **Right**
   - Detail labels: **On** (show percentage)
6. Resize → taruh di **tengah kiri** (ukuran besar)

### Step 4: Treemap — Segment Group Breakdown

1. Klik **Treemap**
2. **Group:** `segment_group` dari `vw_customer_segments`
3. **Details:** `customer_segment`
4. **Values:** `customer_unique_id` → change ke **Count**
5. **Format:**
   - Title: `Segment Groups`
   - Data labels: **All**
   - Category labels: **On**
6. Resize → taruh **di bawah donut chart**

### Step 5: Table — Segment Detail

1. Klik **Table** visual
2. **Columns:**
   - `customer_segment`
   - `segment_group`
   - `recommended_action`
   - Tambahkan: drag `customer_unique_id` → ganti ke Count → rename jadi "Customer Count"
3. **Format:**
   - Title: `Segment Details & Actions`
   - Grid → Alternating rows: **On**
   - Text size: 10pt
4. Resize → taruh di **sebelah kanan** (full height)

### Step 6: Copy Slicer & Apply Theme

1. Balik ke Page 1 → **copy Year slicer** (Ctrl+C)
2. Balik ke Page 2 → paste (Ctrl+V) di posisi yang sama
3. Apply dark theme:
   - Canvas background: `#1a1a2e`
   - Title text box: `CUSTOMER INTELLIGENCE`

---

## 🚚 PAGE 3: LOGISTICS & GEO

### Step 1: Create Page
- New page → rename `Logistics`

### Step 2: Buat 2 KPI Cards

**Card 1 — Avg Delivery Days:**
1. New Measure:
```dax
Avg Delivery = AVERAGE(vw_geo_performance[avg_delivery_days])
```
2. Tambah **Card** → drag measure
3. Title: `Avg Delivery Days`
4. Display units: None, 1 decimal

**Card 2 — OTD Rate:**
1. New Measure:
```dax
OTD Rate = 
VAR LateAvg = AVERAGE(vw_geo_performance[late_delivery_pct])
RETURN 100 - LateAvg
```
2. Tambah **Card** → drag measure
3. Title: `On-Time Delivery %`
4. Value suffix: ` %`
5. **Callout color:** `#00d2d3` (teal — positive metric)

### Step 3: Map — Brazil Geographic Revenue

1. Klik **Filled map** (atau **Shape map** jika ada Brazil map)
2. **Location:** `state` dari `vw_geo_performance`
3. **Tooltips:**
   - Drag `total_revenue`
   - Drag `avg_delivery_days`
   - Drag `avg_review_score`
4. **Color saturation:** `total_revenue`
5. **Format:**
   - Title: `Revenue by State`
   - Map controls: **On**
   - Zoom buttons: **Auto zoom**
6. Resize → taruh di **tengah/kanan** (ukuran besar)

### Step 4: Bar Chart — Late Delivery by State

1. Klik **Clustered bar chart**
2. **Y-axis:** `state` dari `vw_geo_performance`
3. **X-axis:** `late_delivery_pct` dari `vw_geo_performance`
4. **Sort:** klik `...` → Sort descending by `late_delivery_pct`
5. **Filter:** Top 15 (worst states)
6. **Format:**
   - Title: `States with Highest Late Delivery %`
   - Data labels: **On**
   - Bar colors: `#e94560` (red — bad metric)
7. Resize → taruh di **kiri bawah**

### Step 5: Matrix — State Performance Table

1. Klik **Matrix** visual
2. **Rows:** `state` dari `vw_geo_performance`
3. **Values:**
   - `total_revenue` → rename "Revenue"
   - `total_orders` → rename "Orders"
   - `avg_delivery_days` → rename "Avg Days"
   - `late_delivery_pct` → rename "Late %"
   - `avg_review_score` → rename "Avg Review"
4. **Conditional Formatting:**
   - Klik `late_delivery_pct` → Conditional formatting → Background color
   - Gradient: Green (0%) → Yellow (10%) → Red (20%+)
5. **Format:**
   - Title: `State Performance Metrics`
   - Grid → Row padding: Compact
6. Resize → taruh di **kanan bawah**

### Step 6: Apply Theme & Slicer

- Copy slicer dari Page 1
- Canvas background: `#1a1a2e`
- Title: `LOGISTICS & GEO PERFORMANCE`

---

## 💰 PAGE 4: REVENUE DEEP-DIVE

### Step 1: Create Page
- New page → rename `Revenue`

### Step 2: Buat 2 KPI Cards

**Card 1 — YTD Revenue:**
1. New Measure:
```dax
YTD Revenue = 
CALCULATE(
    SUM(vw_monthly_trends[ytd_revenue]),
    LASTDATE(vw_monthly_trends[month])
)
```
2. Tambah **Card** → drag measure
3. Title: `YTD Revenue`
4. Display units: Millions (M)

**Card 2 — Latest MoM Growth:**
1. New Measure:
```dax
Latest MoM = 
VAR LastMonth = MAX(vw_monthly_trends[month])
VAR Growth = 
    CALCULATE(
        MAX(vw_monthly_trends[mom_growth_pct]),
        vw_monthly_trends[month] = LastMonth
    )
RETURN Growth
```
2. Tambah **Card** → drag measure
3. Title: `Latest MoM Growth`
4. Value suffix: ` %`
5. **Conditional formatting:**
   - Callout value → fx → Rules
   - If value >= 0 → color `#00d2d3` (green)
   - If value < 0 → color `#e94560` (red)

### Step 3: Combo Chart — Revenue vs YTD

1. Klik **Line and clustered column chart**
2. **X-axis:** `month` dari `vw_monthly_trends`
3. **Column Y-axis:** `revenue`
4. **Line Y-axis:** `ytd_revenue`
5. **Format:**
   - Title: `Monthly Revenue vs YTD Accumulation`
   - Column color: `#0D47A1` (blue)
   - Line color: `#FFD700` (gold)
   - Data labels: **On** (untuk columns)
6. Resize → taruh di **atas** (horizontal lebar)

### Step 4: Clustered Bar — Quarterly Revenue Comparison

1. Klik **Clustered bar chart**
2. **X-axis:** `quarter` dari `vw_executive_summary`
3. **Y-axis:** `net_revenue`
4. **Legend:** `year`
5. **Format:**
   - Title: `Revenue by Quarter (Year Comparison)`
   - Colors: berbeda untuk 2017 vs 2018
6. Resize → taruh di **kiri bawah**

### Step 5: Area Chart — YTD Accumulation

1. Klik **Area chart**
2. **X-axis:** `month` dari `vw_monthly_trends`
3. **Y-axis:** `ytd_revenue`
4. **Format:**
   - Title: `Year-to-Date Revenue Accumulation`
   - Shade area: gradient fill
   - Color: `#7C4DFF` (purple)
5. Resize → taruh di **kanan bawah**

### Step 6: Apply Theme & Slicer

- Copy slicer dari Page 1
- Canvas background: `#1a1a2e`
- Title: `REVENUE DEEP-DIVE`

---

## 🎨 FINISHING TOUCHES

### 1. Sync Year Slicer Across All Pages

1. Klik **View** → **Sync slicers**
2. Panel muncul di kanan
3. Klik Year slicer di Page 1
4. Di Sync panel → **centang semua 4 pages** (Executive, Customer, Logistics, Revenue)
5. Sekarang slicer akan apply filter ke semua pages sekaligus

### 2. Final Visual Check

Di setiap page, pastikan:
- ✅ Background: `#1a1a2e`
- ✅ All cards/visuals: background `#16213e`
- ✅ Title text box exists & white color
- ✅ Year slicer di posisi konsisten (pojok kanan atas)
- ✅ Semua fonts: white untuk headers, teal/gold untuk values

### 3. Save Dashboard

1. **File** → **Save As**
2. Nama: `dashboard360.pbix`
3. Location: `e:\Project Mandiri\Retail360-Intelligence\dashboard\`
4. Overwrite file lama

---

## ✅ FINAL CHECKLIST

Sebelum selesai, cek ini:

**Page 1 — Executive Summary:**
- [ ] 4 KPI cards (Revenue, Orders, Customers, Avg Review)
- [ ] Line chart revenue trend
- [ ] Bar chart top 10 states
- [ ] Area chart orders by month
- [ ] Year slicer working

**Page 2 — Customer Intelligence:**
- [ ] 3 KPI cards (High Value, At Risk, Growth)
- [ ] Donut chart RFM segments
- [ ] Treemap segment groups
- [ ] Table with recommended actions

**Page 3 — Logistics & Geo:**
- [ ] 2 KPI cards (Avg Delivery, OTD Rate)
- [ ] Brazil map dengan revenue by state
- [ ] Bar chart late delivery by state
- [ ] Matrix state performance

**Page 4 — Revenue Deep-Dive:**
- [ ] 2 KPI cards (YTD, Latest MoM)
- [ ] Combo chart revenue vs YTD
- [ ] Bar chart quarterly comparison
- [ ] Area chart YTD accumulation

**Global:**
- [ ] Dark theme applied di semua pages
- [ ] Slicers synced across pages
- [ ] Consistent positioning
- [ ] File saved as dashboard360.pbix

---

**Ikuti step by step dari atas ke bawah. Jangan skip!** 🚀

Setelah selesai semua, screenshot tiap page dan push ke GitHub:
```bash
git add dashboard/dashboard360.pbix
git commit -m "feat: complete Power BI dashboard with 4 pages"
git push
```
