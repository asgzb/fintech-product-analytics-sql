# Fintech EMI Repayment Product Analytics

## Product Description
Loan EMI repayment is a digital repayment product under the Bills & Recharges section of the Paytm application. This product allows users to pay their pending loan EMIs on-time securely, seamlessly and conveniently using their Paytm app.

## Business Objectives
Improve the EMI repayment reliability while minimising user friction and churn.

## North Star Metrics
We've chosen On-Time Repayment Rate as our North Star metric. On-Time Repayment Rate means the percentage of EMIs due in a given month that are successfully paid on or before the due date.

On-Time EMI Repayment Rate = On-Time EMIs / Total Due EMIs
where,
- Period: Calendar month
- EMI counted as 'due' if due_date falls within the month
- EMI counted as 'on-time' if: payment_status = 'success' and payment_attempt_date <= due_date

On-Time Repayment Rate depends on user intent and system reliability & experience. This can be best captured via:
1. Payment attempt rate
2. Payment success rate
3. User financial readiness

## Supporting Metrics
These diagnose the NSM.

1. Payment Attempt Rate - Percentage of due EMIs where users attempts payment before due date
2. Payment Success Rate - Successful payments divided by total payment attempts
3. Auto-Debit Adoption Rate - Percentage of EMIs enrolled in auto-debit
4. Late Payment Rate - EMIs paid after due date divided by total due EMIs
5. Payment Failure Rate - Failed attempts divided by total attempts

### Engagement Metrics
These metrics explain why Attempt Rate & Success Rate move:

- Reminder open rate - Percentage of sent reminders that were opened. A low open rate means lower awareness which leads to lower attempt rate.
- Push notification CTR - Percentage of reminder notifications that led to "Pay EMI" click
- Login rate near due date - Percentage of users logging in within 3 days before due date
- EMI page visit rate - Percentage of due users who visited EMI page before due date

## Experience Metrics
These metrics affect conversion from attempt to success:

- Time to complete payment - Average time between clicking "Pay" and payment confirmation
- Drop-off at payment step - Users who clicked "Pay" but did not complete payment
- OTP failure rate - Failed OTP verifications divided by OTP attempts
- Error frequency - Payment errors per 1,000 attempts. Signals system instability.

## Reliability Metrics
These influence payment success rate directly:

- Gateway uptime % - Operational time divided by total scheduled time. Usually engineering metric but affects PM decisions.
- Technical failure rate - System failures (timeouts, API errors) divided by total attempts
- Payment processing latency - Time from submission to gateway response. High latency reduces UX trust.

## Guardrail Metrics
We must prevent local optimisation damage.

1. Customer Complaint Rate - Complaints related to repayment per total active users
2. EMI Product Churn Rate - Percentage of users who had an active loan but stopped using repayment product before loan closure.
3. Reminder opt-out Rate - Users disabling reminders per total users receiving reminders
4. Payment Fraud Rate - Fradulent payments per total payments
5. App Uninstalls Rate Near Due Date - Signals over aggressive reminders

## Business Questions to Answer
The analytics project must answer:

1. What is the current On-Time EMI payment rate?
2. Which customer segment has lowest on-time rate?
    a. Credit score band
    b. Acquisition channel
    c. City tier
3. Is the issue attempt-related or success-related?
4. Which payment mode has highest failure rate?
5. Does auto-debit significantly improve on-time rate?
6. How mich revenue comes from late fees?
7. If late payments reduce by 20%, what is the revenue impact?

## Assumptions

1. Only one EMI per loan per month
2. Each EMI is considered paid once first success occurs
3. Multiple payment attempts allowed
4. Partial payments are trated as unpaid unless full EMI paid
5. Timezone consistent across dataset
6. No grace period unless explicitly defined
7. EMI due date does not change dynamically

## Edge Cases

### Case 1: Multiple successful payments
If duplicate success enteries exist, count only the earliest success. Use MIN(payment_attempt_date)

### Case 2: Payment success after failure
Common scenarios include:
- Attempt 1: failed
- Attempt 2: success (before due date)
This should count as on-time.

### Case 3: Payment exactly at 00:00 on due date
payment_success_date <= due_date is on-time

### Case 4: Partial payments
If emi_amount = 2000 & user pays 1000 before due date then it should be treated as unpaid unless full amount is covered.

### Case 5: No payment attempt
Count as not on-time

### Case 6: Auto-debit failure + Manual retry
Manual retry success before due → on-time.

### Case 7: Payment pending (processing delay)
If submission before due date but success confirmed after, then count based on submission timestamp (not confirmation).

## Analytical Focus Area
- Attempt behaviour
- Payment success
- Engagement drivers
- System reliability
- Late payment impact

## Repository Structure
- docs/ : Business logic & metric definitions
- schema/ : Table design
- sql/ : Query definitions
- data/ : Synthetic dataset
- analysis/ : Final insights & reports