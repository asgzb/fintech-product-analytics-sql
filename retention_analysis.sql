WITH user_cohort AS (
    SELECT
        user_id,
        DATE(signup_date) AS signup_date,
        strftime('%Y-%m', DATE(signup_date)) AS cohort_month
    FROM users
),

user_payments AS (
    SELECT
        user_id,
        DATE(payment_submission_time) AS payment_date
    FROM payments
    WHERE payment_status = 'success'
),

cohort_activity AS (
    SELECT
        uc.user_id,
        uc.cohort_month,
        u.acquisition_channel,

        (
            CAST(strftime('%Y', DATE(up.payment_date)) AS INTEGER) - 
            CAST(strftime('%Y', DATE(uc.signup_date)) AS INTEGER)
        ) * 12 +
        (
            CAST(strftime('%m', DATE(up.payment_date)) AS INTEGER) - 
            CAST(strftime('%m', DATE(uc.signup_date)) AS INTEGER)
        ) AS month_number
    FROM user_cohort uc
    JOIN user_payments up ON uc.user_id = up.user_id
    JOIN users u ON uc.user_id = u.user_id
),

cohort_size AS (
    SELECT
        strftime('%Y-%m', DATE(signup_date)) AS cohort_month,
        acquisition_channel,
        COUNT(DISTINCT user_id) AS total_users
    FROM users
    GROUP BY cohort_month, acquisition_channel
),

retention AS (
    SELECT
        cohort_month,
        month_number,
        acquisition_channel,
        COUNT(DISTINCT user_id) AS active_users
    FROM cohort_activity
    GROUP BY cohort_month, month_number, acquisition_channel
)

SELECT
    r.cohort_month,
    r.month_number,
    r.acquisition_channel,
    ROUND(r.active_users * 1.0 / cs.total_users, 3) AS retention_rate
FROM retention r
JOIN cohort_size cs 
    ON r.cohort_month = cs.cohort_month
    AND r.acquisition_channel = cs.acquisition_channel
WHERE r.month_number IS NOT NULL
ORDER BY r.cohort_month, r.acquisition_channel, r.month_number;

-- Inspecting raw data for validation
-- SELECT signup_date, payment_submission_time
-- FROM users u
-- JOIN payments p ON u.user_id = p.user_id
-- LIMIT 10;