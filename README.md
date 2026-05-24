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


