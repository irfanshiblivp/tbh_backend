import razorpay
from django.conf import settings

client = razorpay.Client(auth=(getattr(settings, 'RAZORPAY_KEY_ID', 'rzp_test_default'), getattr(settings, 'RAZORPAY_KEY_SECRET', 'secret_default')))

class RazorpayService:
    @staticmethod
    def create_order(amount, currency='INR'):
        data = {
            'amount': int(amount * 100), # Razorpay expects amount in paise
            'currency': currency,
            'payment_capture': '1'
        }
        order = client.order.create(data=data)
        return order

    @staticmethod
    def verify_payment(order_id, payment_id, signature):
        params_dict = {
            'razorpay_order_id': order_id,
            'razorpay_payment_id': payment_id,
            'razorpay_signature': signature
        }
        try:
            client.utility.verify_payment_signature(params_dict)
            return True
        except:
            return False
