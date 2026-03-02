# Table Definitions - EMI Repayment Product

This document defines all database tables used in the fintech EMI analytics project. Each table includes:
- Column name
- Data Type
- Primary Key (PK)
- Foreign Key (FK)
- Business Purpose

## Table: Users
Description: Stores user-level information for segmentation and cohort analysis.

| Column name         | Data Type  | Key | Description |
|---------------------|------------|-----|-------------|
| user_id             | BIGINT     | PK  | Unique user identifier |
| signup_date         | DATE       |     | Date user signed up |
| acquisition_channel | VARCHAR    |     | organic / paid / referral |
| city_tier           | VARCHAR    |     | Tier1 / Tier2 / Tier3 |
| credit_score_band   | VARCHAR    |     | Low / Medium / High |
| is_active           | BOOLEAN    |     | Whether user currently active |
| created_at          | TIMESTAMP  |     | Record creation timestamp |

## Table: Loans
Description: Stores loan-level information.

| Column Name         | Data Type  | Key | Description |
|---------------------|------------|-----|-------------|
| loan_id             | BIGINT     | PK  | Unique loan identifier |
| user_id             | BIGINT     | FK  | Refernce users.user_id |
| disbursal_date      | DATE       |     | Loan disbursal date |
| loan_amount         | DECIMAL    |     | Total loan amount |
| tenure_months       | INT        |     | Loan tenure in months |
| interest_rate       | DECIMAL    |     | Annual interest rate |
| loan_status         | VARCHAR    |     | active / closed / defaulted |
| auto_debit_enabled  | BOOLEAN    |     | Whether auto-debited enabled |
| created_at          | TIMESTAMP  |     | Record creation timestamp |

## Table: EMI_Schedule
Description: Stores EMI obligations for each loan.

| Column Name  | Data Type | Key | Description |
|--------------|-----------|-----|-------------|
| emi_id       | BIGINT    | PK  | Unique EMI identifier |
| loan_id      | BIGINT    | FK  | References loans.loan_id |
| emi_number   | INT       |     | EMI sequence number (1,2,3...) |
| due_date     | DATE      |     | EMI due date |
| emi_amount   | DECIMAL   |     | EMI amount |
| grace_days   | INT       |     | Allowed grace days |
| emi_status   | VARCHAR   |     | due / paid / late / defaulted |
| created_at   | TIMESTAMP |     | Record creation timestamp |

## Table: Payments
Description: Stores payment attempts for EMIs. Multiple payments allowed per EMI.

| Column Name               | Data Type | Key | Description |
|----------------------------|-----------|-----|-------------|
| payment_id                 | BIGINT    | PK  | Unique payment attempt ID |
| emi_id                     | BIGINT    | FK  | References emi_schedule.emi_id |
| user_id                    | BIGINT    | FK  | References users.user_id |
| payment_mode               | VARCHAR   |     | UPI / card / netbanking |
| is_auto_debit              | BOOLEAN   |     | Whether payment triggered via auto-debit |
| auto_debit_retry_count     | INT       |     | Retry count for auto-debit |
| payment_submission_time    | TIMESTAMP |     | Time payment was submitted |
| payment_confirmation_time  | TIMESTAMP |     | Time payment was confirmed |
| payment_amount             | DECIMAL   |     | Amount paid |
| payment_status             | VARCHAR   |     | success / failed / pending |
| failure_reason             | VARCHAR   |     | Reason if failed |
| created_at                 | TIMESTAMP |     | Record creation timestamp |

## Table: Reminders
Description: Stores reminder notifications sent to users.

| Column Name | Data Type | Key | Description |
|-------------|-----------|-----|-------------|
| reminder_id | BIGINT    | PK  | Unique reminder ID |
| emi_id      | BIGINT    | FK  | References emi_schedule.emi_id |
| user_id     | BIGINT    | FK  | References users.user_id |
| sent_time   | TIMESTAMP |     | Time reminder was sent |
| opened      | BOOLEAN   |     | Whether reminder was opened |
| clicked_pay | BOOLEAN   |     | Whether user clicked pay from reminder |
| channel     | VARCHAR   |     | push / sms / email |

## Table: App_Events
Description: Stores user behavioral events in app.

| Column Name | Data Type | Key | Description |
|-------------|-----------|-----|-------------|
| event_id    | BIGINT    | PK  | Unique event ID |
| user_id     | BIGINT    | FK  | References users.user_id |
| emi_id      | BIGINT    | FK  | Nullable – if event relates to specific EMI |
| event_name  | VARCHAR   |     | login / view_emi / click_pay / otp_failed / payment_success |
| event_time  | TIMESTAMP |     | Time of event |