WITH first_emi AS (
    SELECT
        e.emi_id,
        e.loan_id,
        e.due_date,
        e.emi_amount,
        l.user_id
    FROM emis e
    JOIN loans l ON e.loan_id = l.loan_id
    WHERE e.emi_number = 1
),

payment_agg AS (
    SELECT
        p.emi_id,
        p.payment_submission_time,
        p.payment_amount,
        f.emi_amount,
        SUM(p.payment_amount) OVER (
            PARTITION BY p.emi_id
            ORDER BY p.payment_submission_time
        ) AS cumulative_paid
        FROM payments p
        JOIN first_emi f ON p.emi_id = f.emi_id
        WHERE p.payment_status = 'success'
),

full_payment_time AS (
    SELECT
        emi_id,
        MIN(payment_submission_time) AS full_payment_time
    FROM payment_agg
    WHERE cumulative_paid >= emi_amount
    GROUP BY emi_id
)

SELECT
    COUNT(DISTINCT CASE
        WHEN fpt.full_payment_time <= datetime(f.due_date, '+7 days')
        THEN f.user_id
        END) * 1.0 / COUNT(DISTINCT f.user_id) AS activation_rate
    FROM first_emi f
    LEFT JOIN full_payment_time fpt ON f.emi_id = fpt.emi_id;
