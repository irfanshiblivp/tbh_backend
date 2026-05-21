import os
import sys
import django

sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from django.db import connection

with connection.cursor() as cursor:
    cursor.execute("SELECT id, business_name, logo, card_image FROM merchant_profiles LIMIT 10")
    merchants = cursor.fetchall()
    for m in merchants:
        print(f"ID: {m[0]}, Name: {m[1]}, Logo: '{m[2]}', CardImage: '{m[3]}'")
