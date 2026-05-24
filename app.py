"""
LoanLedger - Flask backend
DBMS Lab Mini Project (BCS403)

Run:  python app.py
Then open http://127.0.0.1:5000 in a browser.

Requires:  pip install flask mysql-connector-python
"""

from flask import Flask, render_template, request, jsonify
import mysql.connector

app = Flask(__name__)

# ----------------------------------------------------------------
# DATABASE CONNECTION  --  edit user / password to match your MySQL
# ----------------------------------------------------------------
DB_CONFIG = {
    "host":     "localhost",
    "user":     "root",
    "password": "your_password_here",        # <-- change to your MySQL password
    "database": "loanledger",
}


def get_db():
    """Open a fresh connection per request (simple + safe for a demo)."""
    return mysql.connector.connect(**DB_CONFIG)


def run_query(sql, params=None, fetch=False):
    """Helper: run a query, optionally return rows as list of dicts."""
    conn = get_db()
    cur = conn.cursor(dictionary=True)
    cur.execute(sql, params or ())
    rows = cur.fetchall() if fetch else None
    if not fetch:
        conn.commit()
    last_id = cur.lastrowid
    cur.close()
    conn.close()
    return rows if fetch else last_id


# ----------------------------------------------------------------
# Table metadata: drives the generic frontend grid
# ----------------------------------------------------------------
TABLES = {
    "customer": {
        "pk": "customer_id",
        "cols": ["name", "phone", "city", "credit_score"],
    },
    "loan": {
        "pk": "loan_id",
        "cols": ["customer_id", "loan_amount", "interest_rate",
                 "tenure_months", "status"],
    },
    "emi_schedule": {
        "pk": "emi_id",
        "cols": ["loan_id", "installment_no", "due_date",
                 "emi_amount", "emi_status"],
    },
    "payment": {
        "pk": "payment_id",
        "cols": ["emi_id", "loan_id", "payment_date",
                 "amount_paid", "payment_mode"],
    },
    "collateral": {
        "pk": "collateral_id",
        "cols": ["loan_id", "asset_type", "description",
                 "est_value", "ownership"],
    },
}


@app.route("/")
def home():
    return render_template("index.html")


# ---- READ: list all rows of a table (SELECT) -------------------
@app.route("/api/<table>", methods=["GET"])
def list_rows(table):
    if table not in TABLES:
        return jsonify({"error": "unknown table"}), 404
    rows = run_query(f"SELECT * FROM {table}", fetch=True)
    return jsonify({"columns": [TABLES[table]["pk"]] + TABLES[table]["cols"],
                    "rows": rows})


# ---- CREATE: insert a row (INSERT) -----------------------------
@app.route("/api/<table>", methods=["POST"])
def create_row(table):
    if table not in TABLES:
        return jsonify({"error": "unknown table"}), 404
    cols = TABLES[table]["cols"]
    data = request.get_json()
    placeholders = ", ".join(["%s"] * len(cols))
    sql = f"INSERT INTO {table} ({', '.join(cols)}) VALUES ({placeholders})"
    try:
        new_id = run_query(sql, [data.get(c) for c in cols])
        return jsonify({"status": "inserted", "id": new_id})
    except mysql.connector.Error as e:
        return jsonify({"error": str(e)}), 400


# ---- UPDATE: edit a row (UPDATE) -------------------------------
@app.route("/api/<table>/<int:rid>", methods=["PUT"])
def update_row(table, rid):
    if table not in TABLES:
        return jsonify({"error": "unknown table"}), 404
    cols = TABLES[table]["cols"]
    pk = TABLES[table]["pk"]
    data = request.get_json()
    set_clause = ", ".join([f"{c}=%s" for c in cols])
    sql = f"UPDATE {table} SET {set_clause} WHERE {pk}=%s"
    try:
        run_query(sql, [data.get(c) for c in cols] + [rid])
        return jsonify({"status": "updated", "id": rid})
    except mysql.connector.Error as e:
        return jsonify({"error": str(e)}), 400


# ---- DELETE: remove a row (DELETE) -----------------------------
@app.route("/api/<table>/<int:rid>", methods=["DELETE"])
def delete_row(table, rid):
    if table not in TABLES:
        return jsonify({"error": "unknown table"}), 404
    pk = TABLES[table]["pk"]
    try:
        run_query(f"DELETE FROM {table} WHERE {pk}=%s", [rid])
        return jsonify({"status": "deleted", "id": rid})
    except mysql.connector.Error as e:
        return jsonify({"error": str(e)}), 400


# ---- VIEWS: loan summary + repayment analytics -----------------
@app.route("/api/view/<view_name>", methods=["GET"])
def get_view(view_name):
    allowed = {"v_loan_summary", "v_repayment_analytics"}
    if view_name not in allowed:
        return jsonify({"error": "unknown view"}), 404
    rows = run_query(f"SELECT * FROM {view_name}", fetch=True)
    cols = list(rows[0].keys()) if rows else []
    return jsonify({"columns": cols, "rows": rows})


# ---- TRIGGER demo: re-save a PENDING EMI so the trigger fires --
@app.route("/api/trigger-check/<int:emi_id>", methods=["POST"])
def trigger_check(emi_id):
    """
    Forces an UPDATE on an EMI. If the EMI is PENDING and past its
    due date, the BEFORE UPDATE trigger flips it to OVERDUE and
    lowers the customer's credit score automatically.
    """
    try:
        run_query("UPDATE emi_schedule SET emi_status='PENDING' "
                  "WHERE emi_id=%s AND emi_status='PENDING'", [emi_id])
        row = run_query("SELECT * FROM emi_schedule WHERE emi_id=%s",
                        [emi_id], fetch=True)
        return jsonify({"status": "trigger ran", "emi": row[0] if row else None})
    except mysql.connector.Error as e:
        return jsonify({"error": str(e)}), 400


if __name__ == "__main__":
    app.run(debug=True, port=5000)
