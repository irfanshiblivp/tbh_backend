import os, django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from django.db import connection

cursor = connection.cursor()

# Check if column exists
cursor.execute("SHOW COLUMNS FROM users LIKE 'state'")
result = cursor.fetchall()

if result:
    print("'state' column already exists in users table.")
else:
    cursor.execute("ALTER TABLE users ADD COLUMN state VARCHAR(255) NULL DEFAULT NULL")
    print("Added 'state' column to users table.")

# Also check customer_number
cursor.execute("SHOW COLUMNS FROM users LIKE 'customer_number'")
result2 = cursor.fetchall()

if result2:
    print("'customer_number' column already exists in users table.")
else:
    cursor.execute("ALTER TABLE users ADD COLUMN customer_number INT NULL DEFAULT NULL")
    print("Added 'customer_number' column to users table.")

print("Done!")
