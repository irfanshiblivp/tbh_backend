import os
import sys
import django
from django.conf import settings

# Set up Django environment
sys.path.append('c:\\Users\\Dell\\Documents\\App\\mobile app\\backend')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from app_api.hashers import LaravelBCryptHasher, LegacyLaravelBCryptHasher

def test_hashers():
    hasher = LaravelBCryptHasher()
    legacy_hasher = LegacyLaravelBCryptHasher()
    password = "testpassword123"
    
    print("--- Testing LaravelBCryptHasher (Raw) ---")
    encoded = hasher.encode(password, None)
    print(f"Encoded: {encoded}")
    print(f"Starts with $2y$: {encoded.startswith('$2y$')}")
    print(f"Length: {len(encoded)}")
    
    verified = hasher.verify(password, encoded)
    print(f"Verified: {verified}")
    
    print("\n--- Testing Legacy (Prefixed) ---")
    legacy_encoded = f"bcrypt_laravel${encoded}"
    print(f"Legacy Encoded: {legacy_encoded}")
    legacy_verified = legacy_hasher.verify(password, legacy_encoded)
    print(f"Legacy Verified: {legacy_verified}")
    
    print("\n--- Testing Identification ---")
    from django.contrib.auth.hashers import identify_hasher
    
    try:
        identified = identify_hasher(encoded)
        print(f"Identify raw hash: {identified.__class__.__name__} (algorithm='{identified.algorithm}')")
    except Exception as e:
        print(f"Identify raw hash failed: {e}")
        
    try:
        identified_legacy = identify_hasher(legacy_encoded)
        print(f"Identify legacy hash: {identified_legacy.__class__.__name__} (algorithm='{identified_legacy.algorithm}')")
    except Exception as e:
        print(f"Identify legacy hash failed: {e}")

if __name__ == "__main__":
    test_hashers()
