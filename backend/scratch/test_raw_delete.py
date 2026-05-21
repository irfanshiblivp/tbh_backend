import os
import sys
import django

# Set up Django environment
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from django.db import transaction, connection
from app_api.models import User

def test_delete():
    user = User.objects.filter(role='customer').first()
    if not user:
        print("No customer user found to test deletion")
        return
        
    print(f"Attempting custom cascade + raw deletion of user: {user.id} ({user.email})")
    try:
        with transaction.atomic():
            user.memberships.all().delete()
            user.payments.all().delete()
            user.vouchers.all().delete()
            user.referral_links.all().delete()
            user.referrals_made.all().delete()
            if hasattr(user, 'referred_by_record'):
                user.referred_by_record.delete()
            user.payouts.all().delete()
            if hasattr(user, 'merchant_profile'):
                user.merchant_profile.delete()
                
            with connection.cursor() as cursor:
                cursor.execute("DELETE FROM users WHERE id = %s", [user.id])
                
            print("Custom deletion successful (dry-run succeeded!)")
            transaction.set_rollback(True)  # Roll back
    except Exception as e:
        import traceback
        print("Custom deletion failed with exception:")
        traceback.print_exc()

test_delete()
