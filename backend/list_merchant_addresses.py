import os
import sys
import django

sys.path.insert(0, r'c:\Users\Dell\Documents\App\mobile app\backend')

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from app_api.models import Merchant

for m in Merchant.objects.all():
    print(f"ID: {m.id} | Business: {m.business_name} | Address: {m.address}")
