-- Ejecutado únicamente al crear un volumen PostgreSQL nuevo.
SELECT 'CREATE DATABASE uct_campus_db' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'uct_campus_db')\gexec
SELECT 'CREATE DATABASE uct_identity_db' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'uct_identity_db')\gexec
SELECT 'CREATE DATABASE uct_schedule_db' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'uct_schedule_db')\gexec
