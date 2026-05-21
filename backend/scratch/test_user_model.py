import os
import sys
import django
from django.conf import settings

# Set up Django environment
sys.path.append('c:\\Users\\Dell\\Documents\\App\\mobile app\\backend')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from app_api.models import User

def test_user_model_hashing():
    print("--- Testing User Model Overrides ---")
    user = User(email="test@example.com")
    password = "testpassword123"
    
    print(f"Setting password to: {password}")
    user.set_password(password)
    
    print(f"Stored password: {user.password}")
    print(f"Starts with $2y$: {user.password.startswith('$2y$')}")
    print(f"Length: {len(user.password)}")
    
    verified = user.check_password(password)
    print(f"Verified correctly: {verified}")
    
    wrong_password = "wrongpassword"
    verified_wrong = user.check_password(wrong_password)
    print(f"Verified wrong password correctly fails: {not verified_wrong}")
    
    print("\n--- Testing Legacy Prefix Verification ---")
    # Simulate an old legacy prefixed hash
    legacy_hash = "bcrypt_laravel$$2b$10$2rFwMF7hp2mS8awdP.uuRO1zkdZlKRMGjZMj87bx8gtMqYBCOfnuK"
    user.password = legacy_hash
    legacy_verified = user.check_password("testpassword123")
    print(f"Legacy Verified: {legacy_verified}")

if __name__ == "__main__":
    test_user_model_hashing()
