import bcrypt

def verify_laravel(password, encoded):
    print(f"Verifying password for hash: {encoded}")
    if encoded.startswith('$2y$'):
        verify_hash = '$2b$' + encoded[4:]
    else:
        verify_hash = encoded
    
    print(f"Standardized hash for bcrypt lib: {verify_hash}")
    try:
        result = bcrypt.checkpw(password.encode('utf-8'), verify_hash.encode('utf-8'))
        print(f"Verification result: {result}")
        return result
    except Exception as e:
        print(f"Error: {e}")
        return False

if __name__ == "__main__":
    # The user says they reset the password and still can't login.
    # If they reset it, it should be bcrypt_laravel$....
    
    # Let's test the Laravel format verification first
    # I don't know the password for info@thebaronclub.com, so I can't test it directly.
    
    # Let's test creating a hash and verifying it
    password = "password123"
    # Mimic Laravel hash (salt doesn't matter for this test)
    laravel_hash = "$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi" # Default Laravel 'password' hash
    verify_laravel("password", laravel_hash)
