from rest_framework import serializers
from .models import (
    User, Category, Merchant, PrimeMembership, Payment, Voucher, AppSetting,
    ReferralPayout
)
from django.utils import timezone

class AppSettingSerializer(serializers.ModelSerializer):
    class Meta:
        model = AppSetting
        fields = '__all__'

class UserSerializer(serializers.ModelSerializer):
    is_prime = serializers.SerializerMethodField()
    prime_starts_at = serializers.SerializerMethodField()
    prime_expires_at = serializers.SerializerMethodField()
    
    class Meta:
        model = User
        fields = (
            'id', 'name', 'email', 'role', 'phone', 'profile_picture', 
            'status', 'referral_balance', 'referral_total_earned', 'referral_code',
            'bank_account_holder_name', 'bank_account_number', 'bank_ifsc', 
            'bank_name', 'bank_upi_id', 'customer_number', 'created_at',
            'is_prime', 'prime_starts_at', 'prime_expires_at', 'email_verified_at', 'state'
        )
        read_only_fields = ('referral_balance', 'referral_total_earned', 'customer_number')

    def get_is_prime(self, obj):
        return PrimeMembership.objects.filter(user=obj, expires_at__gt=timezone.now()).exists()

    def get_prime_starts_at(self, obj):
        membership = PrimeMembership.objects.filter(user=obj).order_by('-expires_at').first()
        return membership.starts_at.isoformat() if membership and membership.starts_at else None

    def get_prime_expires_at(self, obj):
        membership = PrimeMembership.objects.filter(user=obj).order_by('-expires_at').first()
        return membership.expires_at.isoformat() if membership and membership.expires_at else None

class CategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = Category
        fields = '__all__'

class MerchantSerializer(serializers.ModelSerializer):
    category_name = serializers.ReadOnlyField(source='category')
    owner_name = serializers.ReadOnlyField(source='user.name')
    
    class Meta:
        model = Merchant
        fields = [
            'id', 'user', 'business_name', 'category', 'description', 
            'address', 'logo', 'card_image', 'discount_percent', 
            'status', 'created_at', 'updated_at', 'category_name', 'owner_name',
            'latitude', 'longitude', 'license_document'
        ]
        read_only_fields = ['created_at', 'updated_at', 'category_name', 'owner_name']

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
