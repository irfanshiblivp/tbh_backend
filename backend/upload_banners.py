"""
Script to upload local hero banner images to the production server via the API.
"""
import requests
import os

BASE_URL = 'https://api.thebaronclub.com/api'
LOCAL_BANNER_DIR = r'c:\Users\Dell\Documents\App\website\public_html\storage\hero-banners'

# Try to get admin token
credentials_to_try = [
    ('admin@thebaronclub.com', 'Baron@123'),
    ('admin@thebaronclub.com', 'admin123'),
    ('info@thebaronclub.com', 'Baron@123'),
]

token = None
for email, password in credentials_to_try:
    resp = requests.post(f'{BASE_URL}/auth/login/', json={'email': email, 'password': password}, timeout=15)
    print(f'Trying {email}: {resp.status_code}')
    if resp.status_code == 200:
        token = resp.json().get('access')
        print(f'SUCCESS! Logged in as {email}')
        break

if not token:
    print('Could not login. Please check credentials.')
    exit(1)

headers = {'Authorization': f'Bearer {token}'}

# Check existing banners on production
banners_resp = requests.get(f'{BASE_URL}/hero-banners/', headers=headers, timeout=15)
print(f'Existing banners: {banners_resp.status_code}')
if banners_resp.status_code == 200:
    print(banners_resp.json())

# Upload each banner image
for filename in os.listdir(LOCAL_BANNER_DIR):
    filepath = os.path.join(LOCAL_BANNER_DIR, filename)
    if not os.path.isfile(filepath):
        continue
    
    print(f'Uploading {filename}...')
    with open(filepath, 'rb') as f:
        mime = 'image/png' if filename.endswith('.png') else 'image/jpeg'
        resp = requests.post(
            f'{BASE_URL}/hero-banners/',
            headers=headers,
            files={'image': (filename, f, mime)},
            timeout=60
        )
    print(f'  Status: {resp.status_code}, Response: {resp.text[:200]}')
