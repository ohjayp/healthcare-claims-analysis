-- ================================================
-- Healthcare Claims Analysis — Portfolio Queries
-- Dataset: CMS Medicare Provider Utilization 2023
-- Author: John Paul Garcia
-- Database: healthcare_portfolio
-- ================================================

-- ================================================
-- QUERY 1: Top 10 Specialties by Average Payment
-- Business Question: Which medical specialties cost
-- Medicare the most per service in California?
-- ================================================

SELECT TOP 10
    Rndrng_Prvdr_Type AS Specialty,
    COUNT(*) AS Total_Records,
    ROUND(AVG(CAST(Avg_Mdcr_Pymt_Amt AS FLOAT)), 2) AS Avg_Payment,
    ROUND(SUM(CAST(Tot_Srvcs AS FLOAT)), 0) AS Total_Services
FROM medicare_claims
WHERE Rndrng_Prvdr_Type IS NOT NULL
GROUP BY Rndrng_Prvdr_Type
ORDER BY Avg_Payment DESC

-- ================================================
-- QUERY 2: Total Services and Spend by City
-- Business Question: Which California cities have
-- the highest Medicare utilization and cost?
-- ================================================

SELECT TOP 15
    Rndrng_Prvdr_City AS City,
    COUNT(DISTINCT Rndrng_NPI) AS Unique_Providers,
    ROUND(SUM(CAST(Tot_Srvcs AS FLOAT)), 0) AS Total_Services,
    ROUND(SUM(CAST(Avg_Mdcr_Pymt_Amt AS FLOAT) * CAST(Tot_Srvcs AS FLOAT)), 2) AS Estimated_Total_Spend
FROM medicare_claims
WHERE Rndrng_Prvdr_City IS NOT NULL
GROUP BY Rndrng_Prvdr_City
ORDER BY Total_Services DESC

-- ================================================
-- QUERY 3: Above-Average Providers by Specialty
-- Business Question: Which providers charge more
-- than the average payment for their specialty?
-- ================================================

SELECT TOP 20
    mc.Rndrng_Prvdr_Last_Org_Name AS Provider_Name,
    mc.Rndrng_Prvdr_First_Name AS First_Name,
    mc.Rndrng_Prvdr_Type AS Specialty,
    mc.Rndrng_Prvdr_City AS City,
    ROUND(CAST(mc.Avg_Mdcr_Pymt_Amt AS FLOAT), 2) AS Their_Avg_Payment,
    ROUND(specialty_avg.Avg_For_Specialty, 2) AS Specialty_Average,
    ROUND(CAST(mc.Avg_Mdcr_Pymt_Amt AS FLOAT) - specialty_avg.Avg_For_Specialty, 2) AS Difference
FROM medicare_claims AS mc
INNER JOIN (
    SELECT 
        Rndrng_Prvdr_Type,
        AVG(CAST(Avg_Mdcr_Pymt_Amt AS FLOAT)) AS Avg_For_Specialty
    FROM medicare_claims
    GROUP BY Rndrng_Prvdr_Type
) AS specialty_avg ON mc.Rndrng_Prvdr_Type = specialty_avg.Rndrng_Prvdr_Type
WHERE CAST(mc.Avg_Mdcr_Pymt_Amt AS FLOAT) > specialty_avg.Avg_For_Specialty
ORDER BY Difference DESC

-- ================================================
-- QUERY 4: NorCal vs SoCal Regional Comparison
-- Business Question: How does Medicare usage differ
-- across California regions?
-- ================================================

SELECT
    CASE
        WHEN Rndrng_Prvdr_City IN ('Los Angeles','San Diego','Irvine','Santa Barbara',
        'Glendale','Torrance','Santa Monica','Beverly Hills','Long Beach','Pasadena',
        'Burbank','Anaheim','Riverside','San Bernardino','Fresno','Bakersfield')
        THEN 'Southern California'
        WHEN Rndrng_Prvdr_City IN ('San Francisco','Sacramento','San Jose','Oakland',
        'Berkeley','Stockton','Modesto','Santa Rosa','Napa','Redding',
        'San Leandro','Campbell','Monterey')
        THEN 'Northern California'
        ELSE 'Other California'
    END AS Region,
    COUNT(DISTINCT Rndrng_NPI) AS Unique_Providers,
    ROUND(SUM(CAST(Tot_Srvcs AS FLOAT)), 0) AS Total_Services,
    ROUND(AVG(CAST(Avg_Mdcr_Pymt_Amt AS FLOAT)), 2) AS Avg_Payment,
    ROUND(SUM(CAST(Avg_Mdcr_Pymt_Amt AS FLOAT) * CAST(Tot_Srvcs AS FLOAT)), 2) AS Estimated_Spend
FROM medicare_claims
GROUP BY
    CASE
        WHEN Rndrng_Prvdr_City IN ('Los Angeles','San Diego','Irvine','Santa Barbara',
        'Glendale','Torrance','Santa Monica','Beverly Hills','Long Beach','Pasadena',
        'Burbank','Anaheim','Riverside','San Bernardino','Fresno','Bakersfield')
        THEN 'Southern California'
        WHEN Rndrng_Prvdr_City IN ('San Francisco','Sacramento','San Jose','Oakland',
        'Berkeley','Stockton','Modesto','Santa Rosa','Napa','Redding',
        'San Leandro','Campbell','Monterey')
        THEN 'Northern California'
        ELSE 'Other California'
    END
ORDER BY Estimated_Spend DESC

-- ================================================
-- QUERY 5: Specialty Rankings by Total Spend
-- Business Question: How do specialties rank against
-- each other by total Medicare spend in California?
-- ================================================

SELECT
    Rndrng_Prvdr_Type AS Specialty,
    ROUND(SUM(CAST(Avg_Mdcr_Pymt_Amt AS FLOAT) * CAST(Tot_Srvcs AS FLOAT)), 2) AS Total_Spend,
    ROUND(SUM(CAST(Tot_Srvcs AS FLOAT)), 0) AS Total_Services,
    ROUND(AVG(CAST(Avg_Mdcr_Pymt_Amt AS FLOAT)), 2) AS Avg_Payment,
    RANK() OVER (ORDER BY SUM(CAST(Avg_Mdcr_Pymt_Amt AS FLOAT) * 
        CAST(Tot_Srvcs AS FLOAT)) DESC) AS Spend_Rank
FROM medicare_claims
WHERE Rndrng_Prvdr_Type IS NOT NULL
GROUP BY Rndrng_Prvdr_Type
ORDER BY Spend_Rank

-- ================================================
-- QUERY 6: Summary Statistics by Specialty
-- Business Question: What are the MIN, MAX, AVG
-- and spread of payments across specialties?
-- ================================================

SELECT
    Rndrng_Prvdr_Type AS Specialty,
    COUNT(*) AS Total_Records,
    ROUND(MIN(CAST(Avg_Mdcr_Pymt_Amt AS FLOAT)), 2) AS Min_Payment,
    ROUND(MAX(CAST(Avg_Mdcr_Pymt_Amt AS FLOAT)), 2) AS Max_Payment,
    ROUND(AVG(CAST(Avg_Mdcr_Pymt_Amt AS FLOAT)), 2) AS Avg_Payment,
    ROUND(MAX(CAST(Avg_Mdcr_Pymt_Amt AS FLOAT)) - 
          MIN(CAST(Avg_Mdcr_Pymt_Amt AS FLOAT)), 2) AS Payment_Range,
    ROUND(SUM(CAST(Tot_Srvcs AS FLOAT)), 0) AS Total_Services
FROM medicare_claims
WHERE Rndrng_Prvdr_Type IS NOT NULL
GROUP BY Rndrng_Prvdr_Type
ORDER BY Payment_Range DESC