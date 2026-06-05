import os
import sys
import django

sys.path.insert(0, r'c:\Users\Dell\Documents\App\mobile app\backend')

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from django.db import connection

with connection.cursor() as cursor:
    cursor.execute("SELECT id, name, email, phone, role FROM users WHERE phone = ''")
    rows = cursor.fetchall()
    print("Users with empty string phone number:")
    for row in rows:
        print(row)
        
    cursor.execute("SELECT id, name, email, phone, role FROM users WHERE phone IS NULL")
    rows = cursor.fetchall()
    print("\nUsers with NULL phone number (first 10):")
    for row in rows[:10]:
        print(row)
