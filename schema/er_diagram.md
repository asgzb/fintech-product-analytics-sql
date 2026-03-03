# ER Diagram - EMI Repayment Product

This document describes relationships between core entities in the EMI repayment analytics system. Relationship notation:
1 ---< means one-to-many

--------------------------------------------------
                    users
--------------------------------------------------
user_id (PK)
signup_date
acquisition_channel
city_tier
credit_score_band
is_active
created_at
--------------------------------------------------
        1
        |
        | (one user can have multiple loans)
        |
        V
--------------------------------------------------
                    loans
--------------------------------------------------
loan_id (PK)
user_id (FK → users.user_id)
disbursal_date
loan_amount
tenure_months
interest_rate
loan_status
auto_debit_enabled
created_at
--------------------------------------------------
        1
        |
        | (one loan has multiple EMIs)
        |
        V
--------------------------------------------------
                 emi_schedule
--------------------------------------------------
emi_id (PK)
loan_id (FK → loans.loan_id)
emi_number
due_date
emi_amount
grace_days
emi_status
created_at
--------------------------------------------------
        1
        |
        | (one EMI can have multiple payments)
        |
        V
--------------------------------------------------
                   payments
--------------------------------------------------
payment_id (PK)
emi_id (FK → emi_schedule.emi_id)
user_id (FK → users.user_id)
payment_mode
is_auto_debit
auto_debit_retry_count
payment_submission_time
payment_confirmation_time
payment_amount
payment_status
failure_reason
created_at
--------------------------------------------------

Additional Relationships
--------------------------------------------------

users 1 ——< reminders
users 1 ——< app_events
emi_schedule 1 ——< reminders
emi_schedule 1 ——< app_events (nullable reference)

--------------------------------------------------
                   reminders
--------------------------------------------------
reminder_id (PK)
emi_id (FK → emi_schedule.emi_id)
user_id (FK → users.user_id)
sent_time
opened
clicked_pay
channel
--------------------------------------------------

--------------------------------------------------
                   app_events
--------------------------------------------------
event_id (PK)
user_id (FK → users.user_id)
emi_id (nullable FK → emi_schedule.emi_id)
event_name
event_time
--------------------------------------------------

# Relationship Summary

1 user → many loans  
1 loan → many EMIs  
1 EMI → many payments  
1 user → many reminders  
1 user → many app_events  
1 EMI → many reminders  
1 EMI → many related app_events  

Key Analytical Implications:

- On-Time EMI logic is computed at EMI level.
- Fully-paid logic aggregates multiple payments per EMI.
- Partial payments supported via multiple payment rows.
- Engagement metrics derived from reminders + app_events.
- Strict vs grace logic computed using due_date + submission_time.