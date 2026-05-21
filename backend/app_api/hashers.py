from django.contrib.auth.hashers import BasePasswordHasher
import bcrypt

class LaravelBCryptHasher(BasePasswordHasher):
    """
    Handles raw Laravel/Bcrypt hashes (e.g., $2y$10$...).
    Django identifies this hasher when the password starts with $ (algorithm is empty).
    """
    algorithm = "laravel_raw"

    def verify(self, password, encoded):
        # We might get raw $2y$ or $2b$ or $2a$
        if not encoded.startswith('$'):
            return False
            
        # Standardize for python-bcrypt
        verify_hash = encoded
        if encoded.startswith('$2y$'):
            verify_hash = '$2b$' + encoded[4:]
            
        try:
            return bcrypt.checkpw(password.encode('utf-8'), verify_hash.encode('utf-8'))
        except Exception:
            return False

    def encode(self, password, salt):
        # Save in RAW format that Laravel understands
        # We ignore the salt parameter as Bcrypt generates its own
        hashed = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt(10))
        hash_str = hashed.decode('utf-8')
        # Use $2y$ for maximum Laravel compatibility
        if hash_str.startswith('$2b$'):
            hash_str = '$2y$' + hash_str[4:]
        elif hash_str.startswith('$2a$'):
            hash_str = '$2y$' + hash_str[4:]
        return hash_str

    def safe_summary(self, encoded):
        return {
            'algorithm': 'laravel_raw',
            'hash': encoded,
        }

    def must_update(self, encoded):
        # If it doesn't start with $ or uses a prefix we want to phase out, update it.
        # But if it's already a raw $2y$ or $2b$ hash, it's fine.
        if encoded.startswith('$'):
            return False
        return True

class LegacyLaravelBCryptHasher(BasePasswordHasher):
    """
    Handles the older Django-prefixed hashes (bcrypt_laravel$...).
    This allows existing users to log in while their hashes are migrated.
    """
    algorithm = "bcrypt_laravel"

    def verify(self, password, encoded):
        if encoded.startswith(f"{self.algorithm}$"):
            encoded = encoded.split('$', 1)[1]
            # It might have a double $ if it was bcrypt_laravel$$...
            if encoded.startswith('$'):
                pass
            else:
                # If it's not starting with $, it's invalid for us
                return False
        
        # Now use the logic from the raw hasher
        raw_hasher = LaravelBCryptHasher()
        return raw_hasher.verify(password, encoded)

    def safe_summary(self, encoded):
        return {
            'algorithm': self.algorithm,
            'hash': encoded,
        }

    def must_update(self, encoded):
        # Always update legacy hashes to the new raw format
        return True
