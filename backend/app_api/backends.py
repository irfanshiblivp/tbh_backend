from django.contrib.auth.backends import ModelBackend
from django.contrib.auth import get_user_model
import bcrypt

class LaravelAuthBackend(ModelBackend):
    """
    Custom authentication backend to handle Laravel's $2y$ hashes
    that don't follow Django's algorithm$hash format.
    """
    def authenticate(self, request, username=None, password=None, **kwargs):
        print(f"DEBUG: LaravelAuthBackend.authenticate called for {username}")
        UserModel = get_user_model()
        if username is None:
            username = kwargs.get(UserModel.USERNAME_FIELD)
            
        try:
            # Case-insensitive lookup
            user = UserModel.objects.get(**{f"{UserModel.USERNAME_FIELD}__iexact": username})
        except UserModel.DoesNotExist:
            return None
        except Exception:
            return None

        # Check if it's a Laravel hash
        if user.password.startswith('$2y$') or user.password.startswith('$2b$') or user.password.startswith('$2a$'):
            verify_hash = user.password
            if user.password.startswith('$2y$'):
                print(f"DEBUG: Laravel $2y$ hash detected for {user.email}")
                verify_hash = '$2b$' + user.password[4:]
            elif user.password.startswith('$2a$'):
                print(f"DEBUG: Laravel $2a$ hash detected for {user.email}")
                verify_hash = '$2b$' + user.password[4:]
                
            try:
                match = bcrypt.checkpw(password.encode('utf-8'), verify_hash.encode('utf-8'))
                print(f"DEBUG: Manual bcrypt match in backend: {match}")
                if match:
                    return user
            except Exception as e:
                print(f"DEBUG: Manual bcrypt error in backend: {e}")
                pass
                
        # Fallback to standard Django authentication (uses PASSWORD_HASHERS)
        print(f"DEBUG: Falling back to standard check_password for {user.email}")
        if user.check_password(password):
            print(f"DEBUG: check_password MATCH for {user.email}")
            return user
            
        print(f"DEBUG: Authentication FAILED for {user.email}")
        return None
