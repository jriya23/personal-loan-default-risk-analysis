Use loan;

Select * From loan_default;

-- 1. Data Validation-- 

-- Check Table Structure
describe loan_default;

-- Check Duplicate Applications
SELECT 
    applicant_id, COUNT(*) AS duplicate
FROM
    loan_default
GROUP BY applicant_id
HAVING COUNT(*) > 1;

-- Check Null Values
SELECT 
    CASE
        WHEN bank_account_vintage_years = ' ' THEN 0
        ELSE 1
    END,
    CASE
        WHEN existing_emi_monthly_inr = ' ' THEN 0
        ELSE 1
    END,
    CASE
        WHEN num_credit_inquiries_last_6m = ' ' THEN 0
        ELSE 1
    END
FROM
    loan_default;

-- 2. PORTFOLIO OVERVIEW-- 

-- Business questions:

-- How many applications?
-- How many defaults?
-- What is default rate?
-- How much loan exposure?
-- How much exposure belongs to defaulted applicants?

SELECT
    COUNT(*) AS total_applications,

    SUM(default_flag) AS defaulted_applications,

    COUNT(*) - SUM(default_flag) AS non_defaulted_applications,

    ROUND(
        100.0 * SUM(default_flag) / COUNT(*),
        2
    ) AS default_rate_pct,

    ROUND(
        SUM(loan_amount_requested_inr),
        2
    ) AS total_loan_exposure_inr,

    ROUND(
        SUM(
            CASE
                WHEN default_flag = 1
                THEN loan_amount_requested_inr
                ELSE 0
            END
        ),
        2
    ) AS defaulted_loan_exposure_inr,

    ROUND(
        AVG(loan_amount_requested_inr),
        2
    ) AS average_loan_amount_inr,

    ROUND(
        AVG(monthly_income_inr),
        2
    ) AS average_monthly_income_inr,

    ROUND(
        AVG(cibil_score),
        2
    ) AS average_cibil_score

FROM loan_default;

-- Default vs non-default distribution
SELECT
    default_flag,

    COUNT(*) AS applications,

    ROUND(
        100.0 * COUNT(*) /
        (SELECT COUNT(*) FROM loan_default),
        2
    ) AS portfolio_percentage

FROM loan_default

GROUP BY default_flag;

-- 3. CREDIT RISK ANALYSIS-- 

-- CIBIL distribution
SELECT 
    MIN(cibil_score) AS min_cibil,
    MAX(cibil_score) AS max_cibil,
    ROUND(AVG(cibil_score), 2) AS avg_cibil
FROM
    loan_default;

-- CIBIL bands
SELECT
    CASE
        WHEN cibil_score < 650 THEN 'Below 650'
        WHEN cibil_score < 700 THEN '650-699'
        WHEN cibil_score < 750 THEN '700-749'
        ELSE '750+'
    END AS cibil_band,

    COUNT(*) AS applications,

    SUM(default_flag) AS defaults,

    ROUND(
        100.0 * SUM(default_flag) / COUNT(*),
        2
    ) AS default_rate_pct,

    ROUND(
        AVG(loan_amount_requested_inr),
        2
    ) AS avg_loan_amount_inr

FROM loan_default

GROUP BY
    CASE
        WHEN cibil_score < 650 THEN 'Below 650'
        WHEN cibil_score < 700 THEN '650-699'
        WHEN cibil_score < 750 THEN '700-749'
        ELSE '750+'
    END

ORDER BY
    MIN(cibil_score);
    
-- Credit utilization
SELECT

    CASE
        WHEN credit_utilization_ratio_pct < 30
            THEN 'Low (<30%)'

        WHEN credit_utilization_ratio_pct < 70
            THEN 'Moderate (30-69%)'

        ELSE 'High (70%+)'
    END AS utilization_band,

    COUNT(*) AS applications,

    SUM(default_flag) AS defaults,

    ROUND(
        100.0 * SUM(default_flag) / COUNT(*),
        2
    ) AS default_rate_pct

FROM loan_default

GROUP BY utilization_band;

-- 4 LATE PAYMENT ANALYSIS-- 

-- Default rate by late payments 
SELECT 
    late_payments_last_12m,
    COUNT(*) AS Applicants,
    SUM(default_flag) AS defaults,
    ROUND(SUM(default_flag) * 100 / COUNT(*), 2) AS default_rate_pct
FROM
    loan_default
WHERE
    late_payments_last_12m > 0
GROUP BY late_payments_last_12m
ORDER BY late_payments_last_12m;

-- Business-friendly late-payment bands
SELECT

    CASE
        WHEN late_payments_last_12m = 0
            THEN '0 Late Payments'

        WHEN late_payments_last_12m BETWEEN 1 AND 2
            THEN '1-2 Late Payments'

        WHEN late_payments_last_12m BETWEEN 3 AND 5
            THEN '3-5 Late Payments'

        ELSE '6+ Late Payments'
    END AS late_payment_band,

    COUNT(*) AS applications,

    SUM(default_flag) AS defaults,

    ROUND(
        100.0 * SUM(default_flag) / COUNT(*),
        2
    ) AS default_rate_pct

FROM loan_default

GROUP BY late_payment_band
    ;
    
-- 5. CREDIT INQUIRIES -- 

-- Default rate by inquiries
SELECT
    num_credit_inquiries_last_6m,

    COUNT(*) AS applications,

    SUM(default_flag) AS defaults,

    ROUND(
        100.0 * SUM(default_flag) / COUNT(*),
        2
    ) AS default_rate_pct

FROM loan_default

GROUP BY num_credit_inquiries_last_6m

ORDER BY num_credit_inquiries_last_6m;

-- 7. EXISTING LOANS -- 

-- Existing loans vs default
SELECT
    existing_loans_count,

    COUNT(*) AS applications,

    SUM(default_flag) AS defaults,

    ROUND(
        100.0 * SUM(default_flag) / COUNT(*),
        2
    ) AS default_rate_pct

FROM loan_default

GROUP BY existing_loans_count

ORDER BY existing_loans_count;

-- 8. INCOME & AFFORDABILITY -- 

-- Income bands 
SELECT

    CASE
        WHEN monthly_income_inr < 25000
            THEN 'Below 25K'

        WHEN monthly_income_inr < 50000
            THEN '25K-50K'

        WHEN monthly_income_inr < 100000
            THEN '50K-100K'

        ELSE '100K+'
    END AS income_band,

    COUNT(*) AS applications,

    SUM(default_flag) AS defaults,

    ROUND(
        100.0 * SUM(default_flag) / COUNT(*),
        2
    ) AS default_rate_pct,

    ROUND(
        AVG(loan_amount_requested_inr),
        2
    ) AS average_loan_amount_inr

FROM loan_default

GROUP BY income_band;
    
-- 8. EMI-TO-INCOME RATIO --

-- Calculate EMI burden  
SELECT
    applicant_id,

    monthly_income_inr,

    existing_emi_monthly_inr,

    ROUND(
        100.0 * existing_emi_monthly_inr /
        NULLIF(monthly_income_inr, 0),
        2
    ) AS emi_to_income_pct,

    default_flag

FROM loan_default;

-- EMI burden segmentation
SELECT

    CASE
        WHEN 100.0 * existing_emi_monthly_inr /
             NULLIF(monthly_income_inr, 0) < 20
            THEN 'Low'

        WHEN 100.0 * existing_emi_monthly_inr /
             NULLIF(monthly_income_inr, 0) < 40
            THEN 'Moderate'

        ELSE 'High'
    END AS emi_burden,

    COUNT(*) AS applications,

    SUM(default_flag) AS defaults,

    ROUND(
        100.0 * SUM(default_flag) / COUNT(*),
        2
    ) AS default_rate_pct,

    ROUND(
        AVG(monthly_income_inr),
        2
    ) AS avg_income_inr

FROM loan_default

GROUP BY emi_burden;

    
-- 9. LOAN CHARACTERISTICS -- 

-- Loan purpose
SELECT
    loan_purpose,

    COUNT(*) AS applications,

    SUM(default_flag) AS defaults,

    ROUND(
        100.0 * SUM(default_flag) / COUNT(*),
        2
    ) AS default_rate_pct,

    ROUND(
        SUM(loan_amount_requested_inr),
        2
    ) AS loan_exposure_inr

FROM loan_default

GROUP BY loan_purpose

ORDER BY default_rate_pct DESC;

-- Loan tenure
SELECT
    loan_tenure_months,

    COUNT(*) AS applications,

    SUM(default_flag) AS defaults,

    ROUND(
        100.0 * SUM(default_flag) / COUNT(*),
        2
    ) AS default_rate_pct,

    ROUND(
        AVG(loan_amount_requested_inr),
        2
    ) AS avg_loan_amount_inr

FROM loan_default

GROUP BY loan_tenure_months

ORDER BY loan_tenure_months;

-- Loan amount bands
SELECT

    CASE
        WHEN loan_amount_requested_inr < 100000
            THEN 'Below 1 Lakh'

        WHEN loan_amount_requested_inr < 250000
            THEN '1-2.5 Lakh'

        WHEN loan_amount_requested_inr < 500000
            THEN '2.5-5 Lakh'

        ELSE '5 Lakh+'
    END AS loan_amount_band,

    COUNT(*) AS applications,

    SUM(default_flag) AS defaults,

    ROUND(
        100.0 * SUM(default_flag) / COUNT(*),
        2
    ) AS default_rate_pct,

    SUM(loan_amount_requested_inr) AS loan_exposure_inr

FROM loan_default

GROUP BY  loan_amount_band
Order by loan_amount_band ;

-- Collateral
SELECT
    collateral_provided,

    COUNT(*) AS applications,

    SUM(default_flag) AS defaults,

    ROUND(
        100.0 * SUM(default_flag) / COUNT(*),
        2
    ) AS default_rate_pct,

    SUM(loan_amount_requested_inr) AS loan_exposure_inr

FROM loan_default

GROUP BY collateral_provided;

-- Interest rate
SELECT 
    MIN(interest_rate_offered_pct) AS min_interest_rate,
    MAX(interest_rate_offered_pct) AS max_interest_rate,
    ROUND(AVG(interest_rate_offered_pct), 2) AS avg_interest_rate
FROM
    loan_default;

-- Interest rate band
SELECT

    CASE
        WHEN interest_rate_offered_pct < 10
            THEN 'Below 10%'

        WHEN interest_rate_offered_pct < 15
            THEN '10-15%'

        WHEN interest_rate_offered_pct < 20
            THEN '15-20%'

        ELSE '20%+'
    END AS interest_rate_band,

    COUNT(*) AS applications,

    SUM(default_flag) AS defaults,

    ROUND(
        100.0 * SUM(default_flag) / COUNT(*),
        2
    ) AS default_rate_pct

FROM loan_default

GROUP BY interest_rate_band;

-- 10. CUSTOMER & GEOGRAPHY --

-- Employment type 
SELECT
    employment_type,

    COUNT(*) AS applications,

    SUM(default_flag) AS defaults,

    ROUND(
        100.0 * SUM(default_flag) / COUNT(*),
        2
    ) AS default_rate_pct,

    ROUND(
        AVG(monthly_income_inr),
        2
    ) AS avg_income_inr,

    SUM(loan_amount_requested_inr) AS loan_exposure_inr

FROM loan_default

GROUP BY employment_type

ORDER BY default_rate_pct DESC;

-- City tier
SELECT
    city_tier,

    COUNT(*) AS applications,

    SUM(default_flag) AS defaults,

    ROUND(
        100.0 * SUM(default_flag) / COUNT(*),
        2
    ) AS default_rate_pct,

    SUM(loan_amount_requested_inr) AS loan_exposure_inr

FROM loan_default

GROUP BY city_tier

ORDER BY city_tier;

-- State
SELECT
    statetext,

    COUNT(*) AS applications,

    SUM(default_flag) AS defaults,

    ROUND(
        100.0 * SUM(default_flag) / COUNT(*),
        2
    ) AS default_rate_pct,

    SUM(loan_amount_requested_inr) AS loan_exposure_inr

FROM loan_default

GROUP BY statetext

HAVING COUNT(*) >= 100

ORDER BY default_rate_pct DESC;

-- 12. RISK SCORE EVALUATION -- 

-- Risk score distribution
SELECT
    MIN(default_risk_score) AS minimum_score,
    MAX(default_risk_score) AS maximum_score,
    ROUND(AVG(default_risk_score), 2) AS average_score
FROM loan_default;

SELECT
    default_risk_score,
    COUNT(*) AS applications,
    SUM(default_flag) AS defaults,

    ROUND(
        100.0 * SUM(default_flag) / COUNT(*),
        2
    ) AS default_rate_pct

FROM loan_default

GROUP BY default_risk_score

ORDER BY default_risk_score;

-- 13. DEFAULTED VS NON-DEFAULTED PROFILE -- 

SELECT
    default_flag,

    COUNT(*) AS applications,

    ROUND(AVG(age), 2) AS avg_age,

    ROUND(AVG(monthly_income_inr), 2) AS avg_income,

    ROUND(AVG(existing_loans_count), 2)
        AS avg_existing_loans,

    ROUND(AVG(existing_emi_monthly_inr), 2)
        AS avg_existing_emi,

    ROUND(AVG(credit_utilization_ratio_pct), 2)
        AS avg_credit_utilization,

    ROUND(AVG(num_credit_inquiries_last_6m), 2)
        AS avg_credit_inquiries,

    ROUND(AVG(late_payments_last_12m), 2)
        AS avg_late_payments,

    ROUND(AVG(loan_amount_requested_inr), 2)
        AS avg_loan_amount,

    ROUND(AVG(cibil_score), 2)
        AS avg_cibil,

    ROUND(AVG(interest_rate_offered_pct), 2)
        AS avg_interest_rate,

    ROUND(AVG(default_risk_score), 2)
        AS avg_risk_score

FROM loan_default

GROUP BY default_flag;

-- 14. RISK SEGMENTATION -- 

-- CIBIL × EMI Burden
SELECT

    CASE
        WHEN cibil_score < 650
            THEN 'Below 650'

        WHEN cibil_score < 750
            THEN '650-749'

        ELSE '750+'
    END AS cibil_segment,

    CASE
        WHEN 100.0 * existing_emi_monthly_inr /
             NULLIF(monthly_income_inr, 0) < 20
            THEN 'Low EMI Burden'

        WHEN 100.0 * existing_emi_monthly_inr /
             NULLIF(monthly_income_inr, 0) < 40
            THEN 'Moderate EMI Burden'

        ELSE 'High EMI Burden'
    END AS emi_segment,

    COUNT(*) AS applications,

    SUM(default_flag) AS defaults,

    ROUND(
        100.0 * SUM(default_flag) / COUNT(*),
        2
    ) AS default_rate_pct,

    SUM(loan_amount_requested_inr)
        AS loan_exposure_inr

FROM loan_default

GROUP BY
    cibil_segment,
    emi_segment

ORDER BY
    default_rate_pct DESC;

-- 15. CREDIT + PAYMENT BEHAVIOR -- 

SELECT

    CASE
        WHEN cibil_score < 650
            THEN 'Below 650'
        ELSE '650+'
    END AS cibil_group,

    CASE
        WHEN late_payments_last_12m = 0
            THEN 'No Late Payments'

        WHEN late_payments_last_12m <= 2
            THEN '1-2 Late Payments'

        ELSE '3+ Late Payments'
    END AS payment_group,

    COUNT(*) AS applications,

    SUM(default_flag) AS defaults,

    ROUND(
        100.0 * SUM(default_flag) / COUNT(*),
        2
    ) AS default_rate_pct,

    SUM(loan_amount_requested_inr)
        AS loan_exposure_inr

FROM loan_default

GROUP BY
    cibil_group,
    payment_group

ORDER BY
    default_rate_pct DESC;
    
-- 15. CREDIT + UTILIZATION -- 

SELECT

    CASE
        WHEN cibil_score < 650
            THEN 'Below 650'
        WHEN cibil_score < 750
            THEN '650-749'
        ELSE '750+'
    END AS cibil_segment,

    CASE
        WHEN credit_utilization_ratio_pct < 30
            THEN 'Low Utilization'

        WHEN credit_utilization_ratio_pct < 70
            THEN 'Moderate Utilization'

        ELSE 'High Utilization'
    END AS utilization_segment,

    COUNT(*) AS applications,

    SUM(default_flag) AS defaults,

    ROUND(
        100.0 * SUM(default_flag) / COUNT(*),
        2
    ) AS default_rate_pct,

    SUM(loan_amount_requested_inr)
        AS loan_exposure_inr

FROM loan_default

GROUP BY
    cibil_segment,
    utilization_segment

ORDER BY
    default_rate_pct DESC;
    
-- 17. FIND THE IMPORTANT RISK SEGMENTS -- 

SELECT

    CASE
        WHEN cibil_score < 650
            THEN 'Below 650'

        WHEN cibil_score < 750
            THEN '650-749'

        ELSE '750+'
    END AS cibil_segment,

    CASE
        WHEN 100.0 * existing_emi_monthly_inr /
             NULLIF(monthly_income_inr, 0) < 20
            THEN 'Low EMI'

        WHEN 100.0 * existing_emi_monthly_inr /
             NULLIF(monthly_income_inr, 0) < 40
            THEN 'Moderate EMI'

        ELSE 'High EMI'
    END AS emi_segment,

    COUNT(*) AS applications,

    SUM(default_flag) AS defaults,

    ROUND(
        100.0 * SUM(default_flag) / COUNT(*),
        2
    ) AS default_rate_pct,

    ROUND(
        100.0 * COUNT(*) /
        (SELECT COUNT(*) FROM loan_default),
        2
    ) AS portfolio_share_pct,

    SUM(loan_amount_requested_inr)
        AS loan_exposure_inr,

    SUM(
        CASE
            WHEN default_flag = 1
            THEN loan_amount_requested_inr
            ELSE 0
        END
    ) AS defaulted_loan_exposure_inr

FROM loan_default

GROUP BY
    cibil_segment,
    emi_segment

ORDER BY
    default_rate_pct DESC;
    



