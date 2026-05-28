WITH funnel AS (
    SELECT
        emi_id,
        MAX(CASE WHEN event_name = 'login' THEN 1 ELSE 0 END) AS login,
        MAX(CASE WHEN event_name = 'view_emi_details' THEN 1 ELSE 0 END) AS view_emi,
        MAX(CASE WHEN event_name = 'click_pay' THEN 1 ELSE 0 END) AS click_pay,
        MAX(CASE WHEN event_name = 'payment_success' THEN 1 ELSE 0 END) AS success
    FROM app_events
    GROUP BY emi_id
)

SELECT
    COUNT(*) AS total_emis,
    
    -- Step 1 - Login
    SUM(login) AS login_emis,

    -- Step 2 (only if login happened) - View EMI details
    SUM(CASE WHEN login = 1 AND view_emi = 1 THEN 1 ELSE 0 END) AS view_emis,

    -- Step 3 (only if view happened) - Click pay
    SUM(CASE WHEN login = 1 AND view_emi = 1 AND click_pay = 1 THEN 1 ELSE 0 END) AS click_emis,

    -- Step 4 (only if click happened) - Payment success
    SUM(CASE WHEN login = 1 AND view_emi = 1 AND click_pay = 1 AND success = 1 THEN 1 ELSE 0 END) AS success_emis
FROM funnel;

-- Sanity check: Event distribution
SELECT
    event_name, COUNT(*)
FROM app_events
GROUP BY event_name;

-- Sanity check: EMIs with no success
SELECT COUNT(*)
FROM (
    SELECT emi_id
    FROM app_events
    GROUP BY emi_id
    HAVING SUM(CASE WHEN event_name = 'payment_success' THEN 1 ELSE 0 END) = 0
);