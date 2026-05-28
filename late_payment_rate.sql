-- Late payment behaviour of customers
WITH payment_agg AS (
    SELECT
        p.emi_id,
        p.payment_submission_time,
        p.payment_amount,
        e.emi_amount,
        e.due_date,
        l.user_id,

        SUM(p.payment_amount) OVER (
            PARTITION BY p.emi_id
            ORDER BY p.payment_submission_time
        ) AS cumulative_paid
    
    FROM payments p
    JOIN emis e ON p.emi_id = e.emi_id
    JOIN loans l ON e.loan_id = l.loan_id
    WHERE p.payment_status = 'success'
),

full_payment_time AS (
    SELECT
        emi_id,
        user_id,
        due_date,
        MIN(payment_submission_time) AS full_payment_time
    FROM payment_agg
    WHERE cumulative_paid >= emi_amount
    GROUP BY emi_id
)

SELECT
    u.city_tier,
    u.credit_score_band,
    u.acquisition_channel,

    COUNT(*) AS total_emis,

    SUM(CASE WHEN f.full_payment_time > f.due_date THEN 1 ELSE 0 END) AS late_emis,
    ROUND(
        SUM(CASE WHEN f.full_payment_time > f.due_date THEN 1 ELSE 0 END) * 1.0 / COUNT(*), 3) AS late_rate
        FROM full_payment_time f
        JOIN users u ON f.user_id = u.user_id
        GROUP BY u.city_tier, u.credit_score_band, u.acquisition_channel
        ORDER BY late_rate DESC;