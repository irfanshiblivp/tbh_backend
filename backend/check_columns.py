import sys
from django.db import connection
cursor = connection.cursor()
cursor.execute("SHOW COLUMNS FROM users")
columns = cursor.fetchall()
for col in columns:
    sys.stdout.write(col[0] + "\n")
sys.stdout.flush()
