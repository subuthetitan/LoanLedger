# Review-2 Demo Script — LoanLedger

Use this as your spoken walkthrough. ~6–8 minutes. Keep MySQL Workbench
open in one window and the web app in another so you can show two-way sync.

---

## 1. Introduce the project (30 sec)

"LoanLedger is a Loan & Credit Management System for banks and microfinance.
It manages the full loan lifecycle — customer registration, loan application,
EMI scheduling, repayment, collateral, and credit score tracking. Backend is
MySQL, the application layer is Python Flask, frontend is HTML/CSS/JavaScript."

## 2. Show the schema (1 min)

Open `database_setup.sql`. Point out:
- **5 tables / entities**: customer, loan, emi_schedule, payment, collateral.
- Each has a **PRIMARY KEY**; loan/emi_schedule/payment/collateral have
  **FOREIGN KEYs** — say which table each FK points to.
- "Every table is related — no isolated table." Trace:
  customer → loan → emi_schedule → payment, and loan → collateral.
- Each table has **5+ attributes** and **5+ rows** of sample data.

## 3. Show SELECT (30 sec)

In the web app, click through the 5 tabs (Customers, Loans, EMI Schedule,
Payments, Collateral). "Each tab runs a SELECT and shows live table data."

## 4. Demonstrate INSERT (1 min)

On the **Customers** tab, fill the form (name, phone, city, credit score),
click **Add row**. Row appears immediately.
"That was a SQL INSERT — committed to MySQL."
Switch to MySQL Workbench, run `SELECT * FROM customer;` — show the new row.
**This proves front-end → back-end sync.**

## 5. Demonstrate UPDATE (45 sec)

Click **Edit** on any customer, change the city, click **Save changes**.
"That's a SQL UPDATE."

## 6. Demonstrate DELETE (45 sec)

Add a throwaway row, then click **Delete** on it, confirm.
"That's a SQL DELETE." (Delete a row you added, not one with child records,
to avoid foreign-key errors.)

## 7. Demonstrate back-end → front-end sync (45 sec)

In MySQL Workbench run:
```sql
UPDATE customer SET city='Belagavi' WHERE customer_id=1;
```
Go back to the web app, click the Customers tab again — the change shows up.
"Changes made directly in MySQL also reflect in the front-end."

## 8. Demonstrate the TRIGGER (1.5 min)

Go to the **Trigger Demo** tab. Explain:
"`trg_overdue_flag` is a BEFORE UPDATE trigger. If an EMI is still PENDING and
its due date has passed, it auto-marks it OVERDUE and reduces that customer's
credit score by 20."

- First show EMI id 7: Customers tab → note Manoj Verma's credit score (610).
- Enter `7` in the Trigger Demo box, click **Run trigger on this EMI**.
- EMI 7's status flips to **OVERDUE**.
- Go to Customers tab → Manoj Verma's score is now **590**.
"The trigger fired automatically — no manual update of the score."

## 9. Show the VIEWS (1 min)

- **View: Loan Summary** — joins customer + loan into one portfolio view.
- **View: Repayment Analytics** — per loan: total paid, payments made, balance.
"Both are MySQL VIEWs created with CREATE VIEW — read-only, computed live."

## 10. Wrap up (15 sec)

"So LoanLedger demonstrates 5 related tables with keys, 5+ records each,
INSERT/UPDATE/DELETE/SELECT, a trigger for overdue detection, two views, and
full two-way front-end/back-end synchronization."

---

### Quick troubleshooting

- **App won't start** → check MySQL is running and the password in `app.py`
  `DB_CONFIG` is correct.
- **"unknown database loanledger"** → re-run `mysql -u root -p < database_setup.sql`.
- **FK constraint error on delete** → you tried to delete a parent row that has
  child rows; delete the child rows first, or delete a row with no children.
- **Trigger didn't flip status** → it only fires when due_date is in the past;
  EMI 7 is dated 2025-11-20 so it will work as long as today is after that.
