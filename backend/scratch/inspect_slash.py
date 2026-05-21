import os
import sys
import django

sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from django.db import connection

with connection.cursor() as cursor:
    cursor.execute("SELECT id, business_name, logo, card_image FROM merchant_profiles")
    merchants = cursor.fetchall()
    for m in merchants:
        print(f"ID: {m[0]}, Name: {m[1]}")
        print(f"  Logo: {repr(m[2])}")
        print(f"  CardImage: {repr(m[3])}")
        if m[2] and '\\' in m[2]:
            print("  WARNING: Logo contains backslash!")
        if m[3] and '\\' in m[3]:
            print("  WARNING: CardImage contains backslash!")
