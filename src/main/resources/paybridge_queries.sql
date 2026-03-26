-- PayBridge business queries
-- This script contains example SQL queries for CRUD operations, searching,
-- joined reads, statistics, and top results based on the PayBridge domain.

-- =========================================================
-- 1. FULL CRUD FOR MAIN DOMAIN ENTITY: transactions
-- =========================================================

-- Create a raw message first because transactions depends on it.
INSERT INTO raw_messages (format, payload)
VALUES ('ISO8583', 'MTI=0200|DE2=4111111111111111|DE3=000000|DE4=000000010000|DE49=USD');

-- Create transaction
INSERT INTO transactions (raw_message_id, transaction_ref, amount, currency, status)
VALUES (1, 'TXN-1001', 100.00, 'USD', 'RECEIVED');

-- Read transaction by id
SELECT id, raw_message_id, transaction_ref, amount, currency, status, created_at
FROM transactions
WHERE id = 1;

-- Update transaction status
UPDATE transactions
SET status = 'SUCCESS'
WHERE id = 1;

-- Delete transaction by id
DELETE FROM transactions
WHERE id = 1;

-- =========================================================
-- 2. ADDITIONAL CREATE DATA FOR JOINED QUERIES
-- =========================================================

INSERT INTO transactions (raw_message_id, transaction_ref, amount, currency, status)
VALUES (1, 'TXN-1002', 250.00, 'USD', 'SUCCESS');

INSERT INTO transaction_details (transaction_id, mti, processing_code, response_code)
VALUES (2, '0200', '000000', '00');

INSERT INTO api_requests (transaction_id, endpoint, request_json)
VALUES (2, '/api/payments', '{"transactionRef":"TXN-1002","amount":250.00,"currency":"USD"}');

INSERT INTO api_responses (transaction_id, status_code, response_json)
VALUES (2, 200, '{"status":"SUCCESS","message":"Approved"}');

INSERT INTO tags (name)
VALUES ('priority'),
       ('international')
ON CONFLICT (name) DO NOTHING;

INSERT INTO transaction_tags (transaction_id, tag_id)
VALUES (2, 1),
       (2, 2)
ON CONFLICT (transaction_id, tag_id) DO NOTHING;

INSERT INTO logs (transaction_id, level, message)
VALUES (2, 'INFO', 'Transaction translated and sent to API.');

-- =========================================================
-- 3. SEARCH QUERY WITH DYNAMIC FILTERS, PAGINATION, SORTING
-- =========================================================

-- Example JDBC parameters:
-- :status
-- :currency
-- :min_amount
-- :max_amount
-- :from_date
-- :to_date
-- :sort_column
-- :sort_direction
-- :limit_value
-- :offset_value

SELECT id, transaction_ref, amount, currency, status, created_at
FROM transactions
WHERE (:status IS NULL OR status = :status)
  AND (:currency IS NULL OR currency = :currency)
  AND (:min_amount IS NULL OR amount >= :min_amount)
  AND (:max_amount IS NULL OR amount <= :max_amount)
  AND (:from_date IS NULL OR created_at >= :from_date)
  AND (:to_date IS NULL OR created_at <= :to_date)
ORDER BY created_at DESC
LIMIT :limit_value OFFSET :offset_value;

-- Note:
-- For real JDBC sorting, validate sort fields in Java and build only safe ORDER BY values.

-- =========================================================
-- 4. SEARCH QUERY WITH JOINED DATA
-- =========================================================

-- Fetch transaction details for a dashboard or details page.
SELECT t.id,
       t.transaction_ref,
       t.amount,
       t.currency,
       t.status,
       rm.format AS message_format,
       td.mti,
       td.processing_code,
       td.response_code,
       ar.endpoint,
       ap.status_code
FROM transactions t
JOIN raw_messages rm ON rm.id = t.raw_message_id
LEFT JOIN transaction_details td ON td.transaction_id = t.id
LEFT JOIN api_requests ar ON ar.transaction_id = t.id
LEFT JOIN api_responses ap ON ap.transaction_id = t.id
WHERE t.id = 2;

-- Fetch transactions with their tags.
SELECT t.id,
       t.transaction_ref,
       t.status,
       tg.name AS tag_name
FROM transactions t
LEFT JOIN transaction_tags tt ON tt.transaction_id = t.id
LEFT JOIN tags tg ON tg.id = tt.tag_id
ORDER BY t.id, tg.name;

-- =========================================================
-- 5. STATISTIC QUERIES
-- =========================================================

-- Count transactions by status.
SELECT status, COUNT(*) AS transaction_count
FROM transactions
GROUP BY status
ORDER BY transaction_count DESC;

-- Count logs written for each transaction.
SELECT transaction_id, COUNT(*) AS log_count
FROM logs
GROUP BY transaction_id
ORDER BY log_count DESC;

-- =========================================================
-- 6. TOP-SOMETHING QUERIES
-- =========================================================

-- Top transactions by amount.
SELECT id, transaction_ref, amount, currency, status
FROM transactions
ORDER BY amount DESC
LIMIT 5;

-- Top tags by number of assigned transactions.
SELECT tg.name, COUNT(tt.transaction_id) AS usage_count
FROM tags tg
LEFT JOIN transaction_tags tt ON tt.tag_id = tg.id
GROUP BY tg.id, tg.name
ORDER BY usage_count DESC, tg.name ASC
LIMIT 5;

-- =========================================================
-- 7. USE-CASE QUERIES FOR PURE JAVA / JDBC MODULE
-- =========================================================

-- Use case: save parser mapping rules.
INSERT INTO parser_mappings (message_format, source_field, target_property, target_type, required_flag, active_flag)
VALUES ('ISO8583', 'DE4', 'amount', 'BigDecimal', TRUE, TRUE);

-- Use case: get active parser mappings for a message format.
SELECT id, source_field, target_property, target_type, required_flag
FROM parser_mappings
WHERE message_format = 'ISO8583'
  AND active_flag = TRUE
ORDER BY id;

-- Use case: write processing log for a transaction.
INSERT INTO logs (transaction_id, level, message)
VALUES (2, 'INFO', 'Parser mappings loaded successfully.');

-- Use case: fetch transaction processing history.
SELECT id, level, message, created_at
FROM logs
WHERE transaction_id = 2
ORDER BY created_at ASC;

-- Use case: fetch API response for a transaction.
SELECT transaction_id, status_code, response_json, created_at
FROM api_responses
WHERE transaction_id = 2;

-- =========================================================
-- 8. ADDITIONAL QUERIES TO DISCUSS WITH MENTOR
-- =========================================================

-- Possible extra case: find failed transactions for retry.
SELECT id, transaction_ref, amount, currency, status
FROM transactions
WHERE status = 'FAILED'
ORDER BY created_at ASC;

-- Possible extra case: find transactions created today.
SELECT id, transaction_ref, amount, currency, status, created_at
FROM transactions
WHERE created_at::date = CURRENT_DATE
ORDER BY created_at DESC;
