-- Failure rate by payment mode & credit band
SELECT
    payment_mode,
    u.credit_score_band,
    COUNT(*) AS total_attempts,
    sum(CASE WHEN payment_status = 'failed' THEN 1 ELSE 0 END) AS failed_attempts,
    ROUND(
        SUM(CASE WHEN payment_status = 'failed' THEN 1 ELSE 0 END) * 1.0 / COUNT(*), 3) AS failure_rate
FROM payments p
JOIN users u ON p.user_id = u.user_id
GROUP BY payment_mode, u.credit_score_band
ORDER BY payment_mode, u.credit_score_band;

-- Failure by payment mode & city tier
SELECT
    payment_mode,
    u.city_tier,
    ROUND(
        SUM(CASE WHEN payment_status = 'failed' THEN 1 ELSE 0 END) * 1.0 / COUNT(*), 3) AS failure_rate
FROM payments p
JOIN users u ON p.user_id = u.user_id
GROUP BY payment_mode, u.city_tier;