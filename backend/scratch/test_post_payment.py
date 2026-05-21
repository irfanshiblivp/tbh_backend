import os
import sys
import django

sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from django.conf import settings
from django.contrib.auth import get_user_model
from app_api.models import Payment
import razorpay

User = get_user_model()
user = User.objects.filter(role='customer').first()
if not user:
    user = User.objects.first()

print("Using user:", user.email)

try:
    amount = 500.0
    paise_amount = int(amount * 100)
    
    # Let's create Razorpay order first
    client = razorpay.Client(auth=(settings.RAZORPAY_KEY, settings.RAZORPAY_SECRET))
    razorpay_order = client.order.create({
        'amount': paise_amount,
        'currency': 'INR',
        'payment_capture': 1
    })
    print("Created order:", razorpay_order['id'])
    
    # Save a pending payment in our database
    payment = Payment.objects.create(
        user=user,
        razorpay_order_id=razorpay_order['id'],
        amount=paise_amount,
        status='pending',
        purpose='prime_membership'
    )
    print("SUCCESS creating payment object in database! ID:", payment.id)
except Exception as e:
    import traceback
    print("ERROR:")
    traceback.print_exc()
