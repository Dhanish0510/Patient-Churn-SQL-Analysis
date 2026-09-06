# 🏥 Patient Churn Analysis — MySQL

## 📌 Project Overview
Analyzed **2,000 healthcare patient records** to identify churn patterns using MySQL.  
This project covers end-to-end Data Cleaning and Exploratory Data Analysis (EDA)  
to help healthcare providers understand **why patients leave** and **who is at risk.**

---

## 🗂️ Dataset Info
| Field | Details |
|-------|---------|
| Source | Patient Churn Prediction Dataset (Kaggle) |
| Records | 2,000 patients |
| Columns | 21 features |
| Date Range | Jan 2024 — Jan 2026 |

---

## 🛠️ Tools Used
- **MySQL** — Data Cleaning & EDA
- **MySQL Workbench** — Query execution & visualization

---

## 📁 Files
| File | Description |
|------|-------------|
| `Patient_Churn_Data_Cleaning.sql` | Full data cleaning pipeline |
| `Patient_Churn_EDA.sql` | Exploratory Data Analysis queries |
| `patient_churn_dataset.csv` | Raw dataset |

---

## 🧹 Data Cleaning — What Was Done

### Step 1 — Raw Data Inspect
- Viewed raw table structure and all 2,000 records

### Step 2 — Staging Table Created
- Created `patient_churn_staging` as safe working copy
- Never touched original raw data

### Step 3 — Duplicate Check
- Used `ROW_NUMBER()` Window Function to detect duplicates
- **Result: 0 duplicates found** — data integrity confirmed ✅

### Step 4 — Standardization
- Trimmed whitespace from all text columns (PatientID, Gender, State, Specialty, Insurance_Type)
- Standardized Gender, Insurance Type values
- Converted `Last_Interaction_Date` from TEXT → proper DATE format using `STR_TO_DATE()`

### Step 5 — NULL Handling
- Converted blank strings to NULL
- Used **Self JOIN trick** to fill missing Specialty values
- Removed rows where critical fields (Churned, Satisfaction) were NULL

### Step 6 — Range Validation
- Age validated: 18–90 ✅
- Satisfaction scores validated: 1.5–5.0 ✅
- Churned column validated: only 0 or 1 ✅

### Step 7 — Final Cleanup
- Dropped helper `row_num` column
- Final clean table: `patient_churn_staging2`

---

## 📊 EDA — Key Findings

### 🔴 Overall Churn Rate
| Metric | Value |
|--------|-------|
| Total Patients | 2,000 |
| Churned | 1,367 |
| Retained | 633 |
| **Churn Rate** | **68.35%** |

---

### 🏥 Churn by Specialty
| Specialty | Churned Patients |
|-----------|-----------------|
| General Practice | 210 |
| Family Medicine | 203 |
| Neurology | 201 |
| Pediatrics | 198 |
| Internal Medicine | 192 |
| Orthopedics | 185 |
| Cardiology | 178 |

> **General Practice** has the highest patient churn

---

### 💳 Churn by Insurance Type
| Insurance Type | Churned Patients |
|----------------|-----------------|
| Self-Pay | 351 |
| Medicare | 344 |
| Medicaid | 337 |
| Private | 335 |

> **Self-Pay patients** churn the most — likely due to high out-of-pocket costs

---

### 🗺️ Top 3 States by Churn
| State | Churned Patients |
|-------|-----------------|
| NC (North Carolina) | 178 |
| FL (Florida) | 144 |
| IL (Illinois) | 143 |

---

### ⭐ Satisfaction vs Churn
| Status | Avg Overall Satisfaction |
|--------|------------------------|
| Retained (0) | 3.48 |
| Churned (1) | 3.15 |

> Churned patients had **noticeably lower satisfaction scores** — direct correlation confirmed

---

### 📅 Monthly Rolling Churn
- Used **CTE + Window Function** to calculate rolling monthly churn total
- Tracks cumulative churn growth from Jan 2024 to Jan 2026

### 🏆 Top 5 Specialties Per Year
- Used **DENSE_RANK()** with **double CTE** to rank specialties by churn each year
- Identifies consistently high-risk specialties year over year

---

## 💡 Business Insights
1. **68.35% churn rate** is critically high — immediate retention strategy needed
2. **Self-Pay patients** are highest risk — consider financial assistance programs
3. **Low satisfaction (3.15 avg)** among churned patients — improve patient experience
4. **General Practice & Family Medicine** need focused retention efforts
5. **NC, FL, IL** states need regional intervention strategies

---

## 🧠 SQL Concepts Used
| Concept | Used For |
|---------|----------|
| `ROW_NUMBER()` | Duplicate detection |
| `TRIM()` | Whitespace standardization |
| `STR_TO_DATE()` | Date format conversion |
| `Self JOIN` | NULL value filling |
| `GROUP BY` | Aggregation analysis |
| `CASE WHEN` | Age & satisfaction bucketing |
| `CTE (WITH clause)` | Rolling total calculation |
| `DENSE_RANK()` | Top N ranking per year |
| Window Functions | Advanced analytics |

