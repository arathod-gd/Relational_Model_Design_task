# PayBridge-D

PayBridge-D is a plain Java and JDBC project that models a payment gateway bridge for translating legacy bank messages into modern JSON-based API calls.

## Tech Stack

- Java 17
- Maven
- PostgreSQL 16
- Docker Compose

## Current Scope

The project currently includes:
- a PostgreSQL schema in `src/main/resources/paybridge.sql`
- an ER diagram in `src/main/java/org/databaseiep/er_diagram/er.mmd`
- Docker setup for Java app + PostgreSQL

The database design includes:
- one-to-one relationship
- one-to-many relationship
- many-to-many relationship

## Run With Docker

```bash
docker compose up --build -d
```

PostgreSQL is exposed on:

```bash
localhost:5433
```

To recreate the database from the SQL script:

```bash
docker compose down -v
docker compose up --build -d
```

## Verify Database

```bash
docker exec -it paybridge-d-db-1 psql -U user -d postgres
```

Inside `psql`:

```sql
\dt
```

## Status

Completed:
- schema design
- ER diagram
- SQL creation script
- Docker Compose database initialization
- persistent Docker volume setup

Not implemented yet:
- JDBC connection logic
- parser implementation
- JSON request generation
- automated tests


## ER Diagram


<img width="1030" height="774" alt="Screenshot 2026-03-26 at 12 53 53 PM" src="https://github.com/user-attachments/assets/1d32628e-38a7-405a-8353-60e7d9513a07" />
