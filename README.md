# PayBridge-D

PayBridge-D is a plain Java and JDBC project for learning how a payment gateway bridge can translate legacy bank messages into modern JSON-based API requests.

The current project includes:
- a PostgreSQL schema in `src/main/resources/paybridge.sql`
- an ER diagram in `src/main/java/org/databaseiep/er_diagram/er.mmd`
- a simple Java entry point in `src/main/java/org/databaseiep/Main.java`
- Docker support to run the Java app and PostgreSQL together

## Tech Stack

- Java 17
- Maven
- PostgreSQL 16
- Docker Compose

## Project Structure

- `src/main/java/org/databaseiep/Main.java` : main Java class
- `src/main/resources/paybridge.sql` : database schema script
- `src/main/java/org/databaseiep/er_diagram/er.mmd` : ER diagram
- `.env` : database configuration
- `Dockerfile` : Java container setup
- `compose.yaml` : runs Java app and PostgreSQL together

## Database Tables

The schema currently contains these tables:
- `raw_messages`
- `transactions`
- `transaction_details`
- `parser_mappings`
- `tags`
- `transaction_tags`
- `api_requests`
- `api_responses`
- `logs`

## Prerequisites

Install these before running the project:
- Java 17
- Maven
- Docker Desktop

## Environment Variables

Current values from `.env`:

```env
POSTGRES_DB=postgres
POSTGRES_USER=user
POSTGRES_PASSWORD=password
POSTGRES_HOST=localhost
POSTGRES_PORT=5433
```

## Run With Docker

Build and start both Java and PostgreSQL containers:

```bash
docker compose up --build
```

Run in background:

```bash
docker compose up --build -d
```

Stop containers:

```bash
docker compose down
```

Stop containers and remove volumes:

```bash
docker compose down -v
```

Check running containers:

```bash
docker compose ps
```

View logs:

```bash
docker compose logs
```

View only database logs:

```bash
docker compose logs db
```

View only app logs:

```bash
docker compose logs app
```

## Run Without Docker

Build the project:

```bash
mvn clean package
```

Run the jar file:

```bash
java -jar target/PayBridge-D-1.0-SNAPSHOT.jar
```

Or run through Maven:

```bash
mvn exec:java -Dexec.mainClass="org.databaseiep.Main"
```

Note:
- the current `Main` class only prints `Application started...` and waits
- JDBC connection code is not added yet
- the `mvn exec:java` command needs the Maven exec plugin if you want to use it

## Database Verification Commands

Open PostgreSQL inside the running container:

```bash
docker exec -it paybridge-d-db-1 psql -U user -d postgres
```

List tables inside `psql`:

```sql
\dt
```

Describe one table:

```sql
\d transactions
```

Exit `psql`:

```sql
\q
```

Docker note:
- PostgreSQL runs scripts from `/docker-entrypoint-initdb.d/` only when the database directory is empty
- because this project uses a Docker volume, schema initialization normally happens only on the first startup
- to recreate the database from the SQL script, run `docker compose down -v` and then `docker compose up --build -d`

## Sample Data Example

You can insert one sample record flow manually for testing.

Open PostgreSQL:

```bash
docker exec -it paybridge-d-db-1 psql -U user -d postgres
```

Run these SQL commands one by one:

```sql
INSERT INTO raw_messages (format, payload)
VALUES ('ISO8583', 'MTI=0200|DE2=4111111111111111|DE3=000000|DE4=000000010000|DE49=USD');

INSERT INTO transactions (raw_message_id, transaction_ref, amount, currency, status)
VALUES (1, 'TXN-1001', 100.00, 'USD', 'SUCCESS');

INSERT INTO transaction_details (transaction_id, mti, processing_code, response_code)
VALUES (1, '0200', '000000', '00');

INSERT INTO parser_mappings (message_format, source_field, target_property, target_type, required_flag, active_flag)
VALUES ('ISO8583', 'DE4', 'amount', 'BigDecimal', TRUE, TRUE);

INSERT INTO tags (name)
VALUES ('priority');

INSERT INTO transaction_tags (transaction_id, tag_id)
VALUES (1, 1);

INSERT INTO api_requests (transaction_id, endpoint, request_json)
VALUES (1, '/api/payments', '{"transactionRef":"TXN-1001","amount":100.00,"currency":"USD"}');

INSERT INTO api_responses (transaction_id, status_code, response_json)
VALUES (1, 200, '{"status":"SUCCESS","message":"Payment processed"}');

INSERT INTO logs (transaction_id, level, message)
VALUES (1, 'INFO', 'Sample transaction processed successfully.');
```

Check the inserted rows:

```sql
SELECT * FROM raw_messages;
SELECT * FROM transactions;
SELECT * FROM transaction_details;
SELECT * FROM parser_mappings;
SELECT * FROM tags;
SELECT * FROM transaction_tags;
SELECT * FROM api_requests;
SELECT * FROM api_responses;
SELECT * FROM logs;
```

Check Docker mounts for the database container:

```bash
docker inspect paybridge-d-db-1 --format '{{json .Mounts}}'
```

List Docker volumes:

```bash
docker volume ls
```

## Useful Maven Commands

Clean the project:

```bash
mvn clean
```

Compile the project:

```bash
mvn compile
```

Package the project:

```bash
mvn package
```

Run tests:

```bash
mvn test
```

Current note:
- there are no test classes yet, so `mvn test` will not run useful tests until they are added

## Useful Docker Commands

Build only the app image:

```bash
docker compose build
```

Restart containers:

```bash
docker compose restart
```

Stop a single service:

```bash
docker compose stop db
```

Start a single service:

```bash
docker compose start db
```

Remove stopped containers:

```bash
docker compose rm
```

## Current Status

What is finished:
- ER diagram created
- SQL schema created
- Docker setup created
- PostgreSQL container verified
- schema execution verified
- persistent Docker volume verified

What is not implemented yet:
- JDBC database connection
- ISO-8583 parser
- reflection-based mapper
- JSON API request generation
- automated tests

## Next Suggested Steps

1. Add PostgreSQL JDBC dependency to `pom.xml`.
2. Create a `DBConnection` utility class.
3. Insert sample records into `raw_messages`.
4. Add DAO classes for the tables.
5. Start implementing the parser and mapping logic.
