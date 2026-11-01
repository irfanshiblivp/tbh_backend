from rest_framework import serializers
from .models import (
    User, Category, Merchant, PrimeMembership, Payment, Voucher, AppSetting,
    ReferralPayout, HeroBanner, FreePrimeRequest
)
from django.utils import timezone

class AppSettingSerializer(serializers.ModelSerializer):
    class Meta:
        model = AppSetting
        fields = '__all__'

class UserSerializer(serializers.ModelSerializer):
    referral_code = serializers.SerializerMethodField()
    customer_id = serializers.SerializerMethodField()
    is_prime = serializers.SerializerMethodField()
    prime_starts_at = serializers.SerializerMethodField()
    prime_expires_at = serializers.SerializerMethodField()
    signup_method = serializers.SerializerMethodField()
    referred_membership_count = serializers.SerializerMethodField()
    free_prime_requested = serializers.SerializerMethodField()
    
    def get_referral_code(self, obj):
        if obj.role == 'customer' and not obj.referral_code:
            import random
            attempts = 0
            while True:
                if attempts < 100:
                    code = f"TBC{random.randint(100000, 999999)}"
                elif attempts < 200:
                    code = f"TBC{random.randint(10000000, 99999999)}"
                else:
                    code = f"TBC{random.randint(1000000000, 9999999999)}"
                    
                if not User.objects.filter(referral_code=code).exists():
                    obj.referral_code = code
                    User.objects.filter(id=obj.id).update(referral_code=code)
                    break
                attempts += 1
        return obj.referral_code

    def get_customer_id(self, obj):
        if not obj.customer_number:
            return "—"
        if obj.created_at:
            ym = obj.created_at.strftime('%y%m')
        else:
            ym = timezone.now().strftime('%y%m')
        return f"TBC{ym}-{obj.customer_number:05d}"
    
    class Meta:
        model = User
        fields = (
            'id', 'name', 'email', 'role', 'phone', 'profile_picture', 
            'status', 'referral_balance', 'referral_total_earned', 'referral_code',
            'bank_account_holder_name', 'bank_account_number', 'bank_ifsc', 
            'bank_name', 'bank_upi_id', 'customer_number', 'customer_id', 'created_at',
            'is_prime', 'prime_starts_at', 'prime_expires_at', 'email_verified_at', 'state',
            'signup_method', 'referred_membership_count', 'free_prime_requested'
        )
        read_only_fields = (
            'role', 'status', 'referral_balance', 'referral_total_earned', 
            'customer_number', 'email_verified_at', 'referral_code'
        )

    def get_is_prime(self, obj):
        now = self.context.get('now') or timezone.now()
        prime_map = self.context.get('prime_map')
        if prime_map is not None:
            m = prime_map.get(obj.id)
            return bool(m and m.expires_at and m.expires_at > now)
        return PrimeMembership.objects.filter(user=obj, expires_at__gt=now).exists()

    def get_prime_starts_at(self, obj):
        prime_map = self.context.get('prime_map')
        if prime_map is not None:
            m = prime_map.get(obj.id)
            return m.starts_at.isoformat() if m and m.starts_at else None
        membership = PrimeMembership.objects.filter(user=obj).order_by('-expires_at').first()
        return membership.starts_at.isoformat() if membership and membership.starts_at else None

    def get_prime_expires_at(self, obj):
        prime_map = self.context.get('prime_map')
        if prime_map is not None:
            m = prime_map.get(obj.id)
            return m.expires_at.isoformat() if m and m.expires_at else None
        membership = PrimeMembership.objects.filter(user=obj).order_by('-expires_at').first()
        return membership.expires_at.isoformat() if membership and membership.expires_at else None

    def get_signup_method(self, obj):
        referred_by_map = self.context.get('referred_by_map')
        if referred_by_map is not None:
            if obj.id in referred_by_map:
                code = referred_by_map.get(obj.id)
                return f"Referral ({code})" if code else "Referral"
            return "Direct"
        from .models import Referral
        ref = Referral.objects.filter(referred=obj).select_related('referrer').first()
        if ref:
            code = (ref.referrer.referral_code if (ref.referrer and ref.referrer.referral_code) else (f"TBC{ref.referrer.id}" if ref.referrer else "TBC"))
            return f"Referral ({code})"
        return "Direct"

    def get_referred_membership_count(self, obj):
        ref_count_map = self.context.get('ref_count_map')
        if ref_count_map is not None:
            return ref_count_map.get(obj.id, 0)
        from .models import Referral, PrimeMembership
        referrals = Referral.objects.filter(referrer=obj).select_related('referred')
        count = 0
        for ref in referrals:
            if PrimeMembership.objects.filter(user=ref.referred).exists():
                count += 1
        return count

    def get_free_prime_requested(self, obj):
        free_req_map = self.context.get('free_req_map')
        if free_req_map is not None:
            return free_req_map.get(obj.id, 'none')
        from .models import FreePrimeRequest
        req = FreePrimeRequest.objects.filter(user=obj).order_by('-created_at').first()
        if req:
            return req.status
        return 'none'

class CategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = Category
        fields = '__all__'

class MerchantSerializer(serializers.ModelSerializer):
    category_name = serializers.ReadOnlyField(source='category')
    owner_name = serializers.ReadOnlyField(source='user.name')
    state = serializers.ReadOnlyField(source='user.state')
    added_by_name = serializers.ReadOnlyField(source='added_by.name')
    city = serializers.SerializerMethodField()
    
    class Meta:
        model = Merchant
        fields = [
            'id', 'user', 'business_name', 'category', 'description', 
            'address', 'logo', 'card_image', 'discount_percent', 'discount_type',
            'status', 'created_at', 'updated_at', 'category_name', 'owner_name',
            'latitude', 'longitude', 'license_document', 'state', 'city',
            'added_by', 'added_by_name'
        ]
        read_only_fields = ['created_at', 'updated_at', 'category_name', 'owner_name', 'state', 'user', 'logo', 'card_image', 'license_document', 'added_by', 'added_by_name']

    def get_city(self, obj):
        if not obj.address:
            return ""
        parts = [p.strip() for p in obj.address.split(',')]
        if len(parts) >= 3:
            return parts[-3]
        elif len(parts) == 2:
            return parts[0]
        return ""

class PrimeMembershipSerializer(serializers.ModelSerializer):
    class Meta:
        model = PrimeMembership
        fields = '__all__'

class PaymentSerializer(serializers.ModelSerializer):
    user_name = serializers.ReadOnlyField(source='user.name')
    user_email = serializers.ReadOnlyField(source='user.email')
    
    class Meta:
        model = Payment
        fields = '__all__'

class VoucherSerializer(serializers.ModelSerializer):
    user_name = serializers.ReadOnlyField(source='user.name')
    merchant_name = serializers.ReadOnlyField(source='merchant_profile.business_name')
    
    class Meta:
        model = Voucher
        fields = '__all__'

class ChangePasswordSerializer(serializers.Serializer):
    old_password = serializers.CharField(required=True)
class ReferralPayoutSerializer(serializers.ModelSerializer):
    user_details = UserSerializer(source='user', read_only=True)
    referred_users = serializers.SerializerMethodField()
    
    class Meta:
        model = ReferralPayout
        fields = '__all__'

    def get_referred_users(self, obj):
        from .models import Referral, PrimeMembership
        referrals = Referral.objects.filter(referrer=obj.user).select_related('referred')
        result = []
        for ref in referrals:
            referred_user = ref.referred
            is_prime = PrimeMembership.objects.filter(user=referred_user, expires_at__gt=timezone.now()).exists()
            result.append({
                'name': referred_user.name,
                'email': referred_user.email,
                'created_at': referred_user.created_at.isoformat() if referred_user.created_at else None,
                'is_prime': is_prime,
                'reward_amount': str(ref.reward_amount) if ref.reward_amount else None,
                'reward_paid_at': ref.reward_paid_at.isoformat() if ref.reward_paid_at else None
            })
        return result

class HeroBannerSerializer(serializers.ModelSerializer):
    image = serializers.ImageField(required=False, allow_null=True)

    class Meta:
        model = HeroBanner
        fields = ['id', 'image', 'created_at', 'updated_at']

    def to_representation(self, instance):
        rep = super().to_representation(instance)
        if instance.image:
            request = self.context.get('request')
            if request:
                url = request.build_absolute_uri(instance.image.url)
            else:
                url = f'https://api.thebaronclub.com{instance.image.url}'
            rep['image'] = url.replace('/storage/', '/app-storage/')
        else:
            rep['image'] = None
        return rep


class FreePrimeRequestSerializer(serializers.ModelSerializer):
    user_details = UserSerializer(source='user', read_only=True)
    referred_membership_count = serializers.SerializerMethodField()

    class Meta:
        model = FreePrimeRequest
        fields = '__all__'
        read_only_fields = ('user', 'status', 'created_at', 'updated_at')

    def get_referred_membership_count(self, obj):
        from .models import Referral, PrimeMembership
        referrals = Referral.objects.filter(referrer=obj.user).select_related('referred')
        count = 0
        for ref in referrals:
            if PrimeMembership.objects.filter(user=ref.referred).exists():
                count += 1
        return count

