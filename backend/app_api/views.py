from django.db import models
from rest_framework import viewsets, permissions, status, views
from django.core.cache import cache
from rest_framework.parsers import MultiPartParser, FormParser, JSONParser
from rest_framework.response import Response
from rest_framework.decorators import action
from rest_framework_simplejwt.tokens import RefreshToken
from django.contrib.auth import authenticate
from django.utils.http import urlsafe_base64_encode, urlsafe_base64_decode
from django.utils.encoding import force_bytes, force_str
from django.contrib.auth.tokens import default_token_generator
from django.utils import timezone
from django.http import HttpResponse
from .models import (
    User, Category, Merchant, PrimeMembership, Payment, Voucher, AppSetting,
    Referral, ReferralLink, SystemAnnouncement, ReferralPayout
)
from .serializers import (
    UserSerializer, CategorySerializer, MerchantSerializer, 
    PrimeMembershipSerializer, PaymentSerializer, ReferralPayoutSerializer,
    ChangePasswordSerializer, VoucherSerializer, AppSettingSerializer
)


def sync_uploaded_file(saved_path):
    """
    Syncs/copies an uploaded file from the primary storage root (public_html/storage)
    to the secondary storage root (baronclub/public/storage) to maintain absolute consistency.
    """
    import os
    import shutil
    try:
        src = os.path.join('c:/Users/Dell/Documents/App/website/public_html/storage', saved_path)
        dst = os.path.join('c:/Users/Dell/Documents/App/website/baronclub/public/storage', saved_path)
        
        # Ensure destination directory exists
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        
        # Copy file
        if os.path.exists(src):
            shutil.copy2(src, dst)
            print(f"DEBUG SYNC: Copied {src} to {dst}")
        else:
            print(f"DEBUG SYNC: Source file {src} not found!")
    except Exception as e:
        print(f"DEBUG SYNC ERROR: Failed to sync file: {e}")

class AppSettingViewSet(viewsets.ModelViewSet):
    queryset = AppSetting.objects.all()
    serializer_class = AppSettingSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]

class AdminPaymentListView(views.APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        if request.user.role != 'admin' and not request.user.is_superuser:
            return Response({'error': 'Forbidden'}, status=status.HTTP_403_FORBIDDEN)
        
        payments = Payment.objects.all().order_by('-id')
        return Response(PaymentSerializer(payments, many=True).data)

class AdminVoucherListView(views.APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        if request.user.role != 'admin' and not request.user.is_superuser:
            return Response({'error': 'Forbidden'}, status=status.HTTP_403_FORBIDDEN)
        
        vouchers = Voucher.objects.all().order_by('-id')
        return Response(VoucherSerializer(vouchers, many=True).data)

import razorpay
from django.conf import settings

class RazorpayCreateOrderView(views.APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        user = request.user
        amount_in_rupees = request.data.get('amount')
        purpose = request.data.get('purpose', 'prime_membership')
        if purpose:
            purpose = purpose[:50]
        
        if not amount_in_rupees:
            return Response({'error': 'Amount is required'}, status=status.HTTP_400_BAD_REQUEST)
            
        try:
            amount = float(amount_in_rupees)
        except ValueError:
            return Response({'error': 'Invalid amount format'}, status=status.HTTP_400_BAD_REQUEST)
            
        if amount <= 0:
            return Response({'error': 'Amount must be greater than zero'}, status=status.HTTP_400_BAD_REQUEST)
            
        try:
            client = razorpay.Client(auth=(settings.RAZORPAY_KEY, settings.RAZORPAY_SECRET))
            # Amount in Razorpay is in paise (cents), so multiply by 100
            paise_amount = int(amount * 100)
            
            razorpay_order = client.order.create({
                'amount': paise_amount,
                'currency': 'INR',
                'payment_capture': 1
            })
            
            # Save a pending payment in our database
            payment = Payment.objects.create(
                user=user,
                razorpay_order_id=razorpay_order['id'],
                amount=paise_amount,
                status='pending',
                purpose=purpose
            )
            
            return Response({
                'status': 'success',
                'order_id': razorpay_order['id'],
                'amount': paise_amount,
                'key': settings.RAZORPAY_KEY,
                'currency': 'INR'
            })
            
        except Exception as e:
            import traceback
            traceback.print_exc()
            return Response({'error': f'Failed to create order: {str(e)}'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

class RazorpayVerifyPaymentView(views.APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        user = request.user
        order_id = request.data.get('razorpay_order_id')
        payment_id = request.data.get('razorpay_payment_id')
        signature = request.data.get('razorpay_signature')
        
        if not order_id or not payment_id or not signature:
            return Response({'error': 'Missing parameters'}, status=status.HTTP_400_BAD_REQUEST)
            
        try:
            client = razorpay.Client(auth=(settings.RAZORPAY_KEY, settings.RAZORPAY_SECRET))
            client.utility.verify_payment_signature({
                'razorpay_order_id': order_id,
                'razorpay_payment_id': payment_id,
                'razorpay_signature': signature
            })
        except razorpay.errors.SignatureVerificationError:
            return Response({'error': 'Invalid payment signature'}, status=status.HTTP_400_BAD_REQUEST)
            
        try:
            payment = Payment.objects.get(razorpay_order_id=order_id)
        except Payment.DoesNotExist:
            payment = Payment.objects.create(
                user=user,
                razorpay_order_id=order_id,
                amount=99900,
                purpose='prime_membership'
            )
            
        payment.razorpay_payment_id = payment_id
        payment.status = 'success'
        payment.save()
        
        from django.utils import timezone
        now = timezone.now()
        
        active_membership = PrimeMembership.objects.filter(user=user, expires_at__gt=now).first()
        if active_membership:
            active_membership.expires_at = active_membership.expires_at + timezone.timedelta(days=365)
            active_membership.save()
            membership = active_membership
        else:
            membership = PrimeMembership.objects.create(
                user=user,
                source='payment',
                starts_at=now,
                expires_at=now + timezone.timedelta(days=365)
            )
            
        # Dynamically process referral code if provided during Prime purchase
        referral_code = request.data.get('referral_code')
        if referral_code:
            try:
                clean_code = ''.join(c for c in str(referral_code) if c.isdigit())
                if clean_code:
                    referrer = User.objects.filter(customer_number=int(clean_code)).first()
                    if referrer and referrer != user:
                        if not Referral.objects.filter(referred=user).exists():
                            import random, string
                            link, _ = ReferralLink.objects.get_or_create(
                                user=referrer,
                                defaults={
                                    'token': ''.join(random.choices(string.ascii_letters + string.digits, k=32)),
                                    'expires_at': timezone.now() + timezone.timedelta(days=365)
                                }
                            )
                            Referral.objects.create(
                                referrer=referrer,
                                referred=user,
                                referral_link=link
                            )
                            print(f"Created dynamic referral record via verify_payment: {referrer.email} referred {user.email}")
            except Exception as e:
                print(f"Error processing dynamic referral code via verify_payment: {e}")
            
        referral = Referral.objects.filter(referred=user, reward_paid_at__isnull=True).first()
        if referral:
            referrer = referral.referrer
            reward_amount = 100
            referrer.referral_balance = float(referrer.referral_balance or 0) + reward_amount
            referrer.referral_total_earned = float(referrer.referral_total_earned or 0) + reward_amount
            referrer.save()
            referral.reward_paid_at = timezone.now()
            referral.reward_amount = reward_amount
            referral.save()
            
        return Response({
            'status': 'success',
            'message': 'Payment verified and Prime membership activated successfully!',
            'user': UserSerializer(user).data
        })

class CustomerTransactionsView(views.APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        user = request.user
        payments = Payment.objects.filter(user=user).order_by('-id')
        vouchers = Voucher.objects.filter(user=user).order_by('-id')
        
        payments_data = PaymentSerializer(payments, many=True).data
        vouchers_data = VoucherSerializer(vouchers, many=True).data
        
        return Response({
            'payments': payments_data,
            'vouchers': vouchers_data
        })

from django.db import transaction, models
from django.utils import timezone
import random, string

class CategoryViewSet(viewsets.ModelViewSet):
    queryset = Category.objects.all()
    serializer_class = CategorySerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]

    def destroy(self, request, *args, **kwargs):
        if request.user.role != 'admin':
            return Response({'error': 'Unauthorized'}, status=status.HTTP_403_FORBIDDEN)
        return super().destroy(request, *args, **kwargs)

class MerchantViewSet(viewsets.ModelViewSet):
    queryset = Merchant.objects.all()
    serializer_class = MerchantSerializer
    parser_classes = (MultiPartParser, FormParser, JSONParser)

    def perform_update(self, serializer):
        # Handle file uploads manually if they are in request.FILES
        instance = serializer.save()
        updated = False
        
        from django.core.files.storage import default_storage
        from django.core.files.base import ContentFile
        import uuid

        if 'logo' in self.request.FILES:
            image = self.request.FILES['logo']
            path = default_storage.save(f"merchant-logos/{uuid.uuid4()}.{image.name.split('.')[-1]}", ContentFile(image.read()))
            instance.logo = path
            updated = True
            sync_uploaded_file(path)
            
        if 'profile_photo' in self.request.FILES: # Compatibility with frontend param name
            image = self.request.FILES['profile_photo']
            path = default_storage.save(f"merchant-logos/{uuid.uuid4()}.{image.name.split('.')[-1]}", ContentFile(image.read()))
            instance.logo = path
            updated = True
            sync_uploaded_file(path)

        if 'card_image' in self.request.FILES:
            image = self.request.FILES['card_image']
            path = default_storage.save(f"merchant-cards/{uuid.uuid4()}.{image.name.split('.')[-1]}", ContentFile(image.read()))
            instance.card_image = path
            updated = True
            sync_uploaded_file(path)
            
        if updated:
            instance.save()

    def perform_destroy(self, instance):
        # When a merchant is deleted, also delete their associated user.
        # Some deployments may lack the django_admin_log table, which can cause a
        # ProgrammingError during the delete cascade. We catch any exception
        # and log it, allowing the deletion to proceed without aborting the
        # request.
        try:
            user = instance.user
            instance.delete()
            if user:
                user.delete()
        except Exception as e:
            # Log the error for debugging; continue to ensure the API response
            print(f"Error during merchant/user deletion: {e}")
            # Attempt a fallback raw deletion to avoid admin log triggers
            from django.db import connection
            try:
                with connection.cursor() as cursor:
                    cursor.execute('DELETE FROM app_api_merchant WHERE id = %s', [instance.id])
                    if user:
                        cursor.execute('DELETE FROM app_api_user WHERE id = %s', [user.id])
            except Exception as raw_err:
                print(f"Fallback raw deletion also failed: {raw_err}")

    def get_permissions(self):
        if self.action in ['list', 'retrieve']:
            return [permissions.AllowAny()]
        return [permissions.IsAuthenticated()]

    def get_queryset(self):
        user = self.request.user
        if user.is_authenticated and (user.role == 'admin' or user.is_superuser):
            queryset = Merchant.objects.all()
        else:
            queryset = Merchant.objects.filter(status='active')
            
        category = self.request.query_params.get('category')
        if category:
            queryset = queryset.filter(category=category)
        return queryset

    @action(detail=True, methods=['post'])
    def restore(self, request, pk=None):
        if self.request.user.role != 'admin' and not self.request.user.is_superuser:
            return Response({'error': 'Forbidden'}, status=status.HTTP_403_FORBIDDEN)
            
        merchant = self.get_object()
        merchant.status = 'active'
        merchant.save()
        return Response({'status': 'Merchant restored'})

    @action(detail=False, methods=['get'])
    def verify_user(self, request):
        query = request.query_params.get('query')
        if not query:
            return Response({'error': 'Query parameter required'}, status=400)
            
        user = User.objects.filter(models.Q(email=query) | models.Q(phone=query)).first()
        if not user:
            return Response({'error': 'User not found'}, status=404)
            
        is_prime = PrimeMembership.objects.filter(user=user, expires_at__gt=timezone.now()).exists()
        
        return Response({
            'id': user.id,
            'name': user.name,
            'email': user.email,
            'is_prime': is_prime,
            'status': user.status
        })

    @action(detail=False, methods=['post'])
    def redeem(self, request):
        user_id = request.data.get('user_id')
        bill_amount = float(request.data.get('bill_amount', 0))
        merchant_user = request.user
        
        try:
            merchant = Merchant.objects.get(user=merchant_user)
            user = User.objects.get(id=user_id)
        except:
            return Response({'error': 'Invalid user or merchant'}, status=400)

        amount_saved = (bill_amount * merchant.discount_percent) / 100.0
        
        # Create a completed voucher record
        voucher = Voucher.objects.create(
            code=f"APP-{''.join(random.choices(string.ascii_uppercase + string.digits, k=6))}",
            user=user,
            merchant_profile=merchant,
            discount_percent=merchant.discount_percent,
            bill_amount=bill_amount,
            amount_saved=amount_saved,
            used_at=timezone.now(),
            expires_at=timezone.now()
        )
        
        return Response({
            'status': 'success',
            'message': f'{merchant.discount_percent}% Discount Redeemed!',
            'voucher_code': voucher.code,
            'amount_saved': amount_saved
        })

    @action(detail=True, methods=['post'])
    def customer_pay(self, request, pk=None):
        try:
            merchant = self.get_object()
        except Exception:
            return Response({'error': 'Invalid merchant'}, status=400)
            
        user = request.user
        
        # Check active Prime membership to enforce policy
        from django.utils import timezone
        is_prime = PrimeMembership.objects.filter(user=user, expires_at__gt=timezone.now()).exists()
        if not is_prime:
            return Response({'error': 'Active Prime membership is required to redeem discounts.'}, status=status.HTTP_400_BAD_REQUEST)
            
        try:
            bill_amount = float(request.data.get('bill_amount', 0))
        except (ValueError, TypeError):
            return Response({'error': 'Invalid bill amount'}, status=400)
            
        if bill_amount <= 0:
            return Response({'error': 'Bill amount must be greater than zero'}, status=400)
            
        amount_saved = (bill_amount * merchant.discount_percent) / 100.0
        
        # Generate voucher code
        import random
        import string
        code = f"APP-{''.join(random.choices(string.ascii_uppercase + string.digits, k=6))}"
        
        # Create a completed voucher record representing the transaction
        voucher = Voucher.objects.create(
            code=code,
            user=user,
            merchant_profile=merchant,
            discount_percent=merchant.discount_percent,
            bill_amount=bill_amount,
            amount_saved=amount_saved,
            used_at=timezone.now(),
            expires_at=timezone.now()
        )
        
        return Response({
            'status': 'success',
            'message': 'Payment and discount processed successfully!',
            'voucher_code': voucher.code,
            'amount_saved': amount_saved
        })

class ReferralPayoutViewSet(viewsets.ModelViewSet):
    queryset = ReferralPayout.objects.all().order_by('-created_at')
    serializer_class = ReferralPayoutSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        if self.request.user.role == 'admin':
            return self.queryset
        return self.queryset.filter(user=self.request.user)

    @action(detail=True, methods=['post'])
    def mark_completed(self, request, pk=None):
        if request.user.role != 'admin':
            return Response({'error': 'Forbidden'}, status=status.HTTP_403_FORBIDDEN)
        payout = self.get_object()
        payout.status = 'completed'
        payout.admin = request.user
        payout.save()
        return Response({'status': 'completed'})

    @action(detail=True, methods=['post'])
    def decline_payout(self, request, pk=None):
        if request.user.role != 'admin':
            return Response({'error': 'Forbidden'}, status=status.HTTP_403_FORBIDDEN)
        
        payout = self.get_object()
        if payout.status != 'pending':
            return Response({'error': 'Only pending payouts can be declined'}, status=status.HTTP_400_BAD_REQUEST)
            
        remark = request.data.get('remark', '')
        
        from django.db import transaction
        with transaction.atomic():
            payout.status = 'declined'
            payout.notes = remark
            payout.admin = request.user
            payout.save()
            
            # Refund money back to user referral_balance
            user = payout.user
            user.referral_balance = float(user.referral_balance) + float(payout.amount)
            user.save()
            
        return Response({'status': 'declined', 'remark': remark})

class UserViewSet(viewsets.ModelViewSet):
    queryset = User.objects.all()
    serializer_class = UserSerializer
    permission_classes = [permissions.IsAuthenticated]
    parser_classes = (MultiPartParser, FormParser, JSONParser)

    def get_queryset(self):
        if self.request.user.role == 'admin' or self.request.user.is_superuser:
            return User.objects.all().order_by('-created_at')
        return User.objects.filter(id=self.request.user.id)

    @action(detail=False, methods=['post'])
    def admin_create_staff(self, request):
        if self.request.user.role != 'admin' and not self.request.user.is_superuser:
            return Response({'error': 'Forbidden'}, status=status.HTTP_403_FORBIDDEN)
        
        data = request.data
        try:
            user = User.objects.create_user(
                email=data.get('email'),
                password=data.get('password'),
                name=data.get('name', data.get('username', 'Staff')),
                role=data.get('role', 'staff'),
                email_verified_at=timezone.now(),
                status='active'
            )
            return Response(UserSerializer(user).data, status=status.HTTP_201_CREATED)
        except Exception as e:
            return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)

    @action(detail=False, methods=['post'])
    def admin_create_merchant(self, request):
        if self.request.user.role != 'admin' and not self.request.user.is_superuser:
            return Response({'error': 'Forbidden'}, status=status.HTTP_403_FORBIDDEN)
        
        data = request.data
        print(f"DEBUG: admin_create_merchant received data: {data}")
        try:
            # Check for mandatory fields
            mandatory_fields = ['business_name', 'email', 'password', 'phone', 'discount_percent', 'address']
            for field in mandatory_fields:
                val = data.get(field)
                print(f"DEBUG: Checking field {field}, value: '{val}'")
                if val is None or str(val).strip() == "" or str(val).strip() == "null":
                    print(f"DEBUG: Field {field} is MISSING or empty")
                    return Response({'error': f'{field.replace("_", " ").title()} is mandatory'}, status=status.HTTP_400_BAD_REQUEST)

            email = data.get('email')
            phone = data.get('phone')
            
            if User.objects.filter(email=email).exists():
                return Response({'error': 'A user with this email already exists'}, status=status.HTTP_400_BAD_REQUEST)
                
            if User.objects.filter(phone=phone).exists():
                return Response({'error': 'A user with this phone number already exists'}, status=status.HTTP_400_BAD_REQUEST)

            from django.db import transaction
            from decimal import Decimal, InvalidOperation
            
            lat_val = data.get('latitude')
            lng_val = data.get('longitude')
            
            try:
                latitude = Decimal(str(lat_val)) if lat_val and str(lat_val).strip() not in ('', 'None', 'null') else None
            except (InvalidOperation, ValueError):
                latitude = None
                
            try:
                longitude = Decimal(str(lng_val)) if lng_val and str(lng_val).strip() not in ('', 'None', 'null') else None
            except (InvalidOperation, ValueError):
                longitude = None

            with transaction.atomic():
                # 1. Create the User
                from django.utils import timezone
                user = User.objects.create_user(
                    email=email,
                    password=data.get('password'),
                    name=data.get('business_name'),
                    phone=phone,
                    role='merchant',
                    email_verified_at=timezone.now() # Auto-verify for admin-created users to allow website login
                )
                
                # 2. Create the Merchant Profile
                merchant = Merchant.objects.create(
                    user=user,
                    business_name=data.get('business_name'),
                    category=data.get('category'),
                    address=data.get('address'),
                    description=data.get('description'),
                    status=data.get('status', 'active'),
                    discount_percent=data.get('discount_percent', 50),
                    latitude=latitude,
                    longitude=longitude,
                )

                # 3. Handle File Upload (Image)
                if 'card_image' in request.FILES:
                    from django.core.files.storage import default_storage
                    from django.core.files.base import ContentFile
                    import uuid
                    
                    image = request.FILES['card_image']
                    ext = image.name.split('.')[-1]
                    filename = f"merchant-cards/{uuid.uuid4()}.{ext}"
                    path = default_storage.save(filename, ContentFile(image.read()))
                    sync_uploaded_file(path)
                    
                    # Store in both fields so it shows up in both list and detail views
                    merchant.card_image = path
                    merchant.logo = path 
                    merchant.save()
            
            return Response({
                'user': UserSerializer(user).data,
                'merchant': MerchantSerializer(merchant).data
            }, status=status.HTTP_201_CREATED)
        except Exception as e:
            print(f"DEBUG admin_create_merchant ERROR: {e}")
            return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)

    @action(detail=True, methods=['post'])
    def grant_prime(self, request, pk=None):
        if self.request.user.role != 'admin' and not self.request.user.is_superuser:
            return Response({'error': 'Forbidden'}, status=status.HTTP_403_FORBIDDEN)
            
        user = self.get_object()
        PrimeMembership.objects.create(
            user=user,
            source='admin_grant',
            starts_at=timezone.now(),
            expires_at=timezone.now() + timezone.timedelta(days=365)
        )
        return Response({'status': 'Prime membership granted'})

    @action(detail=True, methods=['post'])
    def revoke_prime(self, request, pk=None):
        if self.request.user.role != 'admin' and not self.request.user.is_superuser:
            return Response({'error': 'Forbidden'}, status=status.HTTP_403_FORBIDDEN)
            
        user = self.get_object()
        PrimeMembership.objects.filter(user=user).delete()
        return Response({'status': 'Prime membership revoked'})

    @action(detail=False, methods=['post'])
    def fake_purchase_prime(self, request):
        user = request.user
        
        # 1. Create the membership
        PrimeMembership.objects.create(
            user=user,
            source='payment',
            starts_at=timezone.now(),
            expires_at=timezone.now() + timezone.timedelta(days=365)
        )
        
        # Dynamically process referral code if provided during Prime purchase
        referral_code = request.data.get('referral_code')
        if referral_code:
            try:
                clean_code = ''.join(c for c in str(referral_code) if c.isdigit())
                if clean_code:
                    referrer = User.objects.filter(customer_number=int(clean_code)).first()
                    if referrer and referrer != user:
                        if not Referral.objects.filter(referred=user).exists():
                            import random, string
                            link, _ = ReferralLink.objects.get_or_create(
                                user=referrer,
                                defaults={
                                    'token': ''.join(random.choices(string.ascii_letters + string.digits, k=32)),
                                    'expires_at': timezone.now() + timezone.timedelta(days=365)
                                }
                            )
                            Referral.objects.create(
                                referrer=referrer,
                                referred=user,
                                referral_link=link
                            )
                            print(f"Created dynamic referral record: {referrer.email} referred {user.email}")
            except Exception as e:
                print(f"Error processing dynamic referral code: {e}")
        
        # 2. Check for referral reward
        # On the website, if a referred user takes prime, the referrer gets 100
        referral = Referral.objects.filter(referred=user, reward_paid_at__isnull=True).first()
        if referral:
            referrer = referral.referrer
            reward_amount = 100
            
            # Update referrer's balance safely using float
            referrer.referral_balance = float(referrer.referral_balance or 0) + reward_amount
            referrer.referral_total_earned = float(referrer.referral_total_earned or 0) + reward_amount
            referrer.save()
            
            # Mark referral as paid
            referral.reward_paid_at = timezone.now()
            referral.reward_amount = reward_amount
            referral.save()
            
            print(f"Awarded ₹{reward_amount} referral bonus to {referrer.email} for {user.email}")
            
        user.refresh_from_db()
        return Response({
            'status': 'success', 
            'message': 'Prime Activated! Referral rewards processed.',
            'user': UserSerializer(user).data
        })

    @action(detail=True, methods=['post'])
    def process_payout(self, request, pk=None):
        if self.request.user.role != 'admin' and not self.request.user.is_superuser:
            return Response({'error': 'Forbidden'}, status=status.HTTP_403_FORBIDDEN)
            
        user = self.get_object()
        amount = request.data.get('amount', 0)
        if user.referral_balance < float(amount):
            return Response({'error': 'Insufficient balance'}, status=status.HTTP_400_BAD_REQUEST)
            
        user.referral_balance -= models.DecimalField().to_python(amount)
        user.save()
        return Response({'status': 'Payout processed', 'remaining_balance': user.referral_balance})

    @action(detail=True, methods=['post'])
    def reset_password(self, request, pk=None):
        if self.request.user.role != 'admin' and not self.request.user.is_superuser:
            return Response({'error': 'Forbidden'}, status=status.HTTP_403_FORBIDDEN)
            
        user = self.get_object()
        password = request.data.get('password')
        if not password:
            return Response({'error': 'Password is required'}, status=status.HTTP_400_BAD_REQUEST)
        if len(password) < 8:
            return Response({'error': 'Password must be at least 8 characters'}, status=status.HTTP_400_BAD_REQUEST)
            
        user.set_password(password)
        user.save()
        return Response({'status': 'success', 'message': 'Password reset successfully'})

    def destroy(self, request, *args, **kwargs):
        if self.request.user.role != 'admin' and not self.request.user.is_superuser:
            return Response({'error': 'Forbidden'}, status=status.HTTP_403_FORBIDDEN)
            
        instance = self.get_object()
        user_id = instance.id
        
        from django.db import connection
        try:
            with transaction.atomic():
                with connection.cursor() as cursor:
                    # 1. Delete prime memberships
                    cursor.execute("DELETE FROM prime_memberships WHERE user_id = %s", [user_id])
                    # 2. Delete vouchers associated with merchant profiles of this user (if merchant)
                    cursor.execute("DELETE FROM vouchers WHERE merchant_profile_id IN (SELECT id FROM merchant_profiles WHERE user_id = %s)", [user_id])
                    # 3. Delete vouchers associated with this user
                    cursor.execute("DELETE FROM vouchers WHERE user_id = %s", [user_id])
                    # 4. Delete referral payouts
                    cursor.execute("DELETE FROM referral_payouts WHERE user_id = %s", [user_id])
                    # 5. Set referral payouts admin to NULL
                    cursor.execute("UPDATE referral_payouts SET admin_id = NULL WHERE admin_id = %s", [user_id])
                    # 6. Delete referrals
                    cursor.execute("DELETE FROM referrals WHERE referrer_id = %s OR referred_id = %s", [user_id, user_id])
                    # 7. Delete referral links
                    cursor.execute("DELETE FROM referral_links WHERE user_id = %s", [user_id])
                    # 8. Delete payments
                    cursor.execute("DELETE FROM payments WHERE user_id = %s", [user_id])
                    # 9. Delete merchant profiles
                    cursor.execute("DELETE FROM merchant_profiles WHERE user_id = %s", [user_id])
                    # 10. Finally delete the user
                    cursor.execute("DELETE FROM users WHERE id = %s", [user_id])
            return Response({'status': 'success', 'message': 'User and all related records deleted successfully'}, status=status.HTTP_200_OK)
        except Exception as e:
            return Response({'error': f'Failed to delete user: {str(e)}'}, status=status.HTTP_400_BAD_REQUEST)

class LoginView(views.APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        # Support both email and username label for backward compatibility in UI
        email = (request.data.get('email') or request.data.get('username', '')).strip().lower()
        password = request.data.get('password')
        
        print(f"Login attempt for email: '{email}'")
        try:
            db_user = User.objects.get(email__iexact=email)
            if db_user.status == 'blocked':
                return Response({'error': 'Your account has been blocked by the administrator.'}, status=status.HTTP_403_FORBIDDEN)
            print(f"DEBUG: User found in DB: {db_user.email}, Role: {db_user.role}")
            print(f"DEBUG: Stored Hash: {db_user.password[:20]}...")
            
            # Manually check password to see if it matches
            match = db_user.check_password(password)
            print(f"DEBUG: Manual check_password match: {match}")
        except User.DoesNotExist:
            print(f"DEBUG: No user found in DB with email: {email}")
            
        user = authenticate(username=email, password=password)
        if user:
            print(f"Login successful for user: {user.email}")
            refresh = RefreshToken.for_user(user)
            return Response({
                'refresh': str(refresh),
                'access': str(refresh.access_token),
                'user': UserSerializer(user).data
            })
        
        print(f"Login failed for email: {email}")
        return Response({'error': 'Invalid Credentials'}, status=status.HTTP_401_UNAUTHORIZED)

from django.core.mail import send_mail
from django.conf import settings

def send_verification_email(user):
    subject = 'Verify your email - The Baron Club'
    # Generate a secure verification link pointing to the Django backend
    uid = urlsafe_base64_encode(force_bytes(user.pk))
    token = default_token_generator.make_token(user)
    # Use the production domain URL for verification
    verification_url = f"https://thebaronclub.com/api/auth/verify-email/{uid}/{token}/"
    
    html_message = f"""
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 10px;">
        <div style="text-align: center; margin-bottom: 30px;">
            <img src="https://thebaronclub.com/logo-01.png" alt="The Baron Club" style="height: 80px;">
        </div>
        <h2 style="color: #333; text-align: center;">Verify your email</h2>
        <p style="color: #555; font-size: 16px; line-height: 1.5;">
            Hello {user.name},<br><br>
            Thanks for signing up for The Baron Club! Please click the button below to verify your email address and activate your account.
        </p>
        <div style="text-align: center; margin: 40px 0;">
            <a href="{verification_url}" style="background-color: #ff4d00; color: white; padding: 15px 30px; text-decoration: none; border-radius: 50px; font-weight: bold; font-size: 16px;">Verify Email Address</a>
        </div>
        <p style="color: #888; font-size: 14px; text-align: center;">
            If you did not create an account, no further action is required.
        </p>
        <hr style="border: none; border-top: 1px solid #eee; margin: 30px 0;">
        <p style="color: #aaa; font-size: 12px; text-align: center;">
            © 2026 The Baron Club. All rights reserved.
        </p>
    </div>
    """
    send_mail(
        subject,
        'Please verify your email address.',
        settings.DEFAULT_FROM_EMAIL,
        [user.email],
        html_message=html_message,
        fail_silently=False,
    )

def send_otp_email(user, otp, expiry_str):
    subject = f'Your OTP: {otp} - The Baron Club'
    
    html_message = f"""
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 10px; background-color: #ffffff;">
        <div style="text-align: center; margin-bottom: 30px;">
            <img src="https://thebaronclub.com/logo-01.png" alt="The Baron Club" style="height: 80px;">
        </div>
        <h2 style="color: #333; text-align: center;">Verify your email</h2>
        <p style="color: #555; font-size: 16px; line-height: 1.5; text-align: center;">
            Hello {user.name},<br><br>
            Use the following One-Time Password (OTP) to verify your email address. This code is valid for 15 minutes.
        </p>
        <div style="text-align: center; margin: 40px 0;">
            <div style="background-color: #f8f9fa; color: #ff4d00; padding: 20px; border-radius: 10px; font-weight: bold; font-size: 32px; letter-spacing: 10px; display: inline-block; border: 1px dashed #ff4d00;">
                {otp}
            </div>
        </div>
        <p style="color: #888; font-size: 14px; text-align: center;">
            If you did not request this, please ignore this email.
        </p>
        <hr style="border: none; border-top: 1px solid #eee; margin: 30px 0;">
        <p style="color: #aaa; font-size: 12px; text-align: center;">
            © 2026 The Baron Club. All rights reserved.
        </p>
    </div>
    """
    
    send_mail(
        subject,
        f'Your verification code is {otp}',
        settings.DEFAULT_FROM_EMAIL,
        [user.email],
        html_message=html_message,
        fail_silently=False,
    )

class SignupView(views.APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        data = request.data
        name = data.get('name')
        email = data.get('email')
        password = data.get('password')
        phone = data.get('phone')
        role = data.get('role', 'customer').lower()
        
        if not name or not email or not password:
            return Response({'error': 'Name, Email and Password are required'}, status=status.HTTP_400_BAD_REQUEST)
            
        if len(password) < 8:
            return Response({'error': 'The password field must be at least 8 characters.'}, status=status.HTTP_400_BAD_REQUEST)
            
        if User.objects.filter(email=email).exists():
            return Response({'error': 'Email already exists'}, status=status.HTTP_400_BAD_REQUEST)
        
        user = User.objects.create_user(
            email=email,
            password=password,
            name=name,
            role=role,
            phone=phone if phone else None,
            status='active',
            email_verified_at=None,
            state=data.get('state')
        )

        # Handle Referral Code
        referral_code = data.get('referral_code')
        if referral_code and role == 'customer':
            try:
                # Extract only digit characters to match integer customer_number safely
                clean_code = ''.join(c for c in str(referral_code) if c.isdigit())
                if clean_code:
                    referrer = User.objects.filter(customer_number=int(clean_code)).first()
                    if referrer:
                        # Find or create a referral link for the referrer
                        # In Laravel, these are typically pre-generated or created on first use
                        link, _ = ReferralLink.objects.get_or_create(
                            user=referrer,
                            defaults={'token': ''.join(random.choices(string.ascii_letters + string.digits, k=32)), 'expires_at': timezone.now() + timezone.timedelta(days=365)}
                        )
                        
                        Referral.objects.create(
                            referrer=referrer,
                            referred=user,
                            referral_link=link
                        )
                        print(f"Created referral record: {referrer.email} referred {user.email}")
            except Exception as e:
                print(f"Error processing referral code: {e}")
        
        if role == 'merchant':
            Merchant.objects.create(
                user=user,
                business_name=data.get('business_name', name + "'s Business"),
                address=data.get('address', ''),
                status='active',
                discount_percent=50
            )
        
        try:
            # Generate OTP and send via Hostinger
            otp = ''.join(random.choices(string.digits, k=6))
            cache_key = f"otp_{user.email}"
            cache.set(cache_key, otp, 900) # 15 minutes
            
            expiry_str = (timezone.now() + timezone.timedelta(minutes=15)).strftime("%I:%M %p")
            send_otp_email(user, otp, expiry_str)
        except Exception as e:
            print(f"Error sending OTP email: {e}")

        refresh = RefreshToken.for_user(user)
        return Response({
            'refresh': str(refresh),
            'access': str(refresh.access_token),
            'user': UserSerializer(user).data,
            'message': 'OTP sent to your email'
        }, status=status.HTTP_201_CREATED)

class ResendVerificationView(views.APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        user = request.user
        if user.email_verified_at:
            return Response({'message': 'Email already verified'}, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            # Generate OTP and send via Hostinger
            otp = ''.join(random.choices(string.digits, k=6))
            cache_key = f"otp_{user.email}"
            cache.set(cache_key, otp, 900) # 15 minutes
            
            expiry_str = (timezone.now() + timezone.timedelta(minutes=15)).strftime("%I:%M %p")
            send_otp_email(user, otp, expiry_str)
            
            return Response({
                'message': 'OTP sent to your email'
            })
        except Exception as e:
            return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

class VerifyOTPView(views.APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        user = request.user
        otp_received = request.data.get('otp')
        
        print(f"OTP Verification attempt for user: {user.email}, OTP: {otp_received}")
        
        if not otp_received:
            return Response({'error': 'Please enter the 6-digit OTP code.'}, status=status.HTTP_400_BAD_REQUEST)
            
        cache_key = f"otp_{user.email}"
        cached_otp = cache.get(cache_key)
        
        print(f"Cached OTP for {user.email}: {cached_otp}")
        
        if cached_otp and str(cached_otp) == str(otp_received):
            print(f"OTP Match! Verifying {user.email}")
            user.email_verified_at = timezone.now()
            user.save()
            cache.delete(cache_key)
            return Response({
                'message': 'Email verified successfully',
                'user': UserSerializer(user).data
            })
        else:
            print(f"OTP Mismatch or Expired for {user.email}")
            return Response({'error': 'The OTP you entered is invalid or has expired. Please try again.'}, status=status.HTTP_400_BAD_REQUEST)

class VerifyEmailView(views.APIView):
    permission_classes = [permissions.AllowAny]

    def get(self, request, uidb64, token):
        try:
            uid = force_str(urlsafe_base64_decode(uidb64))
            user = User.objects.get(pk=uid)
        except (TypeError, ValueError, OverflowError, User.DoesNotExist):
            user = None

        if user is not None and default_token_generator.check_token(user, token):
            user.email_verified_at = timezone.now()
            user.save()
            return HttpResponse("""
                <html>
                    <body style="font-family: Arial; text-align: center; padding: 50px; background-color: #0c0c11; color: white;">
                        <img src="https://thebaronclub.com/logo-01.png" style="height: 80px; margin-bottom: 30px;">
                        <h1 style="color: #ff4d00;">Email Verified Successfully!</h1>
                        <p style="font-size: 18px;">Your account is now active. You can close this page and log in to the app.</p>
                        <div style="margin-top: 40px;">
                             <a href="#" style="background-color: #ff4d00; color: white; padding: 12px 25px; text-decoration: none; border-radius: 5px;">Back to App</a>
                        </div>
                    </body>
                </html>
            """)
        else:
            return HttpResponse("Verification link is invalid or has expired.", status=400)

class ForgotPasswordView(views.APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        email = request.data.get('email')
        if not email:
            return Response({'error': 'Email is required'}, status=status.HTTP_400_BAD_REQUEST)
            
        try:
            user = User.objects.get(email=email)
            otp = str(random.randint(100000, 999999))
            cache.set(f'otp_{email}', otp, timeout=600) # 10 minutes
            
            expiry_str = (timezone.now() + timezone.timedelta(minutes=10)).strftime("%I:%M %p")
            print(f"DEBUG: Sending Forgot Password OTP {otp} to {user.email}")
            send_otp_email(user, otp, expiry_str)
            return Response({'message': 'OTP sent to your email'}, status=status.HTTP_200_OK)
        except User.DoesNotExist:
            print(f"DEBUG: Forgot Password requested for non-existent email: {email}")
            return Response({'error': 'User with this email does not exist.'}, status=status.HTTP_404_NOT_FOUND)
        except Exception as e:
            print(f"DEBUG: Forgot Password Error: {str(e)}")
            return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

class ResetPasswordView(views.APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        email = request.data.get('email')
        otp = request.data.get('otp')
        password = request.data.get('password')
        
        if not email or not otp or not password:
            return Response({'error': 'Email, OTP and Password are required'}, status=status.HTTP_400_BAD_REQUEST)
            
        cached_otp = cache.get(f'otp_{email}')
        if cached_otp and str(cached_otp) == str(otp):
            try:
                user = User.objects.get(email=email)
                user.set_password(password)
                user.save()
                cache.delete(f'otp_{email}')
                return Response({'message': 'Password reset successfully'}, status=status.HTTP_200_OK)
            except User.DoesNotExist:
                return Response({'error': 'User not found'}, status=status.HTTP_404_NOT_FOUND)
        else:
            return Response({'error': 'Invalid or expired OTP'}, status=status.HTTP_400_BAD_REQUEST)

class ProfileView(views.APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        print(f"ProfileView hit for user: {request.user}")
        return Response(UserSerializer(request.user).data)

    def put(self, request):
        user = request.user
        data = request.data
        
        # List of allowed fields to update
        allowed_fields = [
            'name', 'phone', 'bank_account_holder_name', 
            'bank_account_number', 'bank_ifsc', 'bank_name', 'bank_upi_id'
        ]
        
        updated = False
        for field in allowed_fields:
            if field in data:
                setattr(user, field, data[field])
                updated = True
        
        if updated:
            user.save()
            return Response(UserSerializer(user).data)
        
        return Response({'error': 'No valid fields provided'}, status=status.HTTP_400_BAD_REQUEST)

    def post(self, request):
        # This is for withdrawal requests
        user = request.user
        amount = request.data.get('amount')
        
        if not amount:
            return Response({'error': 'Amount is required'}, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            amount = float(amount)
        except ValueError:
            return Response({'error': 'Invalid amount'}, status=status.HTTP_400_BAD_REQUEST)
            
        if amount > float(user.referral_balance):
            return Response({'error': 'Insufficient referral balance'}, status=status.HTTP_400_BAD_REQUEST)
            
        if amount < 100: # Minimum withdrawal
            return Response({'error': 'Minimum withdrawal is ₹100'}, status=status.HTTP_400_BAD_REQUEST)
            
        # Create payout record
        ReferralPayout.objects.create(
            user=user,
            amount=amount,
            status='pending'
        )
        
        # Deduct from balance
        user.referral_balance = float(user.referral_balance) - amount
        user.save()
        
        return Response({'message': 'Withdrawal request submitted successfully', 'user': UserSerializer(user).data})

class AdminNotificationView(views.APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        if request.user.role == 'admin' or request.user.is_superuser:
            announcements = SystemAnnouncement.objects.all().order_by('-created_at')
        else:
            role = request.user.role.upper()
            announcements = SystemAnnouncement.objects.filter(
                models.Q(target='BOTH') | models.Q(target=role)
            ).order_by('-created_at')[:20]
        
        return Response([{
            'id': a.id,
            'title': a.title,
            'message': a.message,
            'target': a.target,
            'is_auto': a.is_auto,
            'created_at': a.created_at
        } for a in announcements])

    def post(self, request):
        if request.user.role != 'admin' and not request.user.is_superuser:
            return Response({'error': 'Forbidden'}, status=status.HTTP_403_FORBIDDEN)
        
        title = request.data.get('title')
        message = request.data.get('message')
        target = request.data.get('target', 'BOTH')

        if not title or not message:
            return Response({'error': 'Title and message are required'}, status=status.HTTP_400_BAD_REQUEST)

        # 1. Save to our new table
        SystemAnnouncement.objects.create(
            title=title,
            message=message,
            target=target,
            is_auto=False
        )

        return Response({'status': 'success', 'message': 'Announcement broadcasted successfully'})

    def delete(self, request, pk=None):
        if request.user.role != 'admin' and not request.user.is_superuser:
            return Response({'error': 'Forbidden'}, status=status.HTTP_403_FORBIDDEN)
        
        if pk is None:
            return Response({'error': 'Announcement ID required'}, status=status.HTTP_400_BAD_REQUEST)
            
        try:
            announcement = SystemAnnouncement.objects.get(pk=pk)
            announcement.delete()
            return Response({'status': 'success', 'message': 'Announcement deleted successfully'})
        except SystemAnnouncement.DoesNotExist:
            return Response({'error': 'Announcement not found'}, status=status.HTTP_404_NOT_FOUND)

class AdminDashboardView(views.APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        if request.user.role != 'admin' and not request.user.is_superuser:
            return Response({'error': 'Forbidden'}, status=status.HTTP_403_FORBIDDEN)
        
        total_revenue = Payment.objects.filter(status='success').aggregate(models.Sum('amount'))['amount__sum'] or 0
        total_revenue = float(total_revenue) / 100.0  # Convert from paisa to rupees
        
        total_users = User.objects.count()
        total_merchants = Merchant.objects.count()
        total_vouchers = Voucher.objects.count()
        total_payments = Payment.objects.count()
        
        # Recent activity (mix of payments and vouchers)
        recent_payments = Payment.objects.all().order_by('-id')[:5]
        recent_vouchers = Voucher.objects.all().order_by('-id')[:5]
        
        # Check for expiring memberships (next 7 days) for auto-announcements
        seven_days_later = timezone.now() + timezone.timedelta(days=7)
        expiring_soon = PrimeMembership.objects.filter(expires_at__lte=seven_days_later, expires_at__gte=timezone.now())
        
        expiring_announcements = []
        for m in expiring_soon:
            expiring_announcements.append({
                'action': 'Expiring Soon',
                'details': f"Plan for {m.user.email} expires on {m.expires_at.strftime('%Y-%m-%d')}",
                'timestamp': timezone.now(),
                'admin_name': 'System'
            })

        return Response({
            'stats': {
                'total_revenue': total_revenue,
                'total_users': total_users,
                'total_merchants': total_merchants,
                'total_redemptions': total_vouchers,
                'total_transactions': total_payments,
                'total_prime_users': PrimeMembership.objects.count(),
            },
            'recent_activity': expiring_announcements + [
                {
                    'action': f"Payment Received: ₹{p.amount/100.0}" if p.status == 'success' else f"Payment Pending: ₹{p.amount/100.0}" if p.status == 'pending' else f"Payment Failed: ₹{p.amount/100.0}", 
                    'details': f"User: {p.user.email}", 
                    'timestamp': p.created_at,
                    'admin_name': p.purpose if p.purpose and p.purpose != 'prime_membership' else 'System'
                } for p in recent_payments
            ] + [
                {
                    'action': f"Discount Redeemed: {v.code}", 
                    'details': f"Merchant: {v.merchant_profile.business_name if v.merchant_profile else 'Unknown'}", 
                    'timestamp': v.used_at or v.created_at,
                    'admin_name': v.merchant_profile.business_name if v.merchant_profile else 'System'
                } for v in recent_vouchers
            ]
        })

class MerchantDashboardView(views.APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        try:
            merchant = request.user.merchant_profile
        except:
            return Response({'error': 'Merchant profile not found'}, status=404)
        
        vouchers = Voucher.objects.filter(merchant_profile=merchant).order_by('-id')
        stats_data = vouchers.filter(used_at__isnull=False).aggregate(
            total_rev=models.Sum('bill_amount'),
            total_saved=models.Sum('amount_saved')
        )
        total_transactions = vouchers.filter(used_at__isnull=False).count()
        
        # Return all for history, or at least 50
        recent_vouchers = vouchers[:50]
        
        return Response({
            'stats': {
                'total_revenue': float(stats_data['total_rev'] or 0),
                'total_transactions': total_transactions,
                'total_discount': float(stats_data['total_saved'] or 0),
                'active_offers': 1,
            },
            'transactions': [
                {
                    'id': v.id,
                    'code': v.code,
                    'user_name': v.user.name if v.user else "User",
                    'amount_paid': float(v.bill_amount or 0),
                    'amount_saved': float(v.amount_saved or 0),
                    'discount_percent': v.discount_percent,
                    'timestamp': v.used_at or v.created_at,
                    'status': 'completed' if v.used_at else 'pending'
                } for v in recent_vouchers
            ]
        })


class ChangePasswordView(views.APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        user = request.user
        old_password = request.data.get('old_password')
        new_password = request.data.get('new_password')

        if not old_password or not new_password:
            return Response({'error': 'Both old and new passwords are required'}, status=status.HTTP_400_BAD_REQUEST)

        if not user.check_password(old_password):
            return Response({'error': 'Incorrect old password'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            user.set_password(new_password)
            user.save()
            return Response({'message': 'Password changed successfully'}, status=status.HTTP_200_OK)
        except Exception as e:
            return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)

