-- Exploratory Data Analysis

SELECT *
FROM patient_churn_staging2;

-- Maximum values check
SELECT MAX(Visits_Last_Year), MAX(Overall_Satisfaction)
FROM patient_churn_staging2;

-- Patients who completely stopped (churned=1) ordered by cost
SELECT *
FROM patient_churn_staging2
WHERE Churned = 1
ORDER BY Avg_Out_Of_Pocket_Cost DESC;

-- Overall Churn Rate 
SELECT COUNT(*) AS total_patients,
SUM(Churned) AS churned,
ROUND(SUM(Churned)*100.0/COUNT(*),2) AS churn_rate_pct
FROM patient_churn_staging2;

-- Total churned patients by company/specialty
SELECT Specialty, SUM(Churned)
FROM patient_churn_staging2
GROUP BY Specialty
ORDER BY 2 DESC;

-- Date range of interactions
SELECT MIN(Last_Interaction_Date), MAX(Last_Interaction_Date)
FROM patient_churn_staging2;

-- Churn by Insurance Type
SELECT Insurance_Type, SUM(Churned)
FROM patient_churn_staging2
GROUP BY Insurance_Type
ORDER BY 2 DESC;

-- Churn by State
SELECT State, SUM(Churned)
FROM patient_churn_staging2
GROUP BY State
ORDER BY 2 DESC;

SELECT *
FROM patient_churn_staging2;

-- Churn by Year
SELECT YEAR(Last_Interaction_Date), SUM(Churned)
FROM patient_churn_staging2
GROUP BY YEAR(Last_Interaction_Date)
ORDER BY 1 DESC;

-- Churn by Stage (Insurance Type as stage equivalent)
SELECT Insurance_Type, SUM(Churned)
FROM patient_churn_staging2
GROUP BY Insurance_Type
ORDER BY 1 DESC;

-- Satisfaction vs Churn
SELECT Churned,
ROUND(AVG(Overall_Satisfaction),2) AS avg_satisfaction
FROM patient_churn_staging2
GROUP BY Churned;

-- Average satisfaction per specialty
SELECT 
    Specialty,
    AVG(Overall_Satisfaction) AS Avg_Satisfaction
FROM patient_churn_staging2
GROUP BY Specialty
ORDER BY Avg_Satisfaction DESC;

-- Monthly churn breakdown
SELECT SUBSTRING(Last_Interaction_Date,1,7) AS `MONTH`, SUM(Churned) AS total_churned
FROM patient_churn_staging2
WHERE SUBSTRING(Last_Interaction_Date,1,7) IS NOT NULL
GROUP BY `MONTH`
ORDER BY 1 ASC;

-- Rolling Monthly Churn Total
WITH Rolling_Total AS
(
    SELECT SUBSTRING(Last_Interaction_Date,1,7) AS `MONTH`, SUM(Churned) AS total_churned
    FROM patient_churn_staging2
    WHERE SUBSTRING(Last_Interaction_Date,1,7) IS NOT NULL
    GROUP BY `MONTH`
    ORDER BY 1 ASC
)
SELECT `MONTH`, total_churned,
       SUM(total_churned) OVER(ORDER BY `MONTH`) AS rolling_total
FROM Rolling_Total;

-- Churn by Specialty per Year
SELECT Specialty, YEAR(Last_Interaction_Date), SUM(Churned)
FROM patient_churn_staging2
GROUP BY Specialty, YEAR(Last_Interaction_Date)
ORDER BY 3 DESC;

-- Top 5 Specialties by Churn per Year (DENSE_RANK)
WITH Specialty_Year (Specialty, years, total_churned) AS
(
    SELECT Specialty, YEAR(Last_Interaction_Date), SUM(Churned)
    FROM patient_churn_staging2
    GROUP BY Specialty, YEAR(Last_Interaction_Date)
),
Specialty_Year_Rank AS
(
    SELECT *,
    DENSE_RANK() OVER (PARTITION BY years ORDER BY total_churned DESC) AS Ranking
    FROM Specialty_Year
    WHERE years IS NOT NULL
)
SELECT *
FROM Specialty_Year_Rank
WHERE Ranking <= 5;

SELECT 
    COUNT(*) AS total_patients,
    SUM(Churned) AS total_churned,
    COUNT(*) - SUM(Churned) AS total_retained,
    ROUND(SUM(Churned)*100.0/COUNT(*),2) AS churn_rate_pct
FROM patient_churn_staging2;