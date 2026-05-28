# ------------------------------------------------------------
# Synthetic Fintech EMI Repayment Data Generator
# ------------------------------------------------------------

import numpy as np
import pandas as pd
import random
from datetime import datetime, timedelta

# ------------------------------------------------------------
# GLOBAL SETTINGS
# ------------------------------------------------------------

SEED = 42
NUM_USERS = 10000

np.random.seed(SEED)
random.seed(SEED)

TODAY = datetime.today()

# ------------------------------------------------------------
# HELPER FUNCTIONS
# ------------------------------------------------------------

def random_date(start_date, end_date):
    """Generate a random datetime between `start` and `end`."""
    delta = end_date - start_date
    random_days = random.randint(0, delta.days)
    return start_date + timedelta(days = random_days)

# ------------------------------------------------------------
# BEHAVIOUR / PROBABILITY FUNCTIONS
# ------------------------------------------------------------

def get_attempt_probability(user):
    """Determine payment attempt probability based on user attributes."""
    base = {
        "low": 0.65,
        "medium": 0.75,
        "high": 0.85
    }[user["credit_score_band"]]

    #base_prob = base.get(user["credit_score_band"], 0.75)

    if user["credit_score_band"] == "low":
        base -= 0.1
    elif user["credit_score_band"] == "high":
        base += 0.05

    if user["city_tier"] == "tier3":
        base -= 0.05
    elif user["city_tier"] == "tier1":
        base += 0.05

    if user["acquisition_channel"] == "referral":
        base += 0.05
    elif user["acquisition_channel"] == "paid":
        base -= 0.05

    return max(0.5, min(0.9, base))  # Ensure probability is between 0.5 and 0.9

def get_open_probability(user):
    """Determine reminder open probability based on user attributes."""
    base_prob = 0.5

    if user["city_tier"] == "tier3":
        base_prob -= 0.05
    elif user["city_tier"] == "tier2":
        base_prob += 0.02
    elif user["city_tier"] == "tier1":
        base_prob += 0.05

    return max(0.3, min(0.7, base_prob))  # Ensure probability is between 0.3 and 0.7

def get_failure_reason(payment_mode):
    return np.random.choice(
        ["insufficient_funds", "otp_failure", "gateway_error", "timeout"],
        p = [0.4, 0.25, 0.2, 0.15]
        )

def get_late_probability(user):
    return {
        "high" : 0.10,
        "medium" : 0.20,
        "low" : 0.35
    }[user["credit_score_band"]]

def classify_failure(reason):
    if reason in ["gateway_error", "timeout"]:
        return "technical"
    elif reason is None:
        return None
    else:
        return "user"

# ------------------------------------------------------------
# TABLE 1 - USERS
# ------------------------------------------------------------

def generate_users():

    users = []

    acquisition_channels = ["Organic", "paid", "referral"]
    acquisition_probs = [0.5, 0.35, 0.15]

    credit_bands = ["high", "medium", "low"]
    credit_probs = [0.5, 0.3, 0.2]

    city_tiers = ["tier1", "tier2", "tier3"]
    city_probs = [0.5, 0.3, 0.2]

    start_date = TODAY - timedelta(days = 365 * 2)  # 2 years ago

    for user_id in range(1, NUM_USERS + 1):

        signup_date = random_date(start_date, TODAY)

        users.append({
            "user_id" : user_id,
            "signup_date" : signup_date,
            "acquisition_channel" : np.random.choice(acquisition_channels, p = acquisition_probs),
            "city_tier" : np.random.choice(city_tiers, p = city_probs),
            "credit_score_band" : np.random.choice(credit_bands, p = credit_probs),
            "is_active" : True,
            "created_at": signup_date
        })

    users_df = pd.DataFrame(users)
    return users_df

def is_bad_day(date):
    return np.random.rand() < 0.1  # 10% chance of being a bad day

# ------------------------------------------------------------
# TABLE 2 - LOANS
# ------------------------------------------------------------

def generate_loans(users_df):

    loans = []
    loan_id = 1

    for _, user in users_df.iterrows():

        # decide number of loans for this user
        num_loans = 1 if np.random.rand() < 0.8 else 2

        for _ in range(num_loans):

            disbursal_date = random_date(user["signup_date"], TODAY)

            loans.append({
                "loan_id" : loan_id,
                "user_id" : user["user_id"],
                "loan_amount" : np.random.uniform(10000, 100000),
                "tenure_months" : random.randint(6, 12),
                "interest_rate" : np.random.uniform(12, 24),
                "loan_status" : "active",
                "auto_debit_enabled" : np.random.rand() < 0.55,
                "disbursal_date" : disbursal_date,
                "created_at" : disbursal_date
            })
            
            loan_id += 1
    
    loans_df = pd.DataFrame(loans)
    return loans_df

# ------------------------------------------------------------
# TABLE 3 - EMI SCHEDULE
# ------------------------------------------------------------

def generate_emi_schedule(loans_df):

    emis = []
    emi_id = 1

    for _, loan in loans_df.iterrows():

        tenure = int(loan["tenure_months"])
        emi_amount = (loan["loan_amount"] * loan["interest_rate"] * ((1 + loan["interest_rate"]) ** tenure)) / (((1 + loan["interest_rate"]) ** tenure) - 1)

        for i in range(1, tenure + 1):

            due_date = loan["disbursal_date"] + timedelta(days = 30 * i)

            emis.append({
                "emi_id" : emi_id,
                "loan_id" : loan["loan_id"],
                "emi_number" : i,
                "due_date" : due_date,
                "emi_amount" : emi_amount,
                "grace_days" : 2,
                "emi_status" : "due",
                "created_at" : due_date - timedelta(days = 30)
            })

            emi_id += 1

    emis_df = pd.DataFrame(emis)
    return emis_df

# ------------------------------------------------------------
# TABLE 4 - PAYMENTS
# ------------------------------------------------------------

def generate_payments(emis_df, users_df, loans_df):

    payments = []
    payment_id = 1

    for _, emi in emis_df.iterrows():

        loan = loans_df[loans_df["loan_id"] == emi["loan_id"]].iloc[0]
        user_id = loan["user_id"]
        user = users_df[users_df["user_id"] == user_id].iloc[0]
        
        remaining_amount = emi["emi_amount"]
        payment_completed = False
        
        max_attemtpts = np.random.randint(1, 4)  # 1 to 3 attempts

        for attempt_num in range(max_attemtpts):
            
            if payment_completed:
                break

            # payment attempt probability
            attempt_prob = get_attempt_probability(user)
            attempt = np.random.rand() < attempt_prob

            if not attempt:
                continue  # User did not attempt payment

            payment_mode = np.random.choice(["UPI", "card", "netbanking"],
                                            p = [0.6, 0.25, 0.15])
            
            failure_probs = {
                "UPI" : 0.15,
                "card" : 0.05,
                "netbanking" : 0.08}
            
            failure_prob = failure_probs[payment_mode]

            # Apply system instability
            if is_bad_day(emi["due_date"]):
                failure_prob *= 1.5
                failure_prob = min(failure_prob, 0.95)
            
            if loan["auto_debit_enabled"] and attempt_num == 0:
                # Auto-debit first attempt
                success = np.random.rand() < 0.70
            else:
                success = np.random.rand() > failure_probs[payment_mode]

            if loan["auto_debit_enabled"] and not success:
                retry_success = np.random.rand() < 0.60
                if retry_success:
                    success = True

            is_partial = False

            if success:
                is_partial = np.random.rand() < 0.10 # 10% chance

            if success:
                if is_partial:
                    payment_amount = remaining_amount * np.random.uniform(0.5, 0.8)  # Partial payment between 50% to 80%
                else:
                    payment_amount = remaining_amount
            else:
                payment_amount = 0
            
            if success:
                remaining_amount -= payment_amount
                ramining_amount = max(0, remaining_amount)

                if remaining_amount <= 1:
                    payment_completed = True
            

            submission_time = emi["due_date"] - timedelta(days = random.randint(0, 3)) + timedelta(minutes = attempt_num * 10)  # Payment attempt before or on due date

            latency = max(5, np.random.uniform(5, 60))  # Minimum latency of 5 seconds
            confirmation_time = submission_time + timedelta(seconds = latency)  # Confirmation time after submission

            failure_reason = None if success else get_failure_reason(payment_mode)

            payments.append({
                "payment_id" : payment_id,
                "emi_id" : emi["emi_id"],
                "user_id" : user_id,
                "payment_mode" : payment_mode,
                "is_auto_debit" : loan["auto_debit_enabled"],
                "auto_debit_retry_count" : attempt_num,
                "payment_submission_time" : submission_time,
                "payment_confirmation_time" : confirmation_time,
                "payment_amount" : payment_amount,
                "payment_status" : "success" if success else "failed",
                "failure_reason" : failure_reason,
                "failure_category" : classify_failure(failure_reason),
                "created_at" : confirmation_time
            })

            payment_id += 1

    payments_df = pd.DataFrame(payments)
    return payments_df

# ------------------------------------------------------------
# TABLE 5 - REMINDERS
# ------------------------------------------------------------

def generate_reminders(emis_df, users_df, loans_df):

    reminders = []
    reminder_id = 1

    for _, emi in emis_df.iterrows():

        if np.random.rand() < 0.8:

            loan = loans_df[loans_df["loan_id"] == emi["loan_id"]].iloc[0]
            user_id = loan["user_id"]

            sent_time = emi["due_date"] - timedelta(days = random.randint(1, 3))

            user = users_df[users_df["user_id"] == user_id].iloc[0]
            open_prob = get_open_probability(user)
            opened = np.random.rand() < open_prob
            clicked = opened and (np.random.rand() < 0.3)

            reminders.append({
                "reminder_id" : reminder_id,
                "emi_id" : emi["emi_id"],
                "user_id" : user_id,
                "loan_id" : loan["loan_id"],
                "sent_time" : sent_time,
                "is_opened" : opened,
                "clicked_pay" : clicked,
                "channel" : "push"
            })

            reminder_id += 1

    reminders_df = pd.DataFrame(reminders)
    return reminders_df

# ------------------------------------------------------------
# TABLE 6 - APP EVENTS
# ------------------------------------------------------------

def generate_app_events(payments_df):

    events = []
    event_id = 1

    # Group by EMI (represents one repayment journey) and generate events in sequence
    for emi_id, group in payments_df.groupby("emi_id"):

        user_id = group["user_id"].iloc[0]
        base_time = group["payment_submission_time"].min()

        # Final attempt status determines success or failure event
        final_status = group.iloc[-1]["payment_status"]

        # Step 1 - Login
        if np.random.rand() < 0.9:  # 90% chance user logged in before payment attempt
            events.append({
                "event_id" : event_id,
                "user_id" : user_id,
                "emi_id" : emi_id,
                "event_name" : "login",
                "event_time" : base_time - timedelta(minutes = 5),
            })
            event_id += 1

        # Step 2 - View EMI details
        if np.random.rand() < 0.8:  # 80% chance user viewed EMI details
            events.append({
                "event_id": event_id,
                "user_id": user_id,
                "emi_id": emi_id,
                "event_name": "view_emi_details",
                "event_time": base_time
            })
            event_id += 1

        # Step 3 - Click pay
        click = np.random.rand() < 0.7  # 70% chance user clicked pay after viewing details
            
        if final_status == "success":
                click = True  # If payment was successful, user must have clicked pay

        if click:    
            events.append({
                "event_id": event_id,
                "user_id": user_id,
                "emi_id": emi_id,
                "event_name": "click_pay",
                "event_time": base_time
            })
            event_id += 1

            # Step 4 - Success / failure (depends on click)
            events.append({
                "event_id": event_id,
                "user_id": user_id,
                "emi_id": emi_id,
                "event_name": "payment_success" if final_status == "success" else "payment_failed",
                "event_time": group.iloc[-1]["payment_confirmation_time"]
            })
            event_id += 1

    events_df = pd.DataFrame(events)
    return events_df

# ------------------------------------------------------------
# EXPORT CSV FILES
# ------------------------------------------------------------

def export_tables(users_df, loans_df, emis_df, payments_df, reminders_df, events_df):

    users_df.to_csv("users.csv", index = False)
    loans_df.to_csv("loans.csv", index = False)
    emis_df.to_csv("emis.csv", index = False)
    payments_df.to_csv("payments.csv", index = False)
    reminders_df.to_csv("reminders.csv", index = False)
    events_df.to_csv("app_events.csv", index = False)

# ------------------------------------------------------------
# MAIN PIPELINE
# ------------------------------------------------------------

def main():

    print("Generating users...")
    users_df = generate_users()

    print("Generating loans...")
    loans_df = generate_loans(users_df)

    print("Generating EMI schedule...")
    emis_df = generate_emi_schedule(loans_df)

    print("Generating payments...")
    payments_df = generate_payments(emis_df, users_df, loans_df)

    print("Generating reminders...")
    reminders_df = generate_reminders(emis_df, users_df, loans_df)

    print("Generating app events...")
    events_df = generate_app_events(payments_df)

    print("Exporting tables to CSV...")
    export_tables(users_df, loans_df, emis_df, payments_df, reminders_df, events_df)

    print("Data generation completed!")

# ------------------------------------------------------------

if __name__ == "__main__":
    main()