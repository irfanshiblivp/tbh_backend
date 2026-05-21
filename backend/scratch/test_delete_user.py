import os
import sys
import django

# Set up Django environment
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from django.db import transaction
from app_api.models import User

def test_delete():
    # Find a customer user
    user = User.objects.filter(role='customer').first()
    if not user:
        print("No customer user found to test deletion")
        return
        
    print(f"Attempting dry-run deletion of user: {user.id} ({user.email})")
    try:
        with transaction.atomic():
            user.delete()
            print("Deletion successful (dry-run succeeded!)")
            transaction.set_rollback(True)  # Roll back so we don't actually delete
    except Exception as e:
        import traceback
        print("Deletion failed with exception:")
        traceback.print_exc()

test_delete()
