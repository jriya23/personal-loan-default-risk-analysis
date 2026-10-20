# personal-loan-default-risk-analysis
### Banking & Lending Analytics | SQL • Credit Risk

## Project Overview

This project analyzes **25,000 personal-loan application records** to understand which applicant, credit, repayment, affordability, and loan characteristics are associated with higher observed default rates.

The goal is to turn application-level data into business insights that can help a bank or lending institution monitor its loan portfolio, understand where loan exposure is concentrated, and make better-informed credit-risk decisions.

**Core business question:** Which types of applicants and loans are associated with higher observed default rates, and how can the lending team use these patterns to improve risk monitoring and portfolio decisions?

## Business Objectives

- Measure the overall health of the loan portfolio using application counts, default rates, and loan exposure.
- Compare observed default rates across CIBIL-score bands and credit-behaviour segments.
- Explore affordability indicators, including monthly income and existing EMI burden.
- Examine how loan purpose, tenure, amount, collateral, and interest rate relate to observed defaults.
- Compare patterns by employment type, city tier, and state.
- Evaluate whether the available default-risk score separates groups with different observed default rates.
- Build a business-friendly risk segmentation framework to support portfolio monitoring.

## Dataset

**File:** `india_personal_loan_default_risk_2026.csv`  
**Size:** 25,000 rows × 22 columns

The dataset contains application, customer, financial, credit, and loan-related fields.

| Category | Example fields |
|---|---|
| Applicant profile | `applicant_id`, `age`, `gender`, `marital_status` |
| Employment and geography | `employment_type`, `city_tier`, `state` |
| Income and obligations | `monthly_income_inr`, `existing_loans_count`, `existing_emi_monthly_inr` |
| Credit behaviour | `cibil_score`, `credit_utilization_ratio_pct`, `num_credit_inquiries_last_6m`, `late_payments_last_12m` |
| Loan details | `loan_amount_requested_inr`, `loan_tenure_months`, `loan_purpose`, `collateral_provided`, `interest_rate_offered_pct` |
| Risk and outcome | `default_risk_score`, `default_flag` |

`default_flag` is the outcome used in the SQL analysis: the queries treat `1` as a default and `0` as a non-default.

## Tools Used

- **MySQL / SQL** — data validation, aggregation, KPI calculations, segmentation, and risk analysis.
- **Power BI** — intended interactive reporting layer for presenting portfolio KPIs and risk segments.
- **CSV** — source dataset.

## Project Workflow

### 1. Data validation

The SQL script begins by inspecting the table structure and checking for duplicate applicant IDs and blank values in selected fields. These checks help identify potential data-quality issues before interpreting the results.

### 2. Portfolio overview

I calculate core portfolio metrics, including:

- Total applications
- Defaulted and non-defaulted applications
- Overall observed default rate
- Total requested loan exposure
- Loan exposure associated with defaulted applications
- Average requested loan amount, monthly income, and CIBIL score

### 3. Credit-risk analysis

I group applicants into CIBIL-score bands and credit-utilization bands, then compare application volumes, defaults, default rates, and average loan amounts where relevant.

### 4. Repayment behaviour

I examine how observed default rates vary with:

- Number of late payments in the previous 12 months
- Credit inquiries in the previous six months
- Number of existing loans
- Existing EMI burden relative to monthly income

### 5. Income and affordability

I group applicants by monthly-income ranges and calculate the **EMI-to-income ratio**:

`EMI-to-income ratio (%) = Existing monthly EMI / Monthly income × 100`

The SQL segments EMI burden into low, moderate, and high groups to compare observed default rates and average income. Division by zero is handled with `NULLIF`.

### 6. Loan characteristics

I analyze observed default patterns by loan purpose, tenure, requested loan amount, collateral status, and offered interest-rate bands. I also calculate loan exposure by relevant segments.

### 7. Customer and geographic patterns

I compare application volume, default rate, income, and loan exposure across employment types, city tiers, and states. The state-level query includes only states with at least 100 applications to avoid ranking very small groups in the same way as larger groups.

### 8. Risk-score evaluation and combined segmentation

I examine the distribution of the available `default_risk_score` and compare observed default rates across score values. I also combine risk dimensions, including:

- CIBIL score × EMI burden
- CIBIL score × late-payment history
- CIBIL score × credit utilization

For the CIBIL/EMI segments, the SQL reports application count, observed default rate, portfolio share, total loan exposure, and exposure associated with defaulted applicants.

## Key SQL Concepts Demonstrated

- `SELECT`, `WHERE`, `GROUP BY`, `HAVING`, and `ORDER BY`
- Aggregate functions: `COUNT`, `SUM`, `AVG`, `MIN`, and `MAX`
- Conditional segmentation using `CASE`
- Conditional aggregation to calculate defaulted loan exposure
- Subqueries for portfolio-level percentages
- Derived metrics and percentage calculations
- `NULLIF` to avoid division-by-zero errors
- Multi-dimensional grouping for risk segmentation

## Business Value

The analysis is designed to help a lending team:

- See the scale of observed defaults and the amount of requested loan exposure associated with them.
- Compare risk patterns across credit quality, repayment behaviour, affordability, and loan characteristics.
- Identify segments that may warrant closer monitoring.
- Evaluate how well an existing risk score distinguishes groups with different observed outcomes.
- Use consistent, clearly defined metrics in portfolio reporting.

## Important Analytical Limitations

- This is a historical, descriptive analytics project. Group differences show **associations**, not proof that a factor causes loan default.
- The available `default_risk_score` is evaluated against observed outcomes; this SQL analysis does not train or validate a predictive machine-learning model.
- The results depend on the completeness, accuracy, and representativeness of the supplied dataset.
- Demographic and geographic attributes should be handled carefully and should not be used as a standalone basis for discriminatory lending decisions. Real lending policies require appropriate regulatory, compliance, model-validation, and fairness reviews.
- The SQL script includes initial data-quality checks, but further validation may be needed before production use.



