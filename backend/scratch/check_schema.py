import os
import django
import sys
from django.db import connection

# Add current directory to path
sys.path.append(os.getcwd())

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

with connection.cursor() as cursor:
    cursor.execute("DESCRIBE users")
    columns = cursor.fetchall()
    for col in columns:
        print(col)
