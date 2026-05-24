-- ============================================================
-- LoanLedger: Loan & Credit Management System
-- DBMS Lab Mini Project (BCS403) - Review 2
-- ============================================================
-- Run this file once to create the full database:
--   mysql -u root -p < database_setup.sql
-- ============================================================

DROP DATABASE IF EXISTS loanledger;
CREATE DATABASE loanledger;
USE loanledger;

-- ============================================================
-- TABLE 1: CUSTOMER  (5 attributes)
-- Stores borrower / customer registration details
-- ============================================================
CREATE TABLE customer (
    customer_id    INT AUTO_INCREMENT PRIMARY KEY,
    name           VARCHAR(60)  NOT NULL,
    phone          VARCHAR(15)  NOT NULL,
    city           VARCHAR(40)  NOT NULL,
    credit_score   INT          NOT NULL DEFAULT 650
);

-- ============================================================
-- TABLE 2: LOAN  (6 attributes)
-- Each loan belongs to one customer  (customer 1 --- M loan)
-- ============================================================
CREATE TABLE loan (
    loan_id        INT AUTO_INCREMENT PRIMARY KEY,
    customer_id    INT          NOT NULL,
    loan_amount    DECIMAL(12,2) NOT NULL,
    interest_rate  DECIMAL(5,2)  NOT NULL,
    tenure_months  INT          NOT NULL,
    status         VARCHAR(20)  NOT NULL DEFAULT 'ACTIVE',
    FOREIGN KEY (customer_id) REFERENCES customer(customer_id)
);

-- ============================================================
-- TABLE 3: EMI_SCHEDULE  (6 attributes)
-- One row per monthly installment of a loan  (loan 1 --- M emi)
-- ============================================================
CREATE TABLE emi_schedule (
    emi_id         INT AUTO_INCREMENT PRIMARY KEY,
    loan_id        INT          NOT NULL,
    installment_no INT          NOT NULL,
    due_date       DATE         NOT NULL,
    emi_amount     DECIMAL(10,2) NOT NULL,
    emi_status     VARCHAR(15)  NOT NULL DEFAULT 'PENDING',
    FOREIGN KEY (loan_id) REFERENCES loan(loan_id)
);

-- ============================================================
-- TABLE 4: PAYMENT  (6 attributes)
-- Records an actual repayment against an EMI  (emi 1 --- M payment)
-- ============================================================
CREATE TABLE payment (
    payment_id     INT AUTO_INCREMENT PRIMARY KEY,
    emi_id         INT          NOT NULL,
    loan_id        INT          NOT NULL,
    payment_date   DATE         NOT NULL,
    amount_paid    DECIMAL(10,2) NOT NULL,
    payment_mode   VARCHAR(20)  NOT NULL,
    FOREIGN KEY (emi_id)  REFERENCES emi_schedule(emi_id),
    FOREIGN KEY (loan_id) REFERENCES loan(loan_id)
);

-- ============================================================
-- TABLE 5: COLLATERAL  (6 attributes)
-- Asset pledged against a loan  (loan 1 --- M collateral)
-- ============================================================
CREATE TABLE collateral (
    collateral_id  INT AUTO_INCREMENT PRIMARY KEY,
    loan_id        INT          NOT NULL,
    asset_type     VARCHAR(40)  NOT NULL,
    description    VARCHAR(100) NOT NULL,
    est_value      DECIMAL(12,2) NOT NULL,
    ownership      VARCHAR(40)  NOT NULL,
    FOREIGN KEY (loan_id) REFERENCES loan(loan_id)
);

-- ============================================================
-- SAMPLE DATA  (>= 5 rows each)
-- ============================================================

-- ---- CUSTOMER ----
INSERT INTO customer (name, phone, city, credit_score) VALUES
('Anita Sharma',   '9876500011', 'Bengaluru', 720),
('Ravi Kumar',     '9876500022', 'Mysuru',    680),
('Sneha Patil',    '9876500033', 'Hubli',     750),
('Manoj Verma',    '9876500044', 'Tumkur',    610),
('Divya Nair',     '9876500055', 'Mangaluru', 700),
('Arjun Reddy',    '9876500066', 'Bengaluru', 640);

-- ---- LOAN ----
INSERT INTO loan (customer_id, loan_amount, interest_rate, tenure_months, status) VALUES
(1, 200000.00, 10.50, 12, 'ACTIVE'),
(2, 150000.00, 12.00, 12, 'ACTIVE'),
(3, 500000.00,  9.75, 24, 'ACTIVE'),
(4,  80000.00, 14.00,  6, 'ACTIVE'),
(5, 300000.00, 11.25, 18, 'ACTIVE'),
(6, 120000.00, 13.50, 12, 'CLOSED');

-- ---- EMI_SCHEDULE ----
INSERT INTO emi_schedule (loan_id, installment_no, due_date, emi_amount, emi_status) VALUES
(1, 1, '2025-12-05', 17600.00, 'PAID'),
(1, 2, '2026-01-05', 17600.00, 'PAID'),
(1, 3, '2026-02-05', 17600.00, 'PENDING'),
(2, 1, '2025-12-10', 13312.00, 'PAID'),
(2, 2, '2026-01-10', 13312.00, 'PENDING'),
(3, 1, '2026-01-15', 22980.00, 'PENDING'),
(4, 1, '2025-11-20', 13880.00, 'PENDING'),
(5, 1, '2026-01-25', 18300.00, 'PENDING');

-- ---- PAYMENT ----
INSERT INTO payment (emi_id, loan_id, payment_date, amount_paid, payment_mode) VALUES
(1, 1, '2025-12-04', 17600.00, 'UPI'),
(2, 1, '2026-01-03', 17600.00, 'NET_BANKING'),
(4, 2, '2025-12-09', 13312.00, 'UPI'),
(1, 1, '2025-12-04', 17600.00, 'CASH'),
(2, 1, '2026-01-03', 17600.00, 'CARD');

-- ---- COLLATERAL ----
INSERT INTO collateral (loan_id, asset_type, description, est_value, ownership) VALUES
(1, 'Gold',     '50g gold ornaments',          280000.00, 'Self'),
(2, 'Vehicle',  'Two-wheeler - Honda Activa',   95000.00,  'Self'),
(3, 'Property', 'Residential plot 1200 sqft',   900000.00, 'Joint'),
(4, 'Gold',     '20g gold coins',               110000.00, 'Self'),
(5, 'Property', 'Agricultural land 1 acre',     600000.00, 'Self'),
(6, 'Vehicle',  'Car - Maruti Swift',           450000.00, 'Self');

-- ============================================================
-- TRIGGER: auto-flag overdue EMIs + reduce credit score
-- Fires BEFORE UPDATE on emi_schedule.
-- If an EMI is still PENDING and its due_date has passed,
-- it is marked OVERDUE and the customer's credit score drops by 20.
-- ============================================================
DELIMITER //
CREATE TRIGGER trg_overdue_flag
BEFORE UPDATE ON emi_schedule
FOR EACH ROW
BEGIN
    IF NEW.emi_status = 'PENDING' AND NEW.due_date < CURDATE() THEN
        SET NEW.emi_status = 'OVERDUE';
        UPDATE customer
        SET credit_score = GREATEST(credit_score - 20, 300)
        WHERE customer_id = (SELECT customer_id FROM loan WHERE loan_id = NEW.loan_id);
    END IF;
END;
//
DELIMITER ;

-- ============================================================
-- VIEW 1: LOAN SUMMARY
-- Combines customer + loan info for a quick portfolio overview
-- ============================================================
CREATE VIEW v_loan_summary AS
SELECT  l.loan_id,
        c.name           AS customer_name,
        c.city,
        c.credit_score,
        l.loan_amount,
        l.interest_rate,
        l.tenure_months,
        l.status
FROM loan l
JOIN customer c ON l.customer_id = c.customer_id;

-- ============================================================
-- VIEW 2: REPAYMENT ANALYTICS
-- Per-loan repayment progress: total paid vs loan amount
-- ============================================================
CREATE VIEW v_repayment_analytics AS
SELECT  l.loan_id,
        c.name                       AS customer_name,
        l.loan_amount,
        IFNULL(SUM(p.amount_paid),0) AS total_paid,
        COUNT(p.payment_id)          AS payments_made,
        (l.loan_amount - IFNULL(SUM(p.amount_paid),0)) AS balance
FROM loan l
JOIN customer c ON l.customer_id = c.customer_id
LEFT JOIN payment p ON l.loan_id = p.loan_id
GROUP BY l.loan_id, c.name, l.loan_amount;

-- ============================================================
-- DEMO QUERIES  (run these live during Review 2)
-- ============================================================
-- SELECT * FROM v_loan_summary;
-- SELECT * FROM v_repayment_analytics;
-- UPDATE emi_schedule SET emi_status='PENDING' WHERE emi_id=7;  -- trigger fires -> OVERDUE
-- SELECT * FROM emi_schedule WHERE emi_id=7;
-- SELECT name, credit_score FROM customer WHERE customer_id=4;
