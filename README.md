# Logistics & supply chain Optimization Dashboard

![Power BI](https://img.shields.io/badge/Power%20BI-F2C811?style=for-the-badge&logo=powerbi&logoColor=black)
![SQL Server](https://img.shields.io/badge/SQL%20Server-CC2927?style=for-the-badge&logo=microsoftsqlserver&logoColor=white)
![DAX](https://img.shields.io/badge/DAX-0078D4?style=for-the-badge&logo=microsoft&logoColor=white)
![Status](https://img.shields.io/badge/Status-Completed-brightgreen?style=for-the-badge)
![Dataset](https://img.shields.io/badge/Dataset-Olist%20E--Commerce-orange?style=for-the-badge)

---

## 📌 Project Overview

This end-to-end business intelligence project analyzes the logistics and delivery operations of a major Brazilian e-commerce platform using the **Olist Public Dataset**. The dashboard moves beyond surface-level reporting — it surfaces the *why* behind delivery delays, maps geographic demand imbalances, and connects product characteristics to operational outcomes.

Built across **four report pages**, it answers the questions that operations managers, supply chain leads, and product teams genuinely need answered: *Where are we failing customers? Which states drag down our on-time rate? Does spending more on freight actually improve delivery speed?*

The project demonstrates a full analytics workflow — from raw SQL transformation and star schema modeling in **SQL Server**, to calculated DAX measures and multi-page storytelling in **Power BI**.

---

## 🎯 Objectives

- Evaluate overall logistics health across **96K fulfilled orders** from 2016–2018
- Identify which **customer states, seller states, and product categories** drive the highest late-delivery rates
- Understand the relationship between **freight cost, delivery duration, and customer satisfaction**
- Map the geographic distribution of **customer demand vs. seller network coverage**
- Surface **category-level performance** differences to prioritize operational improvements

---

## 🗂️ Dataset

**Source:** [Olist Brazilian E-Commerce Dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) (Kaggle)

The dataset contains anonymized commercial data from Olist, a Brazilian marketplace connector. It covers orders placed between **September 2016 and August 2018** across multiple product categories.

| Table | Description |
|-------|-------------|
| `orders` | Order lifecycle: purchase, approval, carrier handoff, delivery, estimate |
| `order_items` | Line-item details: product, seller, price, freight per item |
| `customers` | Customer ID, city, state, zip code |
| `sellers` | Seller ID, city, state, zip code |
| `products` | Product dimensions, weight, category name |
| `product_category_name_translation` | Portuguese-to-English category mapping |
| `order_reviews` | Review score (1–5) per order |
| `geolocation` | Latitude/longitude lookup by zip code prefix |

> **Scope:** Only `delivered` orders with a non-null `order_delivered_customer_date` are included in analysis — ensuring metrics reflect real operational outcomes rather than incomplete records.

---

## 🛠️ Tools & Technologies

| Layer | Tool | Purpose |
|-------|------|---------|
| **Data Storage** | Microsoft SQL Server | Hosted all raw tables and Analytics schema |
| **Data Modeling** | SQL Server (Views + DDL) | Built star schema: fact table + 4 dimension views |
| **ETL / Transformation** | T-SQL (CTEs, window functions, DATEDIFF) | Cleaned, joined, and enriched all raw tables |
| **Geolocation Enrichment** | SQL AVG aggregation on zip prefix | Resolved customer and seller lat/lng for mapping |
| **BI & Visualization** | Microsoft Power BI Desktop | All 4 report pages, DAX measures, custom visuals |
| **DAX** | Power BI DAX Engine | KPIs: On-Time %, Late Delivery %, Freight Ratio, Avg Days |
| **Data Modeling (BI Layer)** | Power BI Model View | Star schema relationships, sort tables, calc table |
| **Documentation** | Markdown / GitHub | Project README and portfolio documentation |

---

## 🏗️ Data Architecture

The SQL Server `Analytics` schema follows a **star schema** pattern:

```
                    ┌─────────────────────────┐
                    │  Analytics.DimDate       │
                    │  DateKey, Year, Month... │
                    └────────────┬────────────┘
                                 │
┌─────────────────┐    ┌────────┴──────────────┐    ┌─────────────────────┐
│ vw_dim_products │────│  vw_fact_order_items   │────│   vw_dim_sellers    │
│ product_id      │    │  (Central Fact Table)  │    │   seller_id         │
│ category        │    │  price, freight_value  │    │   seller_state      │
│ dimensions/vol  │    │  delivery metrics      │    │   lat / lng         │
└─────────────────┘    │  review_score          │    └─────────────────────┘
                       │  is_on_time            │
┌─────────────────┐    │  delay_days            │    ┌─────────────────────┐
│ vw_dim_customers│────│                        │────│   Sort_Mapping      │
│ customer_id     │    └────────────────────────┘    │   Sort_Review       │
│ customer_state  │                                  │   (Helper Tables)   │
│ lat / lng       │                                  └─────────────────────┘
└─────────────────┘
```

---

## 📊 Dashboard Pages

### Page 1 — Executive Overview
![Executive Overview](./assets/01_Executive_Overview.png)

The command center for leadership. Presents the full-year logistics picture in one glance — total volume, revenue, on-time rate, and freight efficiency. The **Order Volume Trend** line chart reveals the platform's growth trajectory from near-zero in late 2016 to a peak of 7K+ monthly orders by late 2017. The **On-Time vs. Late Deliveries** cluster chart gives an instant monthly read of operational consistency, while the **Categories with Longest Delivery Time** bar chart flags fulfillment bottlenecks at the category level before they escalate.

**KPIs surfaced:**
- Total Orders: **96K** | Total Revenue: **R$13.28M**
- Avg Delivery Days: **12.4** | On-Time Delivery Rate: **91.9%**
- Late Delivery %: **6.77%** | Freight Ratio: **0.17**

---

### Page 2 — Delivery Performance Deep Dive
![Delivery Performance Deep Dive](./assets/02_Delivery_Performance_Deep_Dive.png)

This page is the operational root-cause engine. Rather than just reporting that delays exist, it shows *where* they concentrate and *what conditions* amplify them.

The **Late Delivery % by State** chart reveals that AL (21.4%), MA (17.4%), and SE (15.2%) are the highest-risk customer states — not random noise, but a clear Northeast Brazil pattern. The **Delivery Days Distribution** histogram shows that 83% of orders complete within 14 days, but the 322 orders exceeding 60 days carry a disproportionate "Poor" satisfaction tail.

The **Delivery Duration vs Customer Satisfaction** matrix is one of the most decision-useful visuals in the project: satisfaction holds reasonably well through 14 days, then degrades sharply — making 15 days the natural SLA threshold. The dual-axis **Freight vs. Late Delivery %** combo chart confirms a counterintuitive finding: higher freight spend does not correlate with faster or more reliable delivery.

---

### Page 3 — Logistics Network & Geographic Analysis
![Logistics Network & Geographic Analysis](./assets/03_Logistics_Network___Geographic_Analysis.png)

Two maps, one story: the mismatch between where customers are and where sellers operate.

The **Customer Demand Distribution** map shows demand fanning broadly across Brazil's eastern seaboard, while the **Seller Network Distribution** map shows an overwhelming concentration in São Paulo and the Southeast. SP generates ~40.5K orders and hosts 68.6K seller listings — a dominant logistics hub, but also a single point of failure for national coverage.

The **Delivery Performance by Customer Region** bar chart quantifies the consequence: BA customers wait an average of 19 days vs. just 9 days for SP customers. The gap is not a product-mix artifact — it is a network coverage gap with a measurable cost to customer experience.

**Filters available:** Year (2016/2017/2018), Month, Seller State, Customer State

---

### Page 4 — Product & Category Performance
![Product & Category Performance](./assets/04__Product___Category_Performance.png)

The revenue lens on the catalog. Across **74 product categories** and **132.9K units sold**, this page answers which categories earn the most, which delight customers, and which create logistics headaches.

**Health Beauty** leads revenue at R$1.24M, followed by **Watches Gifts** (R$1.17M) and **Bed Bath Table** (R$1.04M). Satisfaction scores cluster tightly at 4.0–4.2 stars across top categories, suggesting strong product-market fit. The **Freight Cost Impact on Revenue** scatter plot reveals that most high-revenue categories cluster under R$20 average freight — efficient logistics, not expensive logistics, drives commercial success.

**Filters available:** Year, Product Category, Seller State, Customer State

---

## 📐 Key KPIs

| KPI | Value | Definition |
|-----|-------|------------|
| Total Orders | 96K | Delivered orders with confirmed delivery date |
| Total Revenue | R$ 13.28M | Sum of item prices across all delivered orders |
| Avg Delivery Days | 12.4 days | Mean of (delivered date − purchase date) |
| On-Time Delivery Rate | 91.9% | Orders delivered on or before estimated date |
| Late Delivery % | 6.77% | Orders delivered after estimated date |
| Freight Ratio | 0.17 | Total freight ÷ Total item revenue |
| Product Categories | 74 | Distinct translated category names |
| Units Sold | 132.9K | Total order line items |
| Avg Product Price | R$ 119.8 | Mean item price across the catalog |
| Avg Review Score | 4.1 | Mean customer review (scale 1–5) |
| Customer States | 27 | Distinct states with at least one order |
| Seller States | 23 | Distinct states with at least one active seller |

---

## 💡 Key Insights

**1. The Northeast delivery problem is structural, not incidental**
AL, MA, and SE consistently rank as the highest late-delivery states with rates above 15%. These states also have minimal seller presence, meaning nearly every order ships cross-country. Recruiting regional sellers or partnering with local fulfillment centers in the Northeast would directly reduce late rates for this segment.

**2. 15 days is the customer satisfaction cliff**
Satisfaction scores remain acceptable through 14-day deliveries. Orders in the 15–30 day window see a visible decline, and 60+ day deliveries produce "Poor" ratings at nearly equal volume to all positive ratings combined. A 14-day SLA ceiling would protect satisfaction for over 83% of the order base.

**3. São Paulo is the network's center of gravity — and its vulnerability**
SP generates 42% of all customer demand and hosts the vast majority of sellers. This concentration drives efficiency for SP customers (avg 9 days) but leaves remote states underserved. Network diversification is not just a coverage play; it is a resilience requirement.

**4. Freight spend does not buy delivery speed**
The dual-axis analysis of freight cost vs. late delivery % shows no positive correlation. High-freight orders are just as likely to arrive late as low-freight ones. Optimization should target routing and handoff processes — not simply increasing shipping spend.

**5. Health Beauty, Watches, and Bed Bath Table are the revenue anchors**
These three categories account for a combined ~R$3.45M — over 26% of total revenue. Protecting delivery performance and satisfaction scores here should be a strategic priority.

**6. Platform growth peaked and stabilized by mid-2018**
Order volume surged from near-zero in late 2016 to ~7K/month by late 2017, then plateaued. This shift from growth phase to steady state calls for a focus on retention and operational efficiency over volume acquisition.

---

## ❓ Business Questions Answered

| # | Business Question | Page |
|---|-------------------|------|
| 1 | What is our overall logistics health across all years? | Executive Overview |
| 2 | Which months show the highest late delivery concentration? | Executive Overview |
| 3 | Which customer states are most affected by late deliveries? | Delivery Deep Dive |
| 4 | At what delivery duration does customer satisfaction begin to decline? | Delivery Deep Dive |
| 5 | Does spending more on freight result in faster delivery? | Delivery Deep Dive |
| 6 | Where is customer demand concentrated geographically? | Geographic Analysis |
| 7 | Does seller network coverage align with customer locations? | Geographic Analysis |
| 8 | Which customer regions experience the longest average delivery times? | Geographic Analysis |
| 9 | Which product categories generate the most revenue? | Product & Category |
| 10 | Do high freight cost categories produce the highest revenue? | Product & Category |
| 11 | Which categories have the longest fulfillment times? | Product & Category |
| 12 | Are customer satisfaction scores consistent across top-selling categories? | Product & Category |

---

## ⚙️ Dashboard Features

- **4-page navigation** with top-bar tabs for seamless cross-page exploration
- **Year filter** (2016 / 2017 / 2018) and **Month slicers** on geographic and product pages
- **Seller State** and **Customer State** dropdowns for regional drill-down
- **Product Category dropdown** for filtered category deep dives
- **Custom delivery duration grouping** (0–7, 8–14, 15–30, 31–60, 60+ Days) via DAX calculated column
- **Review category bucketing** (Excellent / Satisfactory / Average / Poor) mapped from raw scores
- **Bing Maps integration** for customer and seller geographic distribution
- **Dual-axis combo chart** pairing total freight spend with late delivery % by duration group
- **Satisfaction matrix table** cross-tabulating delivery duration groups vs. review categories
- **Embedded Key Insights text panels** on each page for non-technical stakeholders

---

## 🗂️ Folder Structure

```Logistics & supply chain Optimization Dashboard/
│
├── 📁 sql/
│   ├── 01_data_exploration.sql           # Row counts, null checks, timestamp inspection
│   ├── 02_create_logistics_master.sql    # vw_logistics_master (order-level aggregation)
│   ├── 03_dimension_views.sql            # vw_dim_products, customers, sellers
│   ├── 04_dim_date.sql                   # DimDate table population
│   ├── 05_geo_enrichment.sql             # vw_geo_base + enriched dimension views
│   └── 06_fact_order_items.sql           # vw_fact_order_items (final fact view)
│
├── 📁 pbix/
│   └── Logistics & supply chain Optimization Dashboard.pbix    # Power BI report file
│
├── 📁 assets/
│   ├── 01_Executive_Overview.png
│   ├── 02_Delivery_Performance_Deep_Dive.png
│   ├── 03_Logistics_Network_Geographic_Analysis.png
│   ├── 04_Product_Category_Performance.png
│
├── 📄 README.md

```

---

## 🧠 Skills Demonstrated

**SQL & Data Engineering**
- Designed and built a production-style `Analytics` schema in SQL Server from scratch
- Wrote CTEs, multi-table JOINs, and GROUP BY aggregations to flatten complex relational data
- Computed derived fields: `actual_delivery_days`, `delay_days`, `is_on_time` using `DATEDIFF`
- Applied geolocation enrichment using zip-code prefix averaging across 1M+ raw geolocation records
- Used `CREATE OR ALTER VIEW` patterns for iterative, safe schema evolution

**Data Modeling**
- Implemented a normalized star schema: one central fact view, four supporting dimension tables/views
- Defined many-to-one relationships in Power BI Model View for clean, unambiguous cross-filtering
- Created helper sort tables to enforce custom visual ordering independent of alphabetical defaults
- Isolated all DAX measures in a dedicated `Calculations` table for maintainability

**DAX & Power BI**
- Authored KPI measures: On-Time %, Late Delivery %, Freight Ratio, Avg Review Score
- Used `CALCULATE` + `FILTER` patterns for conditional aggregations
- Built custom delivery groupings and review categories as calculated columns
- Designed a 4-page report with consistent navigation, cross-filtering, and stakeholder-ready callout panels

**Analytical Storytelling**
- Structured each page around a specific operational question rather than displaying all available data
- Surfaced non-obvious findings: freight spend ≠ speed; 15-day satisfaction cliff; Northeast structural gap
- Embedded insight panels directly in dashboards to make findings self-explanatory for business users

---

## 🔭 Future Improvements

- [ ] **Predictive Delay Scoring** — Train a model to flag orders at risk of late delivery at purchase time, based on seller state, customer state, and product category
- [ ] **Seller Performance Scorecard** — Add a drill-through page ranking sellers by on-time rate, avg review, and freight efficiency
- [ ] **Revenue Forecasting** — Apply Power BI's built-in forecasting to the Order Volume Trend to project future order volumes
- [ ] **Live SQL Server Connection** — Replace static import with DirectQuery for near-real-time operational monitoring
- [ ] **RFM Customer Segmentation** — Identify high-value, at-risk, and lapsed customer segments using Recency-Frequency-Monetary analysis
- [ ] **Power BI Service Deployment** — Publish with scheduled refresh, row-level security per region, and mobile layout optimization
- [ ] **Returns & Cancellation Analysis** — Extend the model to include non-delivered order statuses for a complete fulfillment funnel view

---

## 🏁 Conclusion

This project demonstrates what a full analytics pipeline looks like when built with discipline: raw relational data → cleaned SQL views → star schema model → purposeful Power BI storytelling. Every design decision — from the `Analytics` schema structure to the page-level narrative flow — was made to serve a real operational question, not to showcase features.

The findings are concrete and actionable: the Northeast coverage gap is a network problem, not a transit one. The 15-day satisfaction threshold gives supply chain teams a measurable SLA target. And the freight-spend paradox challenges the instinct to throw money at logistics problems without first auditing the process.

For organizations running high-volume e-commerce operations, dashboards like this are not optional reporting extras — they are the operational infrastructure for making better decisions faster.

---

## 👤 Author

**[Tanaya Sikdar]**
📧 tanaya.sikdar.kolkata@gmail.com
🔗 [LinkedIn](www.linkedin.com/in/tanaya-sikdar-kolkata) | [GitHub](https://github.com/Tanaya-Sikdar) 

---

<div align="center">

⭐ **If this project helped you or sparked ideas, a star goes a long way.** ⭐

*Built with clarity, not just code.*

</div>
