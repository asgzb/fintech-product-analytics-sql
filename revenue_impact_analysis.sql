-- We're assuming an average late fee per EMI = INR 200.

-- Total late EMIs
WITH payment_agg AS (
    SELECT
        p.emi_id,
        p.payment_submission_time,
        p.payment_amount,
        e.emi_amount,
        e.due_date,

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
        MIN(payment_submission_time) AS full_payment_time,
        MAX(due_date) AS due_date
    FROM payment_agg
    WHERE cumulative_paid >= emi_amount
    GROUP BY emi_id
)

SELECT
    COUNT(*) AS total_emis,
    SUM(CASE WHEN full_payment_time > due_date THEN 1 ELSE 0 END) AS late_emis
    FROM full_payment_time;