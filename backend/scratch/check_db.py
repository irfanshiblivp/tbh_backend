import os
import sys
import django

# Set up Django environment
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from django.db import connection

def check_table(table_name):
    print(f"\n--- Columns in '{table_name}' ---")
    try:
        with connection.cursor() as cursor:
            cursor.execute(f"SHOW COLUMNS FROM {table_name}")
            columns = cursor.fetchall()
            for col in columns:
                print(f"  Field: {col[0]}, Type: {col[1]}, Null: {col[2]}, Key: {col[3]}, Default: {col[4]}")
    except Exception as e:
        print(f"Error checking {table_name}: {e}")

check_table("referral_payouts")
check_table("payments")
check_table("users")
