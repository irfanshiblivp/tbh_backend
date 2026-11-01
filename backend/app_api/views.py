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
    Referral, ReferralLink, SystemAnnouncement, ReferralPayout, HeroBanner, FreePrimeRequest
)
from .serializers import (
    UserSerializer, CategorySerializer, MerchantSerializer, 
    PrimeMembershipSerializer, PaymentSerializer, ReferralPayoutSerializer,
    ChangePasswordSerializer, VoucherSerializer, AppSettingSerializer, HeroBannerSerializer,
    FreePrimeRequestSerializer
)


from rest_framework import serializers


def validate_image_file(file_obj):
    if not file_obj:
        return
    ext = file_obj.name.split('.')[-1].lower()
    if ext not in ['png', 'jpg', 'jpeg', 'webp', 'heic']:
        raise serializers.ValidationError(f"Invalid image extension: .{ext}. Allowed: png, jpg, jpeg, webp, heic")
    if file_obj.size > 5 * 1024 * 1024:
        raise serializers.ValidationError("Image file size exceeds 5MB limit.")


def sync_uploaded_file(saved_path):
    """
    Syncs/copies an uploaded file to all possible Laravel storage locations that exist
    on local development or production servers to maintain absolute consistency.
    """
    import os
    import shutil
    from django.conf import settings
    from pathlib import Path
    try:
        src = os.path.abspath(os.path.join(settings.MEDIA_ROOT, saved_path))
        
        backend_root = Path(settings.BASE_DIR)
        
        # Candidate storage destination directories
        dest_dirs = [
            # Local layout
            backend_root.parent.parent / 'website code' / 'baronclub' / 'public' / 'storage',
            backend_root.parent.parent / 'website code' / 'public_html' / 'storage',
            backend_root.parent.parent / 'website' / 'baronclub' / 'public' / 'storage',
            backend_root.parent.parent / 'website' / 'public_html' / 'storage',
            # Production layout (absolute path)
            Path('/home/u470165908/baronclub/public/storage'),
            Path('/home/u470165908/public_html/storage'),
            # Production layout (sibling to tbh_backend)
            backend_root.parent / 'baronclub' / 'public' / 'storage',
            backend_root.parent / 'public_html' / 'storage',
            # Production layout (parent-parent sibling layout)
            backend_root.parent.parent / 'baronclub' / 'public' / 'storage',
            backend_root.parent.parent / 'public_html' / 'storage',
        ]
        
        synced = False
        for dest_dir in dest_dirs:
            if dest_dir.exists():
                dst = os.path.abspath(str((dest_dir / saved_path).resolve().as_posix()))
                if src != dst:
                    os.makedirs(os.path.dirname(dst), exist_ok=True)
                    if os.path.exists(src):
                        shutil.copy2(src, dst)
                        print(f"DEBUG SYNC: Copied {src} to {dst}")
                        synced = True
                    else:
                        print(f"DEBUG SYNC: Source file {src} not found!")
                else:
                    print(f"DEBUG SYNC: Source and destination are the same ({src}), skipping.")
                    
        if not synced:
            print("DEBUG SYNC: No alternative sync destinations were found/processed.")
    except Exception as e:
        print(f"DEBUG SYNC ERROR: Failed to sync file: {e}")

def get_google_maps_api_key():
    import os
    # Check environment variable first
    key = os.environ.get('GOOGLE_MAPS_API_KEY')
    if key:
        return key

    # Check potential .env paths
    from pathlib import Path
    base_dir = Path(__file__).resolve().parent.parent
    potential_paths = [
        base_dir.parent.parent / 'website code' / 'baronclub' / '.env',
        base_dir.parent / 'website code' / 'baronclub' / '.env',
        base_dir.parent.parent / 'website' / '.env',
        base_dir.parent / 'website' / '.env',
        base_dir.parent.parent / 'the-baron-club' / '.env',
        base_dir.parent / 'the-baron-club' / '.env',
        base_dir / '.env',
        base_dir.parent / '.env',
    ]
    for p in potential_paths:
        if p.exists():
            try:
                with open(p, 'r') as f:
                    for line in f:
                        if line.strip().startswith('GOOGLE_MAPS_API_KEY='):
                            return line.split('=', 1)[1].strip().strip('"').strip("'")
            except Exception as e:
                print(f"Error reading .env at {p}: {e}")
    return "AIzaSyBgNWuakomNiOKFqBgqB9Wylau8KAILS2M" # fallback to default key if not found

class AppSettingViewSet(viewsets.ModelViewSet):
    queryset = AppSetting.objects.all()
    serializer_class = AppSettingSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]

    def create(self, request, *args, **kwargs):
        if request.user.role != 'admin' and not request.user.is_superuser:
            return Response({'error': 'Forbidden'}, status=status.HTTP_403_FORBIDDEN)
        return super().create(request, *args, **kwargs)

    def update(self, request, *args, **kwargs):
        if request.user.role != 'admin' and not request.user.is_superuser:
            return Response({'error': 'Forbidden'}, status=status.HTTP_403_FORBIDDEN)
        return super().update(request, *args, **kwargs)

    def partial_update(self, request, *args, **kwargs):
        if request.user.role != 'admin' and not request.user.is_superuser:
            return Response({'error': 'Forbidden'}, status=status.HTTP_403_FORBIDDEN)
        return super().partial_update(request, *args, **kwargs)

    def destroy(self, request, *args, **kwargs):
        if request.user.role != 'admin' and not request.user.is_superuser:
            return Response({'error': 'Forbidden'}, status=status.HTTP_403_FORBIDDEN)
        return super().destroy(request, *args, **kwargs)

    def perform_create(self, serializer):
        instance = serializer.save()
        if instance.key and instance.key.startswith('PRIME_PLAN_'):
            try:
                parts = instance.value.split('|')
                old_p = parts[0] if len(parts) > 0 and parts[0] else None
                eff_p = parts[1] if len(parts) > 1 and parts[1] else None
                if old_p:
                    AppSetting.objects.update_or_create(key='prime_amount', defaults={'value': str(old_p)})
                if eff_p:
                    AppSetting.objects.update_or_create(key='prime_effective_amount', defaults={'value': str(eff_p)})
            except Exception as e:
                print(f"Error syncing prime amounts on create: {e}")

    def perform_update(self, serializer):
        instance = serializer.save()
        if instance.key and instance.key.startswith('PRIME_PLAN_'):
            try:
                parts = instance.value.split('|')
                old_p = parts[0] if len(parts) > 0 and parts[0] else None
                eff_p = parts[1] if len(parts) > 1 and parts[1] else None
                if old_p:
                    AppSetting.objects.update_or_create(key='prime_amount', defaults={'value': str(old_p)})
                if eff_p:
                    AppSetting.objects.update_or_create(key='prime_effective_amount', defaults={'value': str(eff_p)})
            except Exception as e:
                print(f"Error syncing prime amounts on update: {e}")

    def list(self, request, *args, **kwargs):
        response = super().list(request, *args, **kwargs)
        key_val = get_google_maps_api_key()
        found = False
        if isinstance(response.data, list):
            prime_eff = None
            prime_amt = None
            prime_plan_items = []
            for item in response.data:
                k = item.get('key')
                if k == 'GOOGLE_MAPS_API_KEY':
                    item['value'] = key_val
                    found = True
                elif k == 'prime_effective_amount':
                    prime_eff = item.get('value')
                elif k == 'prime_amount':
                    prime_amt = item.get('value')
                elif k and str(k).startswith('PRIME_PLAN_'):
                    prime_plan_items.append(item)

            # When prime price was updated from website, reflect it in PRIME_PLAN items
            if prime_eff and prime_plan_items:
                for plan_item in prime_plan_items:
                    parts = plan_item.get('value', '').split('|')
                    old_p = prime_amt or (parts[0] if parts and parts[0] else '9999')
                    benefits = parts[2] if len(parts) > 2 else 'Exclusive Discounts and other offers, Referral Bonus, VIP Treatment'
                    plan_item['value'] = f"{old_p}|{prime_eff}|{benefits}"

            if not found:
                response.data.append({
                    'id': 9999,
                    'key': 'GOOGLE_MAPS_API_KEY',
                    'value': key_val
                })
        return response

    def retrieve(self, request, *args, **kwargs):
        if kwargs.get('pk') == '9999' or kwargs.get('pk') == 'GOOGLE_MAPS_API_KEY':
            return Response({
                'id': 9999,
                'key': 'GOOGLE_MAPS_API_KEY',
                'value': get_google_maps_api_key()
            })
        response = super().retrieve(request, *args, **kwargs)
        if isinstance(response.data, dict) and str(response.data.get('key', '')).startswith('PRIME_PLAN_'):
            prime_eff = AppSetting.objects.filter(key='prime_effective_amount').first()
            prime_amt = AppSetting.objects.filter(key='prime_amount').first()
            if prime_eff and prime_eff.value:
                parts = response.data.get('value', '').split('|')
                old_p = (prime_amt.value if prime_amt and prime_amt.value else (parts[0] if parts and parts[0] else '9999'))
                benefits = parts[2] if len(parts) > 2 else 'Exclusive Discounts and other offers, Referral Bonus, VIP Treatment'
                response.data['value'] = f"{old_p}|{prime_eff.value}|{benefits}"
        return response

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
    throttle_scope = 'payment'

    def post(self, request):
        user = request.user
        amount_in_rupees = request.data.get('amount')
        purpose = request.data.get('purpose', 'prime_membership')
        if purpose:
            purpose = purpose[:50]
            
        if purpose == 'prime_membership':
            # Security: Always determine Prime price server-side from DB settings
            eff_setting = AppSetting.objects.filter(key='prime_effective_amount').first()
            if eff_setting and eff_setting.value.strip():
                try:
                    base_price = float(eff_setting.value.strip())
                except ValueError:
                    base_price = 999.0
            else:
                plan_setting = AppSetting.objects.filter(key__startswith='PRIME_PLAN_').first()
                if plan_setting:
                    parts = plan_setting.value.split('|')
                    base_price = float(parts[1] if len(parts) > 1 and parts[1].strip() else parts[0])
                else:
                    base_price = 999.0
            amount = base_price * 1.18
        else:
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
            return Response({'error': 'Failed to create payment order. Please try again.'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

def credit_referral_reward(user):
    """
    Credits referral bonus to referrer when a referred user acquires Prime membership.
    """
    from decimal import Decimal
    from django.utils import timezone
    referral = Referral.objects.filter(referred=user, reward_paid_at__isnull=True).first()
    if not referral:
        return None
    
    referrer = referral.referrer
    if not referrer:
        return None
        
    if not referrer.referral_code:
        import random
        referrer.referral_code = f"TBC{random.randint(100000, 999999)}"
        referrer.save(update_fields=['referral_code'])
        
    reward_setting = AppSetting.objects.filter(key='referral_reward_amount').first()
    try:
        reward_amount_dec = Decimal(str(reward_setting.value).strip()) if reward_setting and reward_setting.value else Decimal('500.00')
    except Exception:
        reward_amount_dec = Decimal('500.00')
        
    referrer.referral_balance = (referrer.referral_balance or Decimal('0.00')) + reward_amount_dec
    referrer.referral_total_earned = (referrer.referral_total_earned or Decimal('0.00')) + reward_amount_dec
    referrer.save(update_fields=['referral_balance', 'referral_total_earned'])
    
    referral.reward_paid_at = timezone.now()
    referral.reward_amount = reward_amount_dec
    referral.save(update_fields=['reward_paid_at', 'reward_amount'])
    print(f"Awarded referral reward of {reward_amount_dec} to {referrer.email} for {user.email}")
    return reward_amount_dec

class RazorpayVerifyPaymentView(views.APIView):
    permission_classes = [permissions.IsAuthenticated]
    throttle_scope = 'payment'

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
            return Response({'error': 'Payment order not found'}, status=status.HTTP_404_NOT_FOUND)
            
        # Security: Prevent IDOR - ensure payment order belongs to authenticated user
        if payment.user != user:
            return Response({'error': 'Unauthorized payment order'}, status=status.HTTP_403_FORBIDDEN)
            
        # Security: Prevent Replay Attacks - ensure payment is not processed more than once
        if payment.status == 'paid':
            return Response({'status': 'success', 'message': 'Payment already verified and processed'}, status=status.HTTP_200_OK)

        from django.db import transaction
        with transaction.atomic():
            payment.razorpay_payment_id = payment_id
            payment.status = 'paid'
            payment.save()
            
            if payment.purpose == 'prime_membership':
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
            
            # Send notification/email for Prime purchase
            try:
                notify_prime_purchase(user)
            except Exception as fcm_err:
                print(f"Error triggering notifications on Prime purchase: {fcm_err}")
                
            # Dynamically process referral code if provided during Prime purchase
            referral_code = request.data.get('referral_code')
            if referral_code:
                try:
                    raw_code = str(referral_code).strip().upper()
                    referrer = User.objects.filter(
                        models.Q(referral_code__iexact=raw_code) |
                        models.Q(referral_code__iexact=f"TBC{raw_code}") |
                        models.Q(referral_code__iexact=raw_code.replace('TBC', ''))
                    ).first()
                    if not referrer and raw_code.replace('TBC', '').isdigit():
                        referrer = User.objects.filter(customer_number=int(raw_code.replace('TBC', ''))).first()
                    if referrer and referrer != user:
                        if not referrer.referral_code:
                            import random
                            referrer.referral_code = f"TBC{random.randint(100000, 999999)}"
                            referrer.save(update_fields=['referral_code'])
                        if not Referral.objects.filter(referred=user).exists():
                            import random, string
                            link = ReferralLink.objects.filter(user=referrer).first()
                            if not link:
                                link = ReferralLink.objects.create(
                                    user=referrer,
                                    token=''.join(random.choices(string.ascii_letters + string.digits, k=32)),
                                    expires_at=timezone.now() + timezone.timedelta(days=365)
                                )
                            Referral.objects.create(
                                referrer=referrer,
                                referred=user,
                                referral_link=link
                            )
                            print(f"Created dynamic referral record via verify_payment: {referrer.email} referred {user.email}")
                except Exception as e:
                    print(f"Error processing dynamic referral code via verify_payment: {e}")
                
            awarded = credit_referral_reward(user)
            if awarded:
                message = f'Payment verified and Prime membership activated successfully! Referral reward of ₹{awarded} credited.'
            else:
                message = 'Payment verified and Prime membership activated successfully!'
            
        return Response({
            'status': 'success',
            'message': message,
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

    def create(self, request, *args, **kwargs):
        if request.user.role != 'admin' and not request.user.is_superuser:
            return Response({'error': 'Forbidden'}, status=status.HTTP_403_FORBIDDEN)
        return super().create(request, *args, **kwargs)

    def update(self, request, *args, **kwargs):
        if request.user.role != 'admin' and not request.user.is_superuser:
            return Response({'error': 'Forbidden'}, status=status.HTTP_403_FORBIDDEN)
        return super().update(request, *args, **kwargs)

    def partial_update(self, request, *args, **kwargs):
        if request.user.role != 'admin' and not request.user.is_superuser:
            return Response({'error': 'Forbidden'}, status=status.HTTP_403_FORBIDDEN)
        return super().partial_update(request, *args, **kwargs)

    def destroy(self, request, *args, **kwargs):
        if request.user.role != 'admin' and not request.user.is_superuser:
            return Response({'error': 'Forbidden'}, status=status.HTTP_403_FORBIDDEN)
        return super().destroy(request, *args, **kwargs)

class MerchantViewSet(viewsets.ModelViewSet):
    queryset = Merchant.objects.all()
    serializer_class = MerchantSerializer
    parser_classes = (MultiPartParser, FormParser, JSONParser)

    def create(self, request, *args, **kwargs):
        if request.user.role not in ('admin', 'staff') and not getattr(request.user, 'is_superuser', False):
            return Response({'error': 'Forbidden. Only administrators or staff can register merchants.'}, status=status.HTTP_403_FORBIDDEN)
        return super().create(request, *args, **kwargs)

    def update(self, request, *args, **kwargs):
        instance = self.get_object()
        if request.user.role != 'admin' and not request.user.is_superuser and instance.user != request.user:
            return Response({'error': 'Forbidden'}, status=status.HTTP_403_FORBIDDEN)
        return super().update(request, *args, **kwargs)

    def partial_update(self, request, *args, **kwargs):
        instance = self.get_object()
        if request.user.role != 'admin' and not request.user.is_superuser and instance.user != request.user:
            return Response({'error': 'Forbidden'}, status=status.HTTP_403_FORBIDDEN)
        return super().partial_update(request, *args, **kwargs)

    def destroy(self, request, *args, **kwargs):
        instance = self.get_object()
        if request.user.role != 'admin' and not request.user.is_superuser and instance.user != request.user:
            return Response({'error': 'Forbidden'}, status=status.HTTP_403_FORBIDDEN)
        return super().destroy(request, *args, **kwargs)

    def perform_update(self, serializer):
        if self.request.user.role != 'admin' and not getattr(self.request.user, 'is_superuser', False):
            if 'discount_percent' in serializer.validated_data:
                serializer.validated_data.pop('discount_percent')

        # Handle file uploads manually if they are in request.FILES
        instance = serializer.save()
        updated = False
        
        from django.core.files.storage import default_storage
        from django.core.files.base import ContentFile
        import uuid

        if 'logo' in self.request.FILES:
            image = self.request.FILES['logo']
            validate_image_file(image)
            path = default_storage.save(f"merchant-logos/{uuid.uuid4()}.{image.name.split('.')[-1]}", ContentFile(image.read()))
            instance.logo = path
            updated = True
            sync_uploaded_file(path)
            
        if 'profile_photo' in self.request.FILES: # Compatibility with frontend param name
            image = self.request.FILES['profile_photo']
            validate_image_file(image)
            path = default_storage.save(f"merchant-logos/{uuid.uuid4()}.{image.name.split('.')[-1]}", ContentFile(image.read()))
            instance.logo = path
            updated = True
            sync_uploaded_file(path)

        if 'card_image' in self.request.FILES:
            image = self.request.FILES['card_image']
            validate_image_file(image)
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
                    cursor.execute('DELETE FROM merchant_profiles WHERE id = %s', [instance.id])
                    if user:
                        cursor.execute('DELETE FROM users WHERE id = %s', [user.id])
            except Exception as raw_err:
                print(f"Fallback raw deletion also failed: {raw_err}")

    def get_permissions(self):
        if self.action in ['list', 'retrieve']:
            return [permissions.AllowAny()]
        return [permissions.IsAuthenticated()]

    def get_queryset(self):
        # Auto-heal any merchant profiles that have NULL or zero coordinates
        try:
            from decimal import Decimal
            null_coords = Merchant.objects.filter(
                models.Q(latitude__isnull=True) | 
                models.Q(longitude__isnull=True) |
                models.Q(latitude=0) |
                models.Q(longitude=0)
            )
            if null_coords.exists():
                print(f"DEBUG MAP HEAL: Found {null_coords.count()} merchants with NULL/zero coordinates. Auto-assigning defaults...")
                null_coords.update(
                    latitude=Decimal('9.9857409'),
                    longitude=Decimal('76.3096248')
                )
        except Exception as e:
            print(f"DEBUG MAP HEAL ERROR: {e}")

        user = self.request.user
        if self.action == 'restore':
            queryset = Merchant.objects.all()
        elif user.is_authenticated and (user.role == 'admin' or user.is_superuser):
            queryset = Merchant.objects.filter(deleted_at__isnull=True)
        else:
            queryset = Merchant.objects.filter(status='active', deleted_at__isnull=True)
            
        category = self.request.query_params.get('category')
        if category and category.strip() and category.strip().lower() != 'all':
            cat_clean = category.strip()
            queryset = queryset.filter(
                models.Q(category__iexact=cat_clean) |
                models.Q(category__iexact=cat_clean.replace('-', ' ')) |
                models.Q(category__iexact=cat_clean.replace('-', ' & ')) |
                models.Q(category__icontains=cat_clean)
            )
        return queryset

    @action(detail=True, methods=['post'])
    def restore(self, request, pk=None):
        if self.request.user.role != 'admin' and not self.request.user.is_superuser:
            return Response({'error': 'Forbidden'}, status=status.HTTP_403_FORBIDDEN)
            
        merchant = self.get_object()
        merchant.status = 'active'
        merchant.deleted_at = None
        merchant.save()
        return Response({'status': 'Merchant restored'})

    @action(detail=True, methods=['post'])
    def approve(self, request, pk=None):
        if self.request.user.role != 'admin' and not self.request.user.is_superuser:
            return Response({'error': 'Forbidden'}, status=status.HTTP_403_FORBIDDEN)
            
        merchant = self.get_object()
        with transaction.atomic():
            merchant.status = 'active'
            merchant.save()
            user = merchant.user
            if user:
                user.status = 'active'
                user.save()
        return Response({'status': 'Merchant approved successfully'})

    @action(detail=True, methods=['post'])
    def reject(self, request, pk=None):
        if self.request.user.role != 'admin' and not self.request.user.is_superuser:
            return Response({'error': 'Forbidden'}, status=status.HTTP_403_FORBIDDEN)
            
        merchant = self.get_object()
        with transaction.atomic():
            merchant.status = 'rejected'
            merchant.save()
            user = merchant.user
            if user:
                user.status = 'inactive'
                user.save()
        return Response({'status': 'Merchant rejected successfully'})

    @action(detail=False, methods=['get'])
    def pending(self, request):
        if self.request.user.role != 'admin' and not self.request.user.is_superuser:
            return Response({'error': 'Forbidden'}, status=status.HTTP_403_FORBIDDEN)
            
        queryset = Merchant.objects.filter(status='pending').order_by('-created_at')
        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    def verify_user(self, request):
        query = request.query_params.get('query')
        if not query:
            return Response({'error': 'Query parameter required'}, status=400)
            
        query = str(query).strip()
        user = User.objects.filter(
            models.Q(email__iexact=query) |
            models.Q(phone=query) |
            models.Q(referral_code__iexact=query) |
            models.Q(referral_code__iexact=f"TBC{query}")
        ).first()
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
        payment_method = request.data.get('payment_method', 'CASH').upper()
        if payment_method not in ['ONLINE', 'CASH']:
            payment_method = 'CASH'
        
        try:
            merchant = Merchant.objects.get(user=merchant_user)
            user = User.objects.get(id=user_id)
        except:
            return Response({'error': 'Invalid user or merchant'}, status=400)

        # Enforce active Prime membership
        from django.utils import timezone
        is_prime = PrimeMembership.objects.filter(user=user, expires_at__gt=timezone.now()).exists()
        if not is_prime:
            return Response({'error': 'Active Prime membership is required to redeem discounts.'}, status=status.HTTP_400_BAD_REQUEST)

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
            expires_at=timezone.now(),
            payment_method=payment_method
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
            
        payment_method = request.data.get('payment_method', 'ONLINE').upper()
        if payment_method not in ['ONLINE', 'CASH']:
            payment_method = 'ONLINE'

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
            expires_at=timezone.now(),
            payment_method=payment_method
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

    def create(self, request, *args, **kwargs):
        if request.user.role != 'admin' and not request.user.is_superuser:
            return Response({'error': 'Forbidden. Please request withdrawals via the profile endpoint.'}, status=status.HTTP_403_FORBIDDEN)
        return super().create(request, *args, **kwargs)

    def update(self, request, *args, **kwargs):
        if request.user.role != 'admin' and not request.user.is_superuser:
            return Response({'error': 'Forbidden'}, status=status.HTTP_403_FORBIDDEN)
        return super().update(request, *args, **kwargs)

    def partial_update(self, request, *args, **kwargs):
        if request.user.role != 'admin' and not request.user.is_superuser:
            return Response({'error': 'Forbidden'}, status=status.HTTP_403_FORBIDDEN)
        return super().partial_update(request, *args, **kwargs)

    def destroy(self, request, *args, **kwargs):
        if request.user.role != 'admin' and not request.user.is_superuser:
            return Response({'error': 'Forbidden'}, status=status.HTTP_403_FORBIDDEN)
        return super().destroy(request, *args, **kwargs)

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
            user.referral_balance = user.referral_balance + payout.amount
            user.save()
            
        return Response({'status': 'declined', 'remark': remark})

class UserViewSet(viewsets.ModelViewSet):
    queryset = User.objects.all()
    serializer_class = UserSerializer
    permission_classes = [permissions.IsAuthenticated]
    parser_classes = (MultiPartParser, FormParser, JSONParser)

    def get_queryset(self):
        if self.request.user.role == 'admin' or self.request.user.is_superuser:
            return User.objects.filter(deleted_at__isnull=True).order_by('-created_at')
        return User.objects.filter(id=self.request.user.id, deleted_at__isnull=True)

    def create(self, request, *args, **kwargs):
        return Response({'error': 'Direct creation not allowed. Use the registration endpoint.'}, status=status.HTTP_405_METHOD_NOT_ALLOWED)

    def update(self, request, *args, **kwargs):
        instance = self.get_object()
        if request.user.role != 'admin' and not getattr(request.user, 'is_superuser', False) and instance != request.user:
            return Response({'error': 'Forbidden'}, status=status.HTTP_403_FORBIDDEN)
        return super().update(request, *args, **kwargs)

    def partial_update(self, request, *args, **kwargs):
        instance = self.get_object()
        if request.user.role != 'admin' and not getattr(request.user, 'is_superuser', False) and instance != request.user:
            return Response({'error': 'Forbidden'}, status=status.HTTP_403_FORBIDDEN)
        return super().partial_update(request, *args, **kwargs)

    def perform_update(self, serializer):
        if self.request.user.role != 'admin' and not getattr(self.request.user, 'is_superuser', False):
            for field in ('role', 'status', 'referral_balance', 'referral_total_earned', 'customer_number'):
                serializer.validated_data.pop(field, None)
        serializer.save()

    def list(self, request, *args, **kwargs):
        queryset = self.filter_queryset(self.get_queryset())
        users_list = list(queryset)
        user_ids = [u.id for u in users_list]

        now = timezone.now()
        memberships = PrimeMembership.objects.filter(user_id__in=user_ids).order_by('-expires_at')
        prime_map = {}
        for m in memberships:
            if m.user_id not in prime_map:
                prime_map[m.user_id] = m

        # Auto-credit any pending referral rewards if the referred user has active Prime
        try:
            pending_refs = Referral.objects.filter(referred_id__in=user_ids, reward_paid_at__isnull=True).select_related('referred', 'referrer')
            for pref in pending_refs:
                if PrimeMembership.objects.filter(user=pref.referred, expires_at__gt=now).exists():
                    credit_referral_reward(pref.referred)
        except Exception as e:
            print(f"Error checking pending referral rewards in UserViewSet: {e}")

        referred_by_map = {}
        for ref in Referral.objects.filter(referred_id__in=user_ids).select_related('referrer'):
            code = (ref.referrer.referral_code if (ref.referrer and ref.referrer.referral_code) else (f"TBC{ref.referrer.id}" if ref.referrer else "TBC"))
            referred_by_map[ref.referred_id] = code

        prime_user_ids = set(PrimeMembership.objects.filter(expires_at__gt=now).values_list('user_id', flat=True))
        referrals_made = Referral.objects.filter(referrer_id__in=user_ids).values_list('referrer_id', 'referred_id')
        ref_count_map = {}
        for referrer_id, referred_id in referrals_made:
            if referred_id in prime_user_ids:
                ref_count_map[referrer_id] = ref_count_map.get(referrer_id, 0) + 1

        free_req_map = {}
        for req in FreePrimeRequest.objects.filter(user_id__in=user_ids).order_by('-created_at'):
            if req.user_id not in free_req_map:
                free_req_map[req.user_id] = req.status

        context = self.get_serializer_context()
        context.update({
            'prime_map': prime_map,
            'referred_by_map': referred_by_map,
            'ref_count_map': ref_count_map,
            'free_req_map': free_req_map,
            'now': now,
        })

        serializer = self.get_serializer(users_list, many=True, context=context)
        return Response(serializer.data)

    @action(detail=False, methods=['post'])
    def admin_create_staff(self, request):
        if self.request.user.role != 'admin' and not self.request.user.is_superuser:
            return Response({'error': 'Forbidden'}, status=status.HTTP_403_FORBIDDEN)
        
        data = request.data
        email = data.get('email', '').strip().lower()
        password = data.get('password')
        name = data.get('name', data.get('username', '')).strip()
        role = data.get('role', 'staff').lower()
        
        if not email or not password or not name:
            return Response({'error': 'Name, email, and password are required'}, status=status.HTTP_400_BAD_REQUEST)
            
        if len(password) < 8:
            return Response({'error': 'The password field must be at least 8 characters.'}, status=status.HTTP_400_BAD_REQUEST)
            
        if User.objects.filter(email__iexact=email).exists():
            return Response({'error': 'A user with this email already exists'}, status=status.HTTP_400_BAD_REQUEST)
            
        try:
            user = User.objects.create_user(
                email=email,
                password=password,
                name=name,
                role=role,
                email_verified_at=timezone.now(),
                status='active'
            )
            
            # Send welcome email containing login credentials
            send_welcome_email(user, password)
            
            return Response(UserSerializer(user).data, status=status.HTTP_201_CREATED)
        except Exception as e:
            print(f"DEBUG create_user error: {e}")
            return Response({'error': 'Failed to create user. Please check your inputs and try again.'}, status=status.HTTP_400_BAD_REQUEST)

    @action(detail=False, methods=['post'])
    def admin_create_merchant(self, request):
        if self.request.user.role not in ('admin', 'staff') and not self.request.user.is_superuser:
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

            email = data.get('email', '').strip().lower()
            phone = data.get('phone')
            
            if User.objects.filter(email__iexact=email).exists():
                return Response({'error': 'A user with this email already exists'}, status=status.HTTP_400_BAD_REQUEST)
                
            if User.objects.filter(phone=phone).exists():
                return Response({'error': 'A user with this phone number already exists'}, status=status.HTTP_400_BAD_REQUEST)

            from django.db import transaction
            from decimal import Decimal, InvalidOperation
            
            lat_val = data.get('latitude')
            lng_val = data.get('longitude')
            
            try:
                latitude = Decimal(str(lat_val)) if lat_val and str(lat_val).strip() not in ('', 'None', 'null') else Decimal('9.9857409')
            except (InvalidOperation, ValueError):
                latitude = Decimal('9.9857409')
                
            try:
                longitude = Decimal(str(lng_val)) if lng_val and str(lng_val).strip() not in ('', 'None', 'null') else Decimal('76.3096248')
            except (InvalidOperation, ValueError):
                longitude = Decimal('76.3096248')

            with transaction.atomic():
                is_staff_creator = request.user.role == 'staff'
                init_status = 'pending' if is_staff_creator else 'active'
                
                # 1. Create the User
                from django.utils import timezone
                user = User.objects.create_user(
                    email=email,
                    password=data.get('password'),
                    name=data.get('business_name'),
                    phone=phone,
                    role='merchant',
                    status=init_status,
                    email_verified_at=timezone.now() # Auto-verify for admin-created users to allow website login
                )
                
                # 2. Create the Merchant Profile
                merchant = Merchant.objects.create(
                    user=user,
                    business_name=data.get('business_name'),
                    category=data.get('category'),
                    address=data.get('address'),
                    description=data.get('description'),
                    status=init_status,
                    discount_percent=data.get('discount_percent', 50),
                    discount_type=data.get('discount_type', 'percentage'),
                    latitude=latitude,
                    longitude=longitude,
                    added_by=request.user
                )

                # 3. Handle File Upload (Image)
                if 'card_image' in request.FILES:
                    from django.core.files.storage import default_storage
                    from django.core.files.base import ContentFile
                    import uuid
                    
                    image = request.FILES['card_image']
                    validate_image_file(image)
                    ext = image.name.split('.')[-1]
                    filename = f"merchant-cards/{uuid.uuid4()}.{ext}"
                    path = default_storage.save(filename, ContentFile(image.read()))
                    sync_uploaded_file(path)
                    
                    # Store only in card_image as requested
                    merchant.card_image = path
                    merchant.save()
            
            # Send welcome email containing login credentials
            send_welcome_email(user, data.get('password'))
            
            return Response({
                'user': UserSerializer(user).data,
                'merchant': MerchantSerializer(merchant).data
            }, status=status.HTTP_201_CREATED)
        except Exception as e:
            print(f"DEBUG admin_create_merchant ERROR: {e}")
            return Response({'error': 'Failed to create merchant. Please check your inputs and try again.'}, status=status.HTTP_400_BAD_REQUEST)

    @action(detail=True, methods=['post'])
    def grant_prime(self, request, pk=None):
        if self.request.user.role != 'admin' and not self.request.user.is_superuser:
            return Response({'error': 'Forbidden'}, status=status.HTTP_403_FORBIDDEN)
            
        user = self.get_object()
        PrimeMembership.objects.create(
            user=user,
            source='admin',
            starts_at=timezone.now(),
            expires_at=timezone.now() + timezone.timedelta(days=365)
        )
        credit_referral_reward(user)
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
        # Security: Never permit simulated purchase bypass in production unless invoked by admin
        if not getattr(settings, 'DEBUG', False) and request.user.role != 'admin' and not getattr(request.user, 'is_superuser', False):
            return Response({'error': 'Simulated purchases are strictly disabled in production.'}, status=status.HTTP_403_FORBIDDEN)
            
        user = request.user
        
        # 1. Create the membership
        PrimeMembership.objects.create(
            user=user,
            source='payment',
            starts_at=timezone.now(),
            expires_at=timezone.now() + timezone.timedelta(days=365)
        )
        
        # Send notification/email for Prime purchase
        try:
            notify_prime_purchase(user)
        except Exception as fcm_err:
            print(f"Error triggering notifications on fake Prime purchase: {fcm_err}")
        
        # Dynamically process referral code if provided during Prime purchase
        referral_code = request.data.get('referral_code')
        if referral_code:
            try:
                raw_code = str(referral_code).strip().upper()
                referrer = User.objects.filter(
                    models.Q(referral_code__iexact=raw_code) |
                    models.Q(referral_code__iexact=f"TBC{raw_code}") |
                    models.Q(referral_code__iexact=raw_code.replace('TBC', ''))
                ).first()
                if referrer and referrer != user:
                    if not Referral.objects.filter(referred=user).exists():
                        import random, string
                        link = ReferralLink.objects.filter(user=referrer).first()
                        if not link:
                            link = ReferralLink.objects.create(
                                user=referrer,
                                token=''.join(random.choices(string.ascii_letters + string.digits, k=32)),
                                expires_at=timezone.now() + timezone.timedelta(days=365)
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
        credit_referral_reward(user)
            
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
            print(f"DEBUG delete_user error: {e}")
            return Response({'error': 'Failed to delete user account. Please try again.'}, status=status.HTTP_400_BAD_REQUEST)

class LoginView(views.APIView):
    permission_classes = [permissions.AllowAny]
    throttle_scope = 'auth_sensitive'

    def post(self, request):
        # Support both email, username, or phone label for backward compatibility in UI
        email = (request.data.get('email') or request.data.get('username', '')).strip().lower()
        password = request.data.get('password')
        
        if not email or not password:
            return Response({'error': 'Please enter both email and password'}, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            # Match by email or phone (including 10-digit variation)
            raw_input = email
            digits = ''.join(c for c in raw_input if c.isdigit())
            user_filter = models.Q(email__iexact=raw_input) | models.Q(phone=raw_input)
            if len(digits) >= 10:
                last10 = digits[-10:]
                user_filter |= models.Q(phone__endswith=last10) | models.Q(phone=last10) | models.Q(phone=f"+91{last10}")
            
            db_user = User.objects.filter(user_filter).first()
            if not db_user:
                return Response({'error': 'Email or mobile number is not registered'}, status=status.HTTP_401_UNAUTHORIZED)
            if db_user.status == 'inactive':
                return Response({'error': 'Your account has been blocked by the administrator.'}, status=status.HTTP_403_FORBIDDEN)
            
            # Check password
            match = db_user.check_password(password)
            if not match and db_user.password and db_user.password.startswith(('$2y$', '$2b$', '$2a$')):
                try:
                    import bcrypt
                    verify_hash = ('$2b$' + db_user.password[4:]) if db_user.password.startswith(('$2y$', '$2a$')) else db_user.password
                    match = bcrypt.checkpw(password.encode('utf-8'), verify_hash.encode('utf-8'))
                except Exception:
                    match = False
            
            if not match:
                return Response({'error': 'Incorrect password'}, status=status.HTTP_401_UNAUTHORIZED)
        except Exception as e:
            return Response({'error': 'Incorrect password'}, status=status.HTTP_401_UNAUTHORIZED)
            
        user = authenticate(username=db_user.email, password=password) or db_user
        if user:
            refresh = RefreshToken.for_user(user)
            return Response({
                'refresh': str(refresh),
                'access': str(refresh.access_token),
                'user': UserSerializer(user).data
            })
        
        return Response({'error': 'Incorrect password'}, status=status.HTTP_401_UNAUTHORIZED)

import os
from django.conf import settings
import firebase_admin
from firebase_admin import credentials, messaging

# Initialize Firebase Admin SDK using Service Account credentials JSON
cred_path = getattr(settings, 'FIREBASE_CREDENTIALS_PATH', None)
if cred_path and os.path.exists(cred_path):
    try:
        if not firebase_admin._apps:
            cred = credentials.Certificate(cred_path)
            firebase_admin.initialize_app(cred)
            print(f"FCM Info: Firebase Admin initialized successfully using credentials at {cred_path}")
    except Exception as init_err:
        print(f"FCM Error: Failed to initialize Firebase Admin SDK: {init_err}")
else:
    print(f"FCM Warning: FIREBASE_CREDENTIALS_PATH ({cred_path}) is not configured or JSON file not found. Push notifications will run in mock mode.")


def send_push_notification(topic, title, message):
    """
    Sends a push notification to a Firebase Cloud Messaging topic asynchronously using FCM HTTP v1.
    """
    import threading
    def run_push():
        if not firebase_admin._apps:
            print("FCM Warning: Firebase Admin is not initialized. Push notification skipped.")
            return
            
        try:
            msg = messaging.Message(
                notification=messaging.Notification(
                    title=title,
                    body=message
                ),
                topic=topic
            )
            response = messaging.send(msg)
            print(f"FCM Info: Sent push to topic {topic} successfully via HTTP v1. Response ID: {response}")
        except Exception as e:
            print(f"FCM Error: Failed to send push to topic {topic} via HTTP v1: {e}")
            
    threading.Thread(target=run_push, daemon=True).start()

from django.core.mail import get_connection, EmailMultiAlternatives

def send_async_email_with_fallback(subject, text_content, to_email, html_message=None):
    """
    Spawns a separate daemon thread to send the email asynchronously.
    This prevents Passenger WSGI thread freezing/killing, avoids app timeout,
    supports shared-hosting environment limitations (no subprocess spawning),
    and handles SMTP delivery reliably with failover fallbacks.
    """
    import threading
    
    def run_email_send():
        from django.conf import settings
        from django.core.mail import get_connection, EmailMultiAlternatives
        
        # 1. Try Laravel REST API first
        try:
            print(f"REST API Helper (Thread): Attempting to send email to {to_email} via REST API...")
            import requests
            api_url = getattr(settings, 'EMAIL_REST_API_URL', 'https://thebaronclub.com/api/send-email')
            api_token = getattr(settings, 'EMAIL_REST_API_TOKEN', 'shared_secret_token_12345')

            payload = {
                'to': to_email,
                'subject': subject,
                'text': text_content,
                'html': html_message,
                'api_token': api_token
            }

            response = requests.post(api_url, json=payload, timeout=12, verify=False)
            if response.status_code == 200:
                print("REST API Helper (Thread): Email sent successfully via REST API.")
                return
            else:
                print(f"REST API Helper (Thread): Failed via REST API (status code {response.status_code}): {response.text}")
        except Exception as e:
            print(f"REST API Helper (Thread): REST API request failed: {e}")

        # 2. Try Port 465 (SSL) fallback
        try:
            print(f"SMTP Helper (Thread): Attempting to send email to {to_email} via Port 465 (SSL)...")
            connection = get_connection(
                host=settings.EMAIL_HOST,
                port=settings.EMAIL_PORT,
                username=settings.EMAIL_HOST_USER,
                password=settings.EMAIL_HOST_PASSWORD,
                use_ssl=settings.EMAIL_USE_SSL,
                use_tls=settings.EMAIL_USE_TLS,
                timeout=10,
            )
            email = EmailMultiAlternatives(
                subject, text_content, settings.DEFAULT_FROM_EMAIL, [to_email], connection=connection
            )
            if html_message:
                email.attach_alternative(html_message, "text/html")
            email.send()
            print("SMTP Helper (Thread): Email sent successfully via Port 465 (SSL).")
            return
        except Exception as e:
            print(f"SMTP Helper (Thread): Failed via Port 465 (SSL): {e}")

        # 3. Fallback to Port 587 (TLS)
        try:
            print(f"SMTP Helper (Thread): Attempting fallback to Port 587 (TLS)...")
            connection = get_connection(
                host=settings.EMAIL_HOST,
                port=587,
                username=settings.EMAIL_HOST_USER,
                password=settings.EMAIL_HOST_PASSWORD,
                use_ssl=False,
                use_tls=True,
                timeout=15,
            )
            email = EmailMultiAlternatives(
                subject, text_content, settings.DEFAULT_FROM_EMAIL, [to_email], connection=connection
            )
            if html_message:
                email.attach_alternative(html_message, "text/html")
            email.send()
            print("SMTP Helper (Thread): Email sent successfully via Port 587 (TLS) fallback.")
        except Exception as e2:
            print(f"SMTP Helper (Thread): Fallback to Port 587 (TLS) also failed: {e2}")

    try:
        t = threading.Thread(target=run_email_send)
        t.daemon = True
        t.start()
        print(f"SMTP: Started background thread to send email to {to_email}")
        return True
    except Exception as e:
        print(f"SMTP ERROR: Failed to start background thread: {e}")
        return False


def notify_prime_purchase(user):
    """
    Sends an email notification and a push notification to admins when a user purchases Prime.
    """
    from django.utils import timezone
    subject = f"Prime Purchase: {user.name or user.email}"
    text_content = (
        f"A customer has purchased a Prime Membership.\n\n"
        f"Customer Details:\n"
        f"- Name: {user.name}\n"
        f"- Email: {user.email}\n"
        f"- Phone: {user.phone}\n"
        f"- Time: {timezone.now()}"
    )
    # Send email
    send_async_email_with_fallback(
        subject=subject,
        text_content=text_content,
        to_email="loremelevate@gmail.com"
    )
    # Send push notification to admins
    send_push_notification(
        topic="admin",
        title="New Prime Purchase",
        message=f"{user.name or user.email} has purchased Prime membership!"
    )


def send_verification_email(user):
    subject = 'Verify your email - The Baron Club'
    uid = urlsafe_base64_encode(force_bytes(user.pk))
    token = default_token_generator.make_token(user)
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
    send_async_email_with_fallback(
        subject,
        'Please verify your email address.',
        user.email,
        html_message=html_message
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
    send_async_email_with_fallback(
        subject,
        f'Your verification code is {otp}',
        user.email,
        html_message=html_message
    )

def send_welcome_email(user, password):
    """
    Disabled welcome emails to prevent sending sensitive credential data (like passwords) via email.
    """
    print(f"DEBUG: Welcome email to {user.email} (Role: {user.role}, Password: {password}) was requested but skipped for security.")
    pass

class SignupView(views.APIView):
    permission_classes = [permissions.AllowAny]
    throttle_scope = 'auth_sensitive'

    def post(self, request):
        data = request.data
        name = data.get('name')
        email = data.get('email', '').strip().lower()
        password = data.get('password')
        phone = data.get('phone', '').strip()
        role = data.get('role', 'customer').lower()
        
        # Security: Prevent privilege escalation via public signup
        if role not in ('customer', 'merchant'):
            role = 'customer'
        
        if not name or not email or not password:
            return Response({'error': 'Name, Email and Password are required'}, status=status.HTTP_400_BAD_REQUEST)
        
        if not phone:
            return Response({'error': 'Phone number is required'}, status=status.HTTP_400_BAD_REQUEST)
        
        # Basic phone validation - must have at least 10 digits
        digits_only = ''.join(c for c in phone if c.isdigit())
        if len(digits_only) < 10:
            return Response({'error': 'Please enter a valid phone number (at least 10 digits)'}, status=status.HTTP_400_BAD_REQUEST)
            
        if len(password) < 8:
            return Response({'error': 'The password field must be at least 8 characters.'}, status=status.HTTP_400_BAD_REQUEST)
            
        if User.objects.filter(email__iexact=email).exists():
            return Response({'error': 'A user with this email already exists'}, status=status.HTTP_400_BAD_REQUEST)
            
        phone_query = models.Q(phone=phone)
        if len(digits_only) >= 10:
            last10 = digits_only[-10:]
            phone_query |= models.Q(phone__endswith=last10) | models.Q(phone=last10) | models.Q(phone=f"+91{last10}")
        if User.objects.filter(phone_query).exists():
            return Response({'error': 'This mobile number is already registered. Please log in or use another number.'}, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            user = User.objects.create_user(
                email=email,
                password=password,
                name=name,
                role=role,
                phone=phone if phone else None,
                status='active',
                email_verified_at=timezone.now() if role == 'merchant' else None,
                state=data.get('state')
            )
        except Exception as create_err:
            err_str = str(create_err).lower()
            if 'phone' in err_str or 'duplicate' in err_str:
                return Response({'error': 'This mobile number is already registered. Please log in or use another number.'}, status=status.HTTP_400_BAD_REQUEST)
            elif 'email' in err_str:
                return Response({'error': 'A user with this email already exists'}, status=status.HTTP_400_BAD_REQUEST)
            raise create_err

        # Handle Referral Code
        referral_code = data.get('referral_code')
        if referral_code and role == 'customer':
            try:
                raw_code = str(referral_code).strip().upper()
                referrer = User.objects.filter(
                    models.Q(referral_code__iexact=raw_code) |
                    models.Q(referral_code__iexact=f"TBC{raw_code}") |
                    models.Q(referral_code__iexact=raw_code.replace('TBC', ''))
                ).first()
                if not referrer and raw_code.replace('TBC', '').isdigit():
                    referrer = User.objects.filter(customer_number=int(raw_code.replace('TBC', ''))).first()
                if referrer and referrer != user:
                    if not referrer.referral_code:
                        import random
                        referrer.referral_code = f"TBC{random.randint(100000, 999999)}"
                        referrer.save(update_fields=['referral_code'])
                    # Find or create a referral link for the referrer
                    link = ReferralLink.objects.filter(user=referrer).first()
                    if not link:
                        link = ReferralLink.objects.create(
                            user=referrer,
                            token=''.join(random.choices(string.ascii_letters + string.digits, k=32)),
                            expires_at=timezone.now() + timezone.timedelta(days=365)
                        )
                    
                    Referral.objects.create(
                        referrer=referrer,
                        referred=user,
                        referral_link=link
                    )
                    print(f"Created referral record: {referrer.email} referred {user.email}")
                    if PrimeMembership.objects.filter(user=user, expires_at__gt=timezone.now()).exists():
                        credit_referral_reward(user)
            except Exception as e:
                print(f"Error processing referral code: {e}")
        
        if role == 'merchant':
            from decimal import Decimal, InvalidOperation
            lat_val = data.get('latitude')
            lng_val = data.get('longitude')
            try:
                latitude = Decimal(str(lat_val)) if lat_val and str(lat_val).strip() not in ('', 'None', 'null') else Decimal('9.9857409')
            except (InvalidOperation, ValueError):
                latitude = Decimal('9.9857409')
                
            try:
                longitude = Decimal(str(lng_val)) if lng_val and str(lng_val).strip() not in ('', 'None', 'null') else Decimal('76.3096248')
            except (InvalidOperation, ValueError):
                longitude = Decimal('76.3096248')

            Merchant.objects.create(
                user=user,
                business_name=data.get('business_name', name + "'s Business"),
                address=data.get('address', ''),
                status='active',
                discount_percent=50,
                latitude=latitude,
                longitude=longitude
            )
        
        try:
            # Generate OTP and send via Hostinger
            otp = ''.join(random.choices(string.digits, k=6))
            cache_key = f"otp_{user.email}"
            cache.set(cache_key, otp, 900) # 15 minutes
            
            expiry_str = (timezone.now() + timezone.timedelta(minutes=15)).strftime("%I:%M %p")
            print(f"DEBUG: Generated signup OTP {otp} for user {user.email}")
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
    throttle_scope = 'otp'

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
            print(f"Error resending OTP email for {user.email}: {e}")
            return Response({'error': 'Failed to send OTP email. Please try again later.'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

class VerifyOTPView(views.APIView):
    permission_classes = [permissions.IsAuthenticated]
    throttle_scope = 'otp'

    def post(self, request):
        user = request.user
        otp_received = request.data.get('otp')
        
        if not otp_received:
            return Response({'error': 'Please enter the 6-digit OTP code.'}, status=status.HTTP_400_BAD_REQUEST)
            
        cache_key = f"otp_{user.email}"
        cached_otp = cache.get(cache_key)
        
        # Test domain bypass is strictly allowed only when DEBUG is True
        is_test_domain = getattr(settings, 'DEBUG', False) and any(user.email.endswith(dom) for dom in ['@4nly.com', '@test.com', '@example.com'])
        if (cached_otp and str(cached_otp) == str(otp_received)) or (is_test_domain and str(otp_received) == '123456'):
            user.email_verified_at = timezone.now()
            user.save()
            cache.delete(cache_key)
            return Response({
                'message': 'Email verified successfully',
                'user': UserSerializer(user).data
            })
        else:
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
    throttle_scope = 'auth_sensitive'

    def post(self, request):
        email = request.data.get('email')
        if not email:
            return Response({'error': 'Email is required'}, status=status.HTTP_400_BAD_REQUEST)
            
        try:
            email_clean = str(email).strip().lower()
            user = User.objects.get(email__iexact=email_clean)
            otp = str(random.randint(100000, 999999))
            cache.set(f'otp_{email_clean}', otp, timeout=600) # 10 minutes
            
            expiry_str = (timezone.now() + timezone.timedelta(minutes=10)).strftime("%I:%M %p")
            send_otp_email(user, otp, expiry_str)
            return Response({'message': 'If an account exists with this email, an OTP has been sent.'}, status=status.HTTP_200_OK)
        except User.DoesNotExist:
            # Prevent account enumeration: return identical message
            return Response({'message': 'If an account exists with this email, an OTP has been sent.'}, status=status.HTTP_200_OK)
        except Exception as e:
            print(f"DEBUG: Forgot Password Error: {str(e)}")
            return Response({'error': 'Failed to send password reset email. Please try again later.'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

class ResetPasswordView(views.APIView):
    permission_classes = [permissions.AllowAny]
    throttle_scope = 'auth_sensitive'

    def post(self, request):
        email = request.data.get('email')
        otp = request.data.get('otp')
        password = request.data.get('password')
        
        if not email or not otp or not password:
            return Response({'error': 'Email, OTP and Password are required'}, status=status.HTTP_400_BAD_REQUEST)
            
        if len(password) < 8:
            return Response({'error': 'The password field must be at least 8 characters.'}, status=status.HTTP_400_BAD_REQUEST)
            
        email_clean = str(email).strip().lower()
        cached_otp = cache.get(f'otp_{email_clean}')
        
        # Test domain bypass is strictly allowed only when DEBUG is True
        is_test_domain = getattr(settings, 'DEBUG', False) and any(email_clean.endswith(dom) for dom in ['@4nly.com', '@test.com', '@example.com'])
        if (cached_otp and str(cached_otp) == str(otp)) or (is_test_domain and str(otp) == '123456'):
            try:
                user = User.objects.get(email__iexact=email_clean)
                user.set_password(password)
                user.save()
                cache.delete(f'otp_{email_clean}')
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
        
        from decimal import Decimal, InvalidOperation
        try:
            amount_dec = Decimal(str(amount).strip())
        except (ValueError, TypeError, InvalidOperation):
            return Response({'error': 'Invalid amount'}, status=status.HTTP_400_BAD_REQUEST)
            
        if amount_dec > user.referral_balance:
            return Response({'error': 'Insufficient referral balance'}, status=status.HTTP_400_BAD_REQUEST)
            
        if amount_dec < 100: # Minimum withdrawal
            return Response({'error': 'Minimum withdrawal is ₹100'}, status=status.HTTP_400_BAD_REQUEST)
            
        # Create payout record
        ReferralPayout.objects.create(
            user=user,
            amount=amount_dec,
            status='pending'
        )
        
        # Deduct from balance
        user.referral_balance = user.referral_balance - amount_dec
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

        # Send push notification to target topic
        try:
            topic = f"announcement_{target.lower()}"
            send_push_notification(
                topic=topic,
                title=title,
                message=message
            )
        except Exception as fcm_err:
            print(f"Error triggering push notification for announcement: {fcm_err}")

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
        
        total_users = User.objects.filter(role='customer', deleted_at__isnull=True).count()
        total_merchants = Merchant.objects.filter(deleted_at__isnull=True).count()
        total_vouchers = Voucher.objects.count()
        total_payments = Payment.objects.count()
        total_prime_users = PrimeMembership.objects.filter(expires_at__gt=timezone.now()).values('user_id').distinct().count()
        
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
                'total_prime_users': total_prime_users,
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
            print("DEBUG: ChangePasswordView - Missing parameters")
            return Response({'error': 'Both old and new passwords are required'}, status=status.HTTP_400_BAD_REQUEST)

        match = user.check_password(old_password)
        print(f"DEBUG: ChangePasswordView for {user.email} - old password matches: {match}")

        if not match:
            return Response({'error': 'Incorrect old password'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            user.set_password(new_password)
            user.save()
            print(f"DEBUG: ChangePasswordView for {user.email} - Password changed successfully")
            return Response({'message': 'Password changed successfully'}, status=status.HTTP_200_OK)
        except Exception as e:
            print(f"DEBUG: ChangePasswordView error: {e}")
            return Response({'error': 'Failed to change password. Please check your inputs and try again.'}, status=status.HTTP_400_BAD_REQUEST)

class HeroBannerViewSet(viewsets.ModelViewSet):
    queryset = HeroBanner.objects.all().order_by('-created_at')
    serializer_class = HeroBannerSerializer
    parser_classes = (MultiPartParser, FormParser, JSONParser)

    def get_permissions(self):
        if self.action in ['list', 'retrieve']:
            return [permissions.AllowAny()]
        return [permissions.IsAuthenticated()]

    def create(self, request, *args, **kwargs):
        if request.user.role != 'admin' and not getattr(request.user, 'is_superuser', False):
            return Response({'error': 'Forbidden'}, status=status.HTTP_403_FORBIDDEN)
        return super().create(request, *args, **kwargs)

    def update(self, request, *args, **kwargs):
        if request.user.role != 'admin' and not getattr(request.user, 'is_superuser', False):
            return Response({'error': 'Forbidden'}, status=status.HTTP_403_FORBIDDEN)
        return super().update(request, *args, **kwargs)

    def partial_update(self, request, *args, **kwargs):
        if request.user.role != 'admin' and not getattr(request.user, 'is_superuser', False):
            return Response({'error': 'Forbidden'}, status=status.HTTP_403_FORBIDDEN)
        return super().partial_update(request, *args, **kwargs)

    def destroy(self, request, *args, **kwargs):
        if request.user.role != 'admin' and not getattr(request.user, 'is_superuser', False):
            return Response({'error': 'Forbidden'}, status=status.HTTP_403_FORBIDDEN)
        return super().destroy(request, *args, **kwargs)

    def perform_create(self, serializer):
        instance = serializer.save()
        if instance.image:
            sync_uploaded_file(instance.image.name)

    def perform_update(self, serializer):
        instance = serializer.save()
        if instance.image:
            sync_uploaded_file(instance.image.name)


class FreePrimeRequestViewSet(viewsets.ModelViewSet):
    queryset = FreePrimeRequest.objects.all().order_by('-created_at')
    serializer_class = FreePrimeRequestSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        if self.request.user.role == 'admin':
            return self.queryset
        return self.queryset.filter(user=self.request.user)

    def update(self, request, *args, **kwargs):
        if request.user.role != 'admin' and not getattr(request.user, 'is_superuser', False):
            return Response({'error': 'Forbidden'}, status=status.HTTP_403_FORBIDDEN)
        return super().update(request, *args, **kwargs)

    def partial_update(self, request, *args, **kwargs):
        if request.user.role != 'admin' and not getattr(request.user, 'is_superuser', False):
            return Response({'error': 'Forbidden'}, status=status.HTTP_403_FORBIDDEN)
        return super().partial_update(request, *args, **kwargs)

    def destroy(self, request, *args, **kwargs):
        if request.user.role != 'admin' and not getattr(request.user, 'is_superuser', False):
            return Response({'error': 'Forbidden'}, status=status.HTTP_403_FORBIDDEN)
        return super().destroy(request, *args, **kwargs)

    def create(self, request, *args, **kwargs):
        user = request.user
        
        # Calculate referred membership count
        from .models import Referral, PrimeMembership
        referrals = Referral.objects.filter(referrer=user).select_related('referred')
        count = 0
        for ref in referrals:
            if PrimeMembership.objects.filter(user=ref.referred).exists():
                count += 1
                
        if count < 10:
            return Response({'error': 'You need at least 10 referrals who purchased membership to request free premium access.'}, status=status.HTTP_400_BAD_REQUEST)
            
        # Check if they already have a pending or approved request
        if FreePrimeRequest.objects.filter(user=user, status='pending').exists():
            return Response({'error': 'You already have a pending request.'}, status=status.HTTP_400_BAD_REQUEST)
            
        if FreePrimeRequest.objects.filter(user=user, status='approved').exists():
            return Response({'error': 'You already have an approved request.'}, status=status.HTTP_400_BAD_REQUEST)
            
        free_req = FreePrimeRequest.objects.create(user=user, status='pending')
        return Response(FreePrimeRequestSerializer(free_req).data, status=status.HTTP_201_CREATED)

    @action(detail=True, methods=['post'])
    def approve(self, request, pk=None):
        if request.user.role != 'admin':
            return Response({'error': 'Forbidden'}, status=status.HTTP_403_FORBIDDEN)
            
        free_req = self.get_object()
        if free_req.status != 'pending':
            return Response({'error': 'Request already processed.'}, status=status.HTTP_400_BAD_REQUEST)

        from django.db import transaction
        with transaction.atomic():
            free_req.status = 'approved'
            free_req.save()

            # Grant prime membership for 365 days
            from django.utils import timezone
            from .models import PrimeMembership
            
            now = timezone.now()
            active_membership = PrimeMembership.objects.filter(user=free_req.user, expires_at__gt=now).first()
            if active_membership:
                active_membership.expires_at = active_membership.expires_at + timezone.timedelta(days=365)
                active_membership.save()
            else:
                PrimeMembership.objects.create(
                    user=free_req.user,
                    source='referral_reward',
                    starts_at=now,
                    expires_at=now + timezone.timedelta(days=365)
                )

            credit_referral_reward(free_req.user)

        return Response({'status': 'approved'})

    @action(detail=True, methods=['post'])
    def decline(self, request, pk=None):
        if request.user.role != 'admin':
            return Response({'error': 'Forbidden'}, status=status.HTTP_403_FORBIDDEN)
            
        free_req = self.get_object()
        if free_req.status != 'pending':
            return Response({'error': 'Request already processed.'}, status=status.HTTP_400_BAD_REQUEST)

        free_req.status = 'declined'
        free_req.save()
        return Response({'status': 'declined'})



