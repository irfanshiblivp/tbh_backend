"""Run via: python manage.py shell < add_columns.py"""
from django.db import connection

cursor = connection.cursor()

# Check and add 'state' column
cursor.execute("SHOW COLUMNS FROM users LIKE 'state'")
if cursor.fetchall():
    print("'state' column already exists.")
else:
    cursor.execute("ALTER TABLE users ADD COLUMN state VARCHAR(255) NULL DEFAULT NULL")
    print("Added 'state' column to users table.")

# Check and add 'customer_number' column
cursor.execute("SHOW COLUMNS FROM users LIKE 'customer_number'")
if cursor.fetchall():
    print("'customer_number' column already exists.")
else:
    cursor.execute("ALTER TABLE users ADD COLUMN customer_number INT NULL DEFAULT NULL")
    print("Added 'customer_number' column to users table.")

print("Done!")
