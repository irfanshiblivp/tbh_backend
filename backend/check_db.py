import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from django.db import connection

with connection.cursor() as cursor:
    cursor.execute("SHOW CREATE TABLE users")
    row = cursor.fetchone()
    print("CREATE TABLE:")
    print(row[1])
