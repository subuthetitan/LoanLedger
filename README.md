# LoanLedger — DBMS Lab Mini Project (BCS403)

Loan & Credit Management System. Flask + MySQL web application.

## What's inside

| File | Purpose |
|------|---------|
| `database_setup.sql` | Creates the `loanledger` database: 5 tables, sample data, 1 trigger, 2 views |
| `app.py` | Flask backend — REST API connecting frontend to MySQL |
| `templates/index.html` | Web frontend — tabs, CRUD forms, views, trigger demo |
| `DEMO_SCRIPT.md` | Step-by-step talking points for the Review-2 demo |

## One-time setup

1. Install MySQL Server and start it.
2. Install Python packages:
   ```
   pip install flask mysql-connector-python
   ```
3. Create the database (loads tables + sample data + trigger + views):
   ```
   mysql -u root -p < database_setup.sql
   ```
4. Open `app.py` and set your MySQL password in `DB_CONFIG` (line ~22).
   Default is `root` / `root`.

## Run

```
python app.py
```

Open **http://127.0.0.1:5000** in any browser (Chrome/Firefox).

## How it satisfies the Review-2 guidelines

1. **5 entities** — customer, loan, emi_schedule, payment, collateral.
2. **5+ attributes each + keys** — every table has a PRIMARY KEY; loan, emi_schedule,
   payment and collateral have FOREIGN KEYs. Every table is related (no isolated table).
3. **5+ rows each** — sample data inserts 6 customers, 6 loans, 8 EMIs, 5 payments,
   6 collateral records.
4. **SQL commands** — the UI performs INSERT, UPDATE, DELETE, SELECT live; the SQL
   file also shows CREATE TABLE, ALTER-ready structure, CREATE VIEW, CREATE TRIGGER.
5. **Two-way sync** — front-end Add/Edit/Delete writes to MySQL; you can also run
   MySQL commands in MySQL Workbench and click any tab to see the change reflected
   (the UI always re-fetches with SELECT).
6. **Web-based, runs on laptop** — not a mobile app, so it is permitted.

## Relationships (for your schema/ER slide)

```
customer (1) ────< (M) loan
loan     (1) ────< (M) emi_schedule
loan     (1) ────< (M) collateral
emi_schedule (1) ─< (M) payment
loan     (1) ────< (M) payment
```
