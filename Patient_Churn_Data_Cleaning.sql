-- ============================================================
-- PROJECT  : Patient Churn Analysis - Healthcare
-- FILE     : Data Cleaning
-- AUTHOR   : Dhanish Kumar P
-- DATASET  : Patient Churn Prediction Dataset (2000 records)
-- ============================================================

-- ─────────────────────────────────────────
-- STEP 1 : RAW DATA INSPECT
-- ─────────────────────────────────────────

SELECT *
FROM patient_churn.data;

SELECT COUNT(*) AS total_rows
FROM patient_churn.data;

-- ─────────────────────────────────────────
-- STEP 2 : CREATE STAGING TABLE (Safe Copy)
-- ─────────────────────────────────────────
-- Never touch raw data directly!

CREATE TABLE patient_churn_staging
LIKE patient_churn.data;

INSERT INTO patient_churn_staging
SELECT *
FROM patient_churn.data;

SELECT *
FROM patient_churn_staging;

-- ─────────────────────────────────────────
-- STEP 3 : CHECK & REMOVE DUPLICATES
-- ─────────────────────────────────────────

-- 3a. Identify duplicates using ROW_NUMBER
SELECT *,
    ROW_NUMBER() OVER(
        PARTITION BY PatientID, Age, Gender, State, Specialty,
                     Insurance_Type, Visits_Last_Year, Churned
    ) AS row_num
FROM patient_churn_staging;

-- 3b. Show only duplicate rows
WITH duplicate_cte AS (
    SELECT *,
        ROW_NUMBER() OVER(
            PARTITION BY PatientID, Age, Gender, State, Specialty,
                         Insurance_Type, Visits_Last_Year, Churned
        ) AS row_num
    FROM patient_churn_staging
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;

-- 3c. Create staging2 with row_num column for safe deletion
CREATE TABLE `patient_churn_staging2` (
  `PatientID`                  TEXT,
  `Age`                        INT DEFAULT NULL,
  `Gender`                     TEXT,
  `State`                      TEXT,
  `Tenure_Months`              INT DEFAULT NULL,
  `Specialty`                  TEXT,
  `Insurance_Type`             TEXT,
  `Visits_Last_Year`           INT DEFAULT NULL,
  `Missed_Appointments`        INT DEFAULT NULL,
  `Days_Since_Last_Visit`      INT DEFAULT NULL,
  `Last_Interaction_Date`      TEXT,
  `Overall_Satisfaction`       FLOAT DEFAULT NULL,
  `Wait_Time_Satisfaction`     FLOAT DEFAULT NULL,
  `Staff_Satisfaction`         FLOAT DEFAULT NULL,
  `Provider_Rating`            FLOAT DEFAULT NULL,
  `Avg_Out_Of_Pocket_Cost`     INT DEFAULT NULL,
  `Billing_Issues`             INT DEFAULT NULL,
  `Portal_Usage`               INT DEFAULT NULL,
  `Referrals_Made`             INT DEFAULT NULL,
  `Distance_To_Facility_Miles` FLOAT DEFAULT NULL,
  `Churned`                    INT DEFAULT NULL,
  `row_num`                    INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 3d. Insert with row numbers
INSERT INTO patient_churn_staging2
SELECT *,
    ROW_NUMBER() OVER(
        PARTITION BY PatientID, Age, Gender, State, Specialty,
                     Insurance_Type, Visits_Last_Year, Churned
    ) AS row_num
FROM patient_churn_staging;

-- 3e. Verify before delete
SELECT *
FROM patient_churn_staging2
WHERE row_num > 1;

-- 3f. Delete duplicates
DELETE
FROM patient_churn_staging2
WHERE row_num > 1;

-- ─────────────────────────────────────────
-- STEP 4 : STANDARDIZE DATA
-- ─────────────────────────────────────────

-- 4a. Trim whitespace from all text columns
SET SQL_SAFE_UPDATES = 0;

UPDATE patient_churn_staging2
SET 
    PatientID      = TRIM(PatientID),
    Gender         = TRIM(Gender),
    State          = TRIM(State),
    Specialty      = TRIM(Specialty),
    Insurance_Type = TRIM(Insurance_Type);

SET SQL_SAFE_UPDATES = 1;

-- 4b. Standardize Gender values (handle any casing issues)
SELECT DISTINCT Gender
FROM patient_churn_staging2
ORDER BY 1;

UPDATE patient_churn_staging2
SET Gender = 'Male'
WHERE Gender LIKE 'male%' OR Gender LIKE 'M';

UPDATE patient_churn_staging2
SET Gender = 'Female'
WHERE Gender LIKE 'female%' OR Gender LIKE 'F';

-- 4c. Standardize Insurance_Type values
SELECT DISTINCT Insurance_Type
FROM patient_churn_staging2
ORDER BY 1;

-- Normalize any variations
UPDATE patient_churn_staging2
SET Insurance_Type = 'Self-Pay'
WHERE Insurance_Type LIKE 'Self Pay%' OR Insurance_Type LIKE 'selfpay%';

-- 4d. Standardize Specialty values
SELECT DISTINCT Specialty
FROM patient_churn_staging2
ORDER BY 1;

-- 4e. Fix Date column — convert TEXT to proper DATE format
SELECT Last_Interaction_Date,
       STR_TO_DATE(Last_Interaction_Date, '%Y-%m-%d')
FROM patient_churn_staging2
LIMIT 5;

UPDATE patient_churn_staging2
SET Last_Interaction_Date = STR_TO_DATE(Last_Interaction_Date, '%Y-%m-%d');

ALTER TABLE patient_churn_staging2
MODIFY COLUMN Last_Interaction_Date DATE;

-- Verify date conversion
SELECT Last_Interaction_Date
FROM patient_churn_staging2
LIMIT 5;

-- ─────────────────────────────────────────
-- STEP 5 : HANDLE NULL / BLANK VALUES
-- ─────────────────────────────────────────

-- 5a. Check nulls across all key columns
SELECT
    SUM(CASE WHEN PatientID IS NULL OR PatientID = ''             THEN 1 ELSE 0 END) AS null_patientid,
    SUM(CASE WHEN Gender IS NULL OR Gender = ''                    THEN 1 ELSE 0 END) AS null_gender,
    SUM(CASE WHEN Specialty IS NULL OR Specialty = ''              THEN 1 ELSE 0 END) AS null_specialty,
    SUM(CASE WHEN Insurance_Type IS NULL OR Insurance_Type = ''    THEN 1 ELSE 0 END) AS null_insurance,
    SUM(CASE WHEN Overall_Satisfaction IS NULL                     THEN 1 ELSE 0 END) AS null_satisfaction,
    SUM(CASE WHEN Churned IS NULL                                  THEN 1 ELSE 0 END) AS null_churned
FROM patient_churn_staging2;

-- 5b. Convert blank strings to NULL for text columns
UPDATE patient_churn_staging2
SET Specialty = NULL
WHERE Specialty = '';

UPDATE patient_churn_staging2
SET Insurance_Type = NULL
WHERE Insurance_Type = '';

UPDATE patient_churn_staging2
SET Gender = NULL
WHERE Gender = '';

-- 5c. Self JOIN to fill missing Specialty using same PatientID pattern
-- (If same patient has multiple records)
SELECT t1.Specialty, t2.Specialty
FROM patient_churn_staging2 t1
JOIN patient_churn_staging2 t2
    ON t1.PatientID = t2.PatientID
WHERE (t1.Specialty IS NULL OR t1.Specialty = '')
AND t2.Specialty IS NOT NULL;

UPDATE patient_churn_staging2 t1
JOIN patient_churn_staging2 t2
    ON t1.PatientID = t2.PatientID
SET t1.Specialty = t2.Specialty
WHERE t1.Specialty IS NULL
AND t2.Specialty IS NOT NULL;

-- 5d. Remove rows where critical fields are NULL (cannot be used for analysis)
SELECT *
FROM patient_churn_staging2
WHERE Churned IS NULL
AND Overall_Satisfaction IS NULL;

DELETE
FROM patient_churn_staging2
WHERE Churned IS NULL
AND Overall_Satisfaction IS NULL;

-- ─────────────────────────────────────────
-- STEP 6 : VALIDATE RANGES
-- ─────────────────────────────────────────

-- Age should be between 0 and 120
SELECT *
FROM patient_churn_staging2
WHERE Age < 0 OR Age > 120;

-- Satisfaction scores should be between 1 and 5
SELECT *
FROM patient_churn_staging2
WHERE Overall_Satisfaction < 1 OR Overall_Satisfaction > 5;

-- Churned should only be 0 or 1
SELECT DISTINCT Churned
FROM patient_churn_staging2;

-- Tenure should be positive
SELECT *
FROM patient_churn_staging2
WHERE Tenure_Months <= 0;

-- ─────────────────────────────────────────
-- STEP 7 : FINAL CLEANUP
-- ─────────────────────────────────────────

-- Drop helper column
ALTER TABLE patient_churn_staging2
DROP COLUMN row_num;

-- Final clean table check
SELECT *
FROM patient_churn_staging2;

SELECT COUNT(*) AS final_row_count
FROM patient_churn_staging2;
