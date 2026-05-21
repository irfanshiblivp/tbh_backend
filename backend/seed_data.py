import os
import django
import sys
import random
import string

# Setup django environment
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from app_api.models import User, Category, Merchant
from django.utils import timezone

def seed():
    print("Seeding database...")
    
    # Categories
    cats_data = [
        'Restaurants',
        'Hotels',
        'Fashion',
        'Jewellery',
        'Bar & Lounge',
        'Electronics',
        'Beauty & Spa',
    ]
    
    cat_objs = []
    for c_name in cats_data:
        obj, created = Category.objects.get_or_create(name=c_name)
        cat_objs.append(obj)
        if created:
            print(f"Created category: {c_name}")

    # Create Admin
    if not User.objects.filter(email='admin@thebaronclub.com').exists():
        User.objects.create_superuser(
            email='admin@thebaronclub.com', 
            password='password123', 
            name='Admin User',
            role='admin'
        )
        print("Created admin user: admin@thebaronclub.com / password123")

    # Merchants
    merchants_data = [
        { 'name':'Spice Garden', 'loc':'Fort Kochi, Ernakulam', 'cat':'Restaurants', 'disc':20,
          'img':'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=700&q=80&auto=format' },
        { 'name':'The Lalit Resort', 'loc':'Kovalam, Trivandrum', 'cat':'Hotels', 'disc':25,
          'img':'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=700&q=80&auto=format' },
        { 'name':'Kalyan Jewellers', 'loc':'MG Road, Kochi', 'cat':'Jewellery', 'disc':5,
          'img':'https://images.unsplash.com/photo-1515562141207-7a88fb7ce338?w=700&q=80&auto=format' },
        { 'name':'Fabindia Kerala', 'loc':'Palayam, Trivandrum', 'cat':'Fashion', 'disc':18,
          'img':'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?w=700&q=80&auto=format' },
        { 'name':'Serene Spa & Wellness', 'loc':'Calicut Beach Road', 'cat':'Beauty & Spa', 'disc':30,
          'img':'https://images.unsplash.com/photo-1544161515-4ab6ce6db874?w=700&q=80&auto=format' },
    ]

    for m in merchants_data:
        m_email = m['name'].lower().replace(' ', '_') + "@merchant.com"
        if not User.objects.filter(email=m_email).exists():
            m_user = User.objects.create_user(
                email=m_email,
                password='password123', 
                name=m['name'],
                role='merchant'
            )
            Merchant.objects.create(
                user=m_user,
                business_name=m['name'],
                category=m['cat'],
                address=m['loc'],
                discount_percent=m['disc'],
                card_image=m['img'],
                status='active'
            )
            print(f"Created merchant: {m['name']}")

    # Create demo customer
    cust_email = 'customer@thebaronclub.com'
    if not User.objects.filter(email=cust_email).exists():
        User.objects.create_user(
            email=cust_email, 
            password='password123', 
            name='Irfan Customer', 
            role='customer'
        )
        print(f"Created customer user: {cust_email} / password123")

    print("Seeding complete.")

if __name__ == '__main__':
    seed()

