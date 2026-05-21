import os
import sys
import django

sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from django.conf import settings
import razorpay

print("RAZORPAY_KEY:", settings.RAZORPAY_KEY)
print("RAZORPAY_SECRET:", settings.RAZORPAY_SECRET)

try:
    client = razorpay.Client(auth=(settings.RAZORPAY_KEY, settings.RAZORPAY_SECRET))
    order = client.order.create({
        'amount': 50000, # 500 INR
        'currency': 'INR',
        'payment_capture': 1
    })
    print("SUCCESS! Order ID:", order['id'])
except Exception as e:
    import traceback
    print("ERROR:")
    traceback.print_exc()
