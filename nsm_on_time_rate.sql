-- NSM On-Time Rate
WITH payment_aggregation AS (
    SELECT
        p.emi_id,
        p.payment_submission_time,
        e.emi_amount,
        SUM(p.payment_amount) OVER (
            PARTITION BY p.emi_id
            ORDER BY p.payment_submission_time
        ) AS cumulative_paid
    FROM payments p
    JOIN emis e ON p.emi_id = e.emi_id
    WHERE p.payment_status = 'success'
),

full_payment_time AS (
    SELECT
        emi_id,
        MIN(payment_submission_time) AS full_payment_time
    FROM payment_aggregation
    WHERE cumulative_paid >= emi_amount
    GROUP BY emi_id
)

SELECT
    COUNT(CASE WHEN f.full_payment_time <= e.due_date THEN 1 END) *1.0 / COUNT(*) AS on_time_emi_rate
    FROM emis e
    LEFT JOIN full_payment_time f ON e.emi_id = f.emi_id;

-- Attempt Rate
SELECT
    COUNT(DISTINCT p.emi_id) * 1.0 / COUNT(DISTINCT e.emi_id) AS attempt_rate
FROM emis e
LEFT JOIN payments p ON e.emi_id = p.emi_id;

-- Success Rate
SELECT
    SUM(CASE WHEN payment_status = 'success' THEN 1 ELSE 0 END) * 1.0 / COUNT(*) AS success_rate
FROM payments;

-- Failure by payment mode
SELECT
    payment_mode,
    AVG(CASE WHEN payment_status = 'failed' THEN 1 ELSE 0 END) AS failure_rate
FROM payments
GROUP BY payment_mode;

-- Failure by credit band
SELECT
    u.credit_score_band,
    AVG(CASE WHEN p.payment_status = 'failed' THEN 1 ELSE 0 END) AS failure_rate
FROM payments p
JOIN users u ON p.user_id = u.user_id
GROUP BY u.credit_score_band;

-- Failure by city tier
SELECT
    u.city_tier,
    AVG(CASE WHEN p.payment_status = 'failed' THEN 1 ELSE 0 END) AS failure_rate
FROM payments p
JOIN users u ON p.user_id = u.user_id
GROUP BY u.city_tier;

-- Failure category
SELECT
    failure_category,
    COUNT(*) * 1.0 / SUM(COUNT(*)) OVER () AS proportion
FROM payments
WHERE payment_status = 'failed'
GROUP BY failure_category;

-- Retry effectiveness
SELECT
    auto_debit_retry_count,
    AVG(CASE WHEN payment_status = 'success' THEN 1 ELSE 0 END) AS success_rate
FROM payments
GROUP BY auto_debit_retry_count;