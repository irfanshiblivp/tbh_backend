import sys
import os
import django
import json

# Setup Django environment
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from django.core.mail import get_connection, EmailMultiAlternatives
from django.conf import settings

def main():
    try:
        # Read parameters from standard input
        params = json.loads(sys.stdin.read())
        to_email = params['to']
        subject = params['subject']
        text_content = params['text']
        html_message = params.get('html')
        
        # Try Port 465 (SSL) first
        try:
            print(f"SMTP Helper: Attempting to send email to {to_email} via Port 465 (SSL)...")
            connection = get_connection(
                host=settings.EMAIL_HOST,
                port=settings.EMAIL_PORT,
                username=settings.EMAIL_HOST_USER,
                password=settings.EMAIL_HOST_PASSWORD,
                use_ssl=settings.EMAIL_USE_SSL,
                use_tls=settings.EMAIL_USE_TLS,
                timeout=10,
            )
            email = EmailMultiAlternatives(
                subject, text_content, settings.DEFAULT_FROM_EMAIL, [to_email], connection=connection
            )
            if html_message:
                email.attach_alternative(html_message, "text/html")
            email.send()
            print("SMTP Helper: Email sent successfully via Port 465 (SSL).")
            return
        except Exception as e:
            print(f"SMTP Helper: Failed via Port 465 (SSL): {e}")

        # Fallback to Port 587 (TLS)
        try:
            print(f"SMTP Helper: Attempting fallback to Port 587 (TLS)...")
            connection = get_connection(
                host=settings.EMAIL_HOST,
                port=587,
                username=settings.EMAIL_HOST_USER,
                password=settings.EMAIL_HOST_PASSWORD,
                use_ssl=False,
                use_tls=True,
                timeout=15,
            )
            email = EmailMultiAlternatives(
                subject, text_content, settings.DEFAULT_FROM_EMAIL, [to_email], connection=connection
            )
            if html_message:
                email.attach_alternative(html_message, "text/html")
            email.send()
            print("SMTP Helper: Email sent successfully via Port 587 (TLS) fallback.")
        except Exception as e2:
            print(f"SMTP Helper: Fallback to Port 587 (TLS) also failed: {e2}")
    except Exception as e:
        print(f"SMTP Helper: General error in helper: {e}")

if __name__ == '__main__':
    main()
