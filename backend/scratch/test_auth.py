import os
import django
import sys

# Set up Django environment
sys.path.append(os.getcwd())
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from django.contrib.auth import authenticate
from app_api.models import User
from django.contrib.auth.hashers import make_password, check_password

def test_auth(email, password):
    print(f"Testing auth for {email}")
    try:
        user = User.objects.get(email=email)
        print(f"User found: {user.email}")
        print(f"Stored Hash: {user.password}")
        
        # Test direct verification
        is_correct = check_password(password, user.password)
        print(f"check_password result: {is_correct}")
        
        # Test authenticate
        auth_user = authenticate(username=email, password=password)
        print(f"authenticate result: {auth_user}")
        
    except User.DoesNotExist:
        print(f"User {email} not found")

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python test_auth.py <email> <password>")
    else:
        test_auth(sys.argv[1], sys.argv[2])
