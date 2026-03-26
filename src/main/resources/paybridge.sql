-- PayBridge schema
-- This database supports a payment gateway bridge that reads legacy bank messages,
-- converts them into normalized transaction data, and tracks the generated JSON API flow.

-- Stores the original inbound ISO-8583 or flat-file bank message.
-- Purpose: keeps the unmodified source message so the system can parse, audit, or reprocess it later.
CREATE TABLE IF NOT EXISTS raw_messages (
                              id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                              format VARCHAR(100) NOT NULL,
                              payload TEXT NOT NULL,
                              created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Represents the normalized payment transaction created from a raw message.
-- Purpose: acts as the main business record after the incoming bank message is interpreted.
CREATE TABLE IF NOT EXISTS transactions (
                              id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                              raw_message_id BIGINT NOT NULL,
                              transaction_ref VARCHAR(255) NOT NULL UNIQUE,
                              amount DECIMAL(18, 2) NOT NULL,
                              currency VARCHAR(3) NOT NULL,
                              status VARCHAR(50) NOT NULL,
                              created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                              CONSTRAINT fk_transactions_raw_message
                                  FOREIGN KEY (raw_message_id) REFERENCES raw_messages(id)
);

-- Stores ISO-8583 specific details for a transaction.
-- Purpose: keeps protocol-level values separately so the main transaction table stays simple and readable.
CREATE TABLE IF NOT EXISTS transaction_details (
                                     id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                                     transaction_id BIGINT NOT NULL UNIQUE,
                                     mti VARCHAR(20) NOT NULL,
                                     processing_code VARCHAR(20),
                                     response_code VARCHAR(20),
                                     CONSTRAINT fk_transaction_details_transaction
                                         FOREIGN KEY (transaction_id) REFERENCES transactions(id)
);

-- Stores reusable parser rules that map source fields to Java object properties.
-- Purpose: supports reflection and generics by defining how source fields are mapped into Java objects.
CREATE TABLE IF NOT EXISTS parser_mappings (
                                 id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                                 message_format VARCHAR(100) NOT NULL,
                                 source_field VARCHAR(255) NOT NULL,
                                 target_property VARCHAR(255) NOT NULL,
                                 target_type VARCHAR(100) NOT NULL,
                                 required_flag BOOLEAN NOT NULL DEFAULT FALSE,
                                 active_flag BOOLEAN NOT NULL DEFAULT TRUE
);

-- Stores reusable labels that can be attached to transactions.
-- Purpose: classifies transactions for reporting, filtering, or business grouping.
CREATE TABLE IF NOT EXISTS tags (
                     id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                     name VARCHAR(100) NOT NULL UNIQUE
);

-- Bridge table for the many-to-many relationship between transactions and tags.
-- Purpose: allows one transaction to have many tags and one tag to belong to many transactions.
CREATE TABLE IF NOT EXISTS transaction_tags (
                                 transaction_id BIGINT NOT NULL,
                                 tag_id BIGINT NOT NULL,
                                 PRIMARY KEY (transaction_id, tag_id),
                                 CONSTRAINT fk_transaction_tags_transaction
                                     FOREIGN KEY (transaction_id) REFERENCES transactions(id),
                                 CONSTRAINT fk_transaction_tags_tag
                                     FOREIGN KEY (tag_id) REFERENCES tags(id)
);

-- Stores the JSON API request generated for a transaction.
-- Purpose: records the modern API payload created after translating the legacy bank message.
CREATE TABLE IF NOT EXISTS api_requests (
                              id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                              transaction_id BIGINT NOT NULL UNIQUE,
                              endpoint VARCHAR(255) NOT NULL,
                              request_json TEXT NOT NULL,
                              created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                              CONSTRAINT fk_api_requests_transaction
                                  FOREIGN KEY (transaction_id) REFERENCES transactions(id)
);

-- Stores the JSON API response returned for a transaction.
-- Purpose: keeps the external API result so the bridge can show whether processing succeeded or failed.
CREATE TABLE IF NOT EXISTS api_responses (
                               id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                               transaction_id BIGINT NOT NULL UNIQUE,
                               status_code INT NOT NULL,
                               response_json TEXT NOT NULL,
                               created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                               CONSTRAINT fk_api_responses_transaction
                                   FOREIGN KEY (transaction_id) REFERENCES transactions(id)
);

-- Stores processing or audit log entries for each transaction.
-- Purpose: helps track each processing step for debugging, monitoring, and project demonstration.
CREATE TABLE IF NOT EXISTS logs (
                      id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                      transaction_id BIGINT NOT NULL,
                      level VARCHAR(20) NOT NULL,
                      message VARCHAR(1000) NOT NULL,
                      created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                      CONSTRAINT fk_logs_transaction
                          FOREIGN KEY (transaction_id) REFERENCES transactions(id)
);

CREATE INDEX IF NOT EXISTS idx_transactions_raw_message_id
    ON transactions(raw_message_id);

CREATE INDEX IF NOT EXISTS idx_logs_transaction_id
    ON logs(transaction_id);

CREATE INDEX IF NOT EXISTS idx_parser_mappings_message_format
    ON parser_mappings(message_format);

CREATE INDEX IF NOT EXISTS idx_transaction_tags_tag_id
    ON transaction_tags(tag_id);
