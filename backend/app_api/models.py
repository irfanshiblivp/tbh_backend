from django.db import models
from django.contrib.auth.models import AbstractBaseUser, BaseUserManager
import bcrypt

class UserManager(BaseUserManager):
    def create_user(self, email, password=None, **extra_fields):
        if not email:
            raise ValueError('The Email field must be set')
        email = self.normalize_email(email)
        user = self.model(email=email, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(self, email, password=None, **extra_fields):
        return self.create_user(email, password, **extra_fields)

class User(AbstractBaseUser):
    # Laravel fields
    name = models.CharField(max_length=255, blank=True, null=True)
    email = models.EmailField(unique=True)
    
    # Map Django mandatory last_login to Laravel's updated_at column
    # We use this as the primary field for the 'updated_at' column to avoid E007 error
    last_login = models.DateTimeField(db_column='updated_at', auto_now=True, null=True)
    
    ROLE_CHOICES = (
        ('admin', 'Admin'),
        ('staff', 'Staff'),
        ('merchant', 'Merchant'),
        ('customer', 'Customer'),
    )
    role = models.CharField(max_length=20, choices=ROLE_CHOICES, default='customer')
    phone = models.CharField(max_length=20, blank=True, null=True, unique=True)
    profile_picture = models.CharField(max_length=255, blank=True, null=True)
    status = models.CharField(max_length=20, default='active')
    email_verified_at = models.DateTimeField(blank=True, null=True)
    
    referral_balance = models.DecimalField(max_digits=10, decimal_places=2, default=0.00)
    referral_total_earned = models.DecimalField(max_digits=10, decimal_places=2, default=0.00)
    
    bank_account_holder_name = models.CharField(max_length=255, blank=True, null=True)
    bank_account_number = models.CharField(max_length=255, blank=True, null=True)
    bank_ifsc = models.CharField(max_length=255, blank=True, null=True)
    bank_name = models.CharField(max_length=255, blank=True, null=True)
    bank_upi_id = models.CharField(max_length=255, blank=True, null=True)
    
    customer_number = models.IntegerField(unique=True, null=True, blank=True)
    state = models.CharField(max_length=255, blank=True, null=True)
    
    # Laravel created_at
    created_at = models.DateTimeField(auto_now_add=True, null=True)

    @property
    def referral_code(self):
        if self.customer_number:
            return f"TBH{self.customer_number}"
        return f"TBH{self.id + 1000}"

    # Virtual updated_at property for code compatibility
    @property
    def updated_at(self):
        return self.last_login

    # Django internal flags (properties, NOT database columns)
    @property
    def is_active(self):
        return self.status == 'active'

    @property
    def is_staff(self):
        return self.role in ['admin', 'staff']

    @property
    def is_superuser(self):
        return self.role == 'admin'

    def has_perm(self, perm, obj=None):
        return self.is_superuser

    def has_module_perms(self, app_label):
        return self.is_superuser

    objects = UserManager()

    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['name']

    def set_password(self, raw_password):
        if raw_password is None:
            self.set_unusable_password()
            return

        # Generate Laravel-compatible bcrypt hash ($2y$)
        # Python's bcrypt generates $2b$ or $2a$, we translate to $2y$
        hashed = bcrypt.hashpw(raw_password.encode('utf-8'), bcrypt.gensalt(10))
        hash_str = hashed.decode('utf-8')
        if hash_str.startswith('$2b$'):
            hash_str = '$2y$' + hash_str[4:]
        elif hash_str.startswith('$2a$'):
            hash_str = '$2y$' + hash_str[4:]
            
        self.password = hash_str
        self._password = raw_password

    def check_password(self, raw_password):
        # 1. Handle raw Laravel/Bcrypt hashes ($2y$, $2b$, $2a$)
        if self.password and self.password.startswith('$'):
            verify_hash = self.password
            if self.password.startswith('$2y$'):
                verify_hash = '$2b$' + self.password[4:]
            elif self.password.startswith('$2a$'):
                verify_hash = '$2b$' + self.password[4:]
                
            try:
                return bcrypt.checkpw(raw_password.encode('utf-8'), verify_hash.encode('utf-8'))
            except Exception:
                pass

        # 2. Fallback to standard Django check (for legacy prefixed hashes or other hashers)
        # We use AbstractBaseUser's original check_password logic indirectly
        from django.contrib.auth.hashers import check_password as django_check_password
        return django_check_password(raw_password, self.password)

    def save(self, *args, **kwargs):
        if not self.customer_number:
            import random
            while True:
                new_number = random.randint(100000, 999999)
                if not User.objects.filter(customer_number=new_number).exists():
                    self.customer_number = new_number
                    break
        super().save(*args, **kwargs)

    class Meta:
        db_table = 'users'
        managed = False 

    def __str__(self):
        return self.email or "Unknown User"

class Category(models.Model):
    name = models.CharField(max_length=100, unique=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    class Meta:
        db_table = 'categories'
        managed = False

class Merchant(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='merchant_profile', db_column='user_id')
    business_name = models.CharField(max_length=255)
    category = models.CharField(max_length=255, null=True, blank=True)
    description = models.TextField(null=True, blank=True)
    address = models.CharField(max_length=255, blank=True, null=True)
    logo = models.CharField(max_length=255, blank=True, null=True)
    card_image = models.CharField(max_length=255, blank=True, null=True)
    discount_percent = models.IntegerField(default=50)
    status = models.CharField(max_length=20, default='active')
    latitude = models.DecimalField(max_digits=10, decimal_places=7, null=True, blank=True)
    longitude = models.DecimalField(max_digits=10, decimal_places=7, null=True, blank=True)
    license_document = models.CharField(max_length=255, null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    class Meta:
        db_table = 'merchant_profiles'
        managed = False

class PrimeMembership(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='memberships', db_column='user_id')
    source = models.CharField(max_length=20)
    starts_at = models.DateTimeField()
    expires_at = models.DateTimeField()
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    class Meta:
        db_table = 'prime_memberships'
        managed = False

class Payment(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='payments', db_column='user_id')
    razorpay_order_id = models.CharField(max_length=255, unique=True)
    razorpay_payment_id = models.CharField(max_length=255, null=True, blank=True, unique=True)
    amount = models.PositiveIntegerField()
    status = models.CharField(max_length=20, default='pending')
    purpose = models.CharField(max_length=50, default='prime_membership')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    class Meta:
        db_table = 'payments'
        managed = False

class Voucher(models.Model):
    code = models.CharField(max_length=12, unique=True)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='vouchers', db_column='user_id')
    merchant_profile = models.ForeignKey(Merchant, on_delete=models.CASCADE, related_name='vouchers', db_column='merchant_profile_id')
    discount_percent = models.IntegerField()
    bill_amount = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    amount_saved = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    expires_at = models.DateTimeField(null=True, blank=True)
    used_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True, null=True)
    updated_at = models.DateTimeField(auto_now=True, null=True)

    class Meta:
        db_table = 'vouchers'
        managed = False

class AppSetting(models.Model):
    key = models.CharField(max_length=255, unique=True)
    value = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'settings'
        managed = False

class ReferralLink(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='referral_links', db_column='user_id')
    token = models.CharField(max_length=64, unique=True)
    expires_at = models.DateTimeField()
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'referral_links'
        managed = False

class Referral(models.Model):
    referrer = models.ForeignKey(User, on_delete=models.CASCADE, related_name='referrals_made', db_column='referrer_id')
    referred = models.OneToOneField(User, on_delete=models.CASCADE, related_name='referred_by_record', db_column='referred_id')
    referral_link = models.ForeignKey(ReferralLink, on_delete=models.CASCADE, related_name='referrals', db_column='referral_link_id')
    reward_paid_at = models.DateTimeField(null=True, blank=True)
    reward_amount = models.DecimalField(max_digits=8, decimal_places=2, null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'referrals'
        managed = False

class SystemAnnouncement(models.Model):
    title = models.CharField(max_length=255)
    message = models.TextField()
    target = models.CharField(max_length=20, default='BOTH') # BOTH, CUSTOMER, MERCHANT
    is_auto = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'system_announcements'
        managed = True

class ReferralPayout(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='payouts', db_column='user_id')
    admin = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, related_name='processed_payouts', db_column='admin_id')
    amount = models.DecimalField(max_digits=8, decimal_places=2)
    status = models.CharField(max_length=20, default='pending')
    notes = models.TextField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'referral_payouts'
        managed = True
