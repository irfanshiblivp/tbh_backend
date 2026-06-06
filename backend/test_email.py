import os
import django
import sys

# Set up Django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from django.core.mail import send_mail
from django.conf import settings

print("Testing SMTP connection to:", settings.EMAIL_HOST, "on port:", settings.EMAIL_PORT)
try:
    send_mail(
        'Test SMTP - The Baron Club',
        'This is a test email to verify SMTP configuration.',
        settings.DEFAULT_FROM_EMAIL,
        ['info@thebaronclub.com'],  # send to self
        fail_silently=False,
    )
    print("SUCCESS: Email sent successfully!")
except Exception as e:
    print("ERROR: Failed to send email.")
    import traceback
    traceback.print_exc()
