-- Payments referencing vaid EMIs
SELECT 
    COUNT(*) AS invalid_payments
FROM payments p
LEFT JOIN 
    emis e ON p.emi_id = e.emi_id
WHERE 
    e.emi_id IS NULL;

-- Negative payment amounts
SELECT 
    COUNT(*) AS negative_payments
FROM payments
WHERE 
    payment_amount < 0;

-- Timestamp consistency: payment confirmation time should be after payment submission time
SELECT 
    COUNT(*) AS invalid_timestamps
FROM payments
WHERE 
    payment_confirmation_time < payment_submission_time;

-- Delete payments with timestmap inconsistencies
DELETE FROM payments
WHERE payment_confirmation_time < payment_submission_time;

-- Number of EMIs with multiple payment attempts
SELECT
    COUNT(*) AS emis_with_multiple_payments
FROM (
    SELECT emi_id
    FROM payments
    GROUP BY emi_id
    HAVING COUNT(*) > 1
) t;

-- Partial payments exists
SELECT 
    COUNT(*) AS partial_payments
FROM payments p
JOIN
    emis e ON p.emi_id = e.emi_id
WHERE 
    p.payment_amount < e.emi_amount AND p.payment_amount > 0;

-- EMI fully paid check
SELECT 
    COUNT(*) AS underpaid_emis
FROM (
    SELECT
        e.emi_id,
        SUM(CASE WHEN payment_status = 'success' THEN payment_amount ELSE 0 END) AS total_paid,
        MAX (e.emi_amount) AS emi_amount
        FROM payments p
        JOIN emis e ON p.emi_id = e.emi_id
        GROUP BY e.emi_id
) t
WHERE total_paid < emi_amount;

-- Attempt rate
SELECT
    COUNT(DISTINCT p.emi_id) * 1.0 / COUNT(DISTINCT e.emi_id) AS attempt_rate
FROM emis e
LEFT JOIN payments p ON e.emi_id = p.emi_id;

-- Attempt rate by credit band
SELECT
    u.credit_score_band,
    COUNT(DISTINCT p.emi_id) * 1.0 / COUNT(DISTINCT e.emi_id) AS attempt_rate
FROM emis e
JOIN loans l ON e.loan_id = l.loan_id
JOIN users u ON l.user_id = u.user_id
LEFT JOIN payments p ON e.emi_id = p.emi_id
GROUP BY u.credit_score_band;

-- Reminder open rate by city tier
SELECT
    u.city_tier,
    AVG(CASE WHEN r.is_opened = TRUE THEN 1 ELSE 0 END) AS open_rate
FROM reminders r
JOIN users u ON r.user_id = u.user_id
GROUP BY u.city_tier;

-- Clean reminder open column as a category
DELETE
FROM reminders
WHERE is_opened = 'is_opened';

-- Reminder open rate
SELECT is_opened, COUNT(*) 
FROM reminders 
GROUP BY is_opened;

-- Failure rate by payment method
SELECT
    payment_mode,
    AVG(CASE WHEN payment_status = "failed" THEN 1 ELSE 0 END) AS failure_rate
FROM payments
GROUP BY payment_mode;

-- Delete payment mode as a category
DELETE 
FROM payments
WHERE payment_mode = 'payment_mode';

-- Failure category distribution
SELECT
    failure_category,
    COUNT(*) * 1.0 / SUM(COUNT(*)) OVER () AS proportion
FROM payments
WHERE payment_status = "failed"
GROUP BY failure_category;

-- Retry effectiveness
SELECT
    auto_debit_retry_count,
    AVG(CASE WHEN payment_status = 'success' THEN 1 ELSE 0 END) AS success_rate
FROM payments
WHERE is_auto_debit = TRUE
GROUP BY auto_debit_retry_count
ORDER BY auto_debit_retry_count;

-- On time payment rate by credit band
WITH first_success AS (
    SELECT
        p.emi_id,
        MIN(p.payment_submission_time) AS first_payment_time
    FROM payments p
    WHERE p.payment_status = 'success'
    GROUP BY p.emi_id
)

SELECT
    u.credit_score_band,
    AVG(CASE WHEN fs.first_payment_time <= e.due_date THEN 1 ELSE 0 END) AS on_time_rate
FROM emis e
JOIN loans l ON e.loan_id = l.loan_id
JOIN users u ON l.user_id = u.user_id
LEFT JOIN first_success fs ON e.emi_id = fs.emi_id
GROUP BY u.credit_score_band;

-- Late payment rate by credit band
SELECT
    u.credit_score_band,
    AVG(CASE WHEN p.payment_submission_time> e.due_date THEN 1 ELSE 0 END) AS late_rate
FROM payments p
JOIN emis e ON p.emi_id = e.emi_id
JOIN loans l ON e.loan_id = l.loan_id
JOIN users u ON l.user_id = u.user_id
WHERE p.payment_status = 'success'
GROUP BY u.credit_score_band;

-- Clean credit_score_band as a category
DELETE
FROM users
WHERE credit_score_band = 'credit_score_band';

-- Failure spikes
SELECT
    DATE(payment_submission_time) AS day,
    AVG(CASE WHEN payment_status = 'failed' THEN 1 ELSE 0 END) AS failure_rate
FROM payments
GROUP BY day
ORDER BY failure_rate DESC
LIMIT 10;

-- Payment latency distribution
SELECT
    AVG(strftime('%s', payment_confirmation_time) - strftime('%s', payment_submission_time)) AS avg_latency_seconds
FROM payments;

-- Funnel drop-off
SELECT
    COUNT(DISTINCT CASE WHEN event_name = 'login' THEN user_id END) AS login_users,
    COUNT(DISTINCT CASE WHEN event_name = 'click_pay' THEN user_id END) AS click_users,
    COUNT(DISTINCT CASE WHEN event_name = 'payment_success' THEN user_id END) AS success_users
FROM app_events;

-- On-time emi payment rate
WITH first_success AS (
    SELECT
        emi_id,
        MIN(payment_submission_time) AS first_payment_time
    FROM payments
    WHERE payment_status = 'success'
    GROUP BY emi_id
)

SELECT
    AVG(CASE WHEN fs.first_payment_time <= e.due_date THEN 1 ELSE 0 END) AS on_time_emi_rate
FROM emis e
LEFT JOIN first_success fs ON e.emi_id = fs.emi_id;