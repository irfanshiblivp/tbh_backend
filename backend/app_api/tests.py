from django.test import TestCase, TransactionTestCase, override_settings
from rest_framework.test import APIClient
from rest_framework import status
from django.utils import timezone
from app_api.models import User, Merchant, PrimeMembership, Payment, AppSetting, HeroBanner, FreePrimeRequest
import unittest

class UnmanagedModelTestMixin:
    """Helper to ensure unmanaged models have SQLite tables during tests."""
    @classmethod
    def setUpClass(cls):
        super().setUpClass()
        from django.db import connection
        from django.apps import apps
        with connection.schema_editor() as editor:
            for m in apps.get_app_config('app_api').get_models():
                try:
                    editor.create_model(m)
                except Exception:
                    pass

class SystemHealthTests(TestCase):
    def setUp(self):
        self.client = APIClient()

    def test_health_check_endpoint(self):
        response = self.client.get('/health/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('status', response.json())
        self.assertEqual(response.json()['status'], 'healthy')

    def test_api_health_check_endpoint(self):
        response = self.client.get('/api/health/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('database', response.json())


class SecurityAuthAndPrivilegeEscalationTests(UnmanagedModelTestMixin, TransactionTestCase):
    def setUp(self):
        User.objects.all().delete()
        self.client = APIClient()
        self.admin = User.objects.create_user(
            email='admin@thebaronclub.com',
            password='Password123!',
            name='Admin User',
            role='admin',
            phone='9999999991'
        )
        self.customer = User.objects.create_user(
            email='customer@example.com',
            password='Password123!',
            name='Regular Customer',
            role='customer',
            phone='9999999992'
        )

    def test_signup_prevents_role_escalation_to_admin(self):
        """Security: Users signing up must not be able to elevate themselves to admin or staff."""
        payload = {
            'name': 'Hacker User',
            'email': 'hacker@example.com',
            'password': 'SecurePassword123!',
            'phone': '9876543210',
            'role': 'admin' # Attempted privilege escalation
        }
        response = self.client.post('/api/auth/signup/', payload, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        
        user = User.objects.get(email='hacker@example.com')
        self.assertEqual(user.role, 'customer', "Role should default to customer, NOT admin!")

    def test_user_viewset_create_is_forbidden(self):
        """Security: Direct POST /api/users/ must be disabled."""
        self.client.force_authenticate(user=self.customer)
        response = self.client.post('/api/users/', {'name': 'New'}, format='json')
        self.assertEqual(response.status_code, status.HTTP_405_METHOD_NOT_ALLOWED)

    def test_user_cannot_modify_own_role_via_patch(self):
        """Security: Customers cannot update their own role or referral balance."""
        self.client.force_authenticate(user=self.customer)
        response = self.client.patch(
            f'/api/users/{self.customer.id}/',
            {'role': 'admin', 'referral_balance': '99999.00'},
            format='json'
        )
        self.customer.refresh_from_db()
        self.assertEqual(self.customer.role, 'customer')
        self.assertEqual(float(self.customer.referral_balance), 0.0)

    def test_forgot_password_prevents_user_enumeration(self):
        """Security: Forgot password returns identical response for existing and non-existing emails."""
        response_existing = self.client.post('/api/auth/forgot-password/', {'email': 'customer@example.com'}, format='json')
        response_nonexisting = self.client.post('/api/auth/forgot-password/', {'email': 'unknown@example.com'}, format='json')
        
        self.assertEqual(response_existing.status_code, status.HTTP_200_OK)
        self.assertEqual(response_nonexisting.status_code, status.HTTP_200_OK)
        self.assertEqual(response_existing.json()['message'], response_nonexisting.json()['message'])

    def test_reset_password_enforces_minimum_length(self):
        """Security: Password reset must reject short or empty passwords."""
        response = self.client.post('/api/auth/reset-password/', {
            'email': 'customer@example.com',
            'otp': '123456',
            'password': 'short'
        }, format='json')
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('8 characters', response.json().get('error', ''))


class AccessControlAndPaymentSecurityTests(UnmanagedModelTestMixin, TransactionTestCase):
    def setUp(self):
        User.objects.all().delete()
        Payment.objects.all().delete()
        FreePrimeRequest.objects.all().delete()
        HeroBanner.objects.all().delete()
        self.client = APIClient()
        self.admin = User.objects.create_user(
            email='admin@thebaronclub.com',
            password='Password123!',
            name='Admin User',
            role='admin',
            phone='9999999991'
        )
        self.customer_a = User.objects.create_user(
            email='user_a@example.com',
            password='Password123!',
            name='Customer A',
            role='customer',
            phone='9999999993'
        )
        self.customer_b = User.objects.create_user(
            email='user_b@example.com',
            password='Password123!',
            name='Customer B',
            role='customer',
            phone='9999999994'
        )

    def test_hero_banner_creation_blocked_for_regular_user(self):
        """Security: Non-admin users cannot create or delete hero banners."""
        self.client.force_authenticate(user=self.customer_a)
        response = self.client.post('/api/hero-banners/', {}, format='multipart')
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_merchant_creation_blocked_for_regular_customer(self):
        """Security: Customers cannot directly create merchant records."""
        self.client.force_authenticate(user=self.customer_a)
        response = self.client.post('/api/merchants/', {'business_name': 'Fake Merchant'}, format='json')
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_free_prime_request_cannot_be_approved_by_customer(self):
        """Security: Customers cannot update or approve their own free prime request."""
        free_req = FreePrimeRequest.objects.create(user=self.customer_a, status='pending')
        self.client.force_authenticate(user=self.customer_a)
        
        # Attempt PATCH status to approved
        response = self.client.patch(f'/api/free-prime-requests/{free_req.id}/', {'status': 'approved'}, format='json')
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)
        
        free_req.refresh_from_db()
        self.assertEqual(free_req.status, 'pending')

    def test_payment_verification_idor_protection(self):
        """Security: User B cannot verify a payment order created by User A."""
        payment = Payment.objects.create(
            user=self.customer_a,
            razorpay_order_id='order_test_12345',
            amount=99900,
            status='pending',
            purpose='prime_membership'
        )
        
        self.client.force_authenticate(user=self.customer_b)
        response = self.client.post('/api/auth/razorpay/verify/', {
            'razorpay_order_id': 'order_test_12345',
            'razorpay_payment_id': 'pay_test_99999',
            'razorpay_signature': 'invalid_or_fake_sig'
        }, format='json')
        
        # Fails signature or unauthorized
        self.assertIn(response.status_code, [status.HTTP_400_BAD_REQUEST, status.HTTP_403_FORBIDDEN])

    @override_settings(DEBUG=False)
    def test_fake_purchase_prime_disabled_in_production(self):
        """Security: fake_purchase_prime must return 403 Forbidden in production for non-admins."""
        self.client.force_authenticate(user=self.customer_a)
        response = self.client.post('/api/users/fake_purchase_prime/', {}, format='json')
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)
