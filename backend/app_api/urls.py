from django.urls import path, include
from rest_framework.routers import DefaultRouter
from rest_framework_simplejwt.views import TokenRefreshView
from .views import (
    CategoryViewSet, MerchantViewSet, UserViewSet, AppSettingViewSet,
    ProfileView, LoginView, SignupView, AdminDashboardView, MerchantDashboardView,
    AdminPaymentListView, AdminVoucherListView, ResendVerificationView,
    VerifyEmailView, ForgotPasswordView, ResetPasswordView, VerifyOTPView,
    AdminNotificationView, ReferralPayoutViewSet, RazorpayCreateOrderView,
    RazorpayVerifyPaymentView, CustomerTransactionsView, ChangePasswordView
)

router = DefaultRouter()
router.register(r'categories', CategoryViewSet)
router.register(r'merchants', MerchantViewSet)
router.register(r'users', UserViewSet)
router.register(r'settings', AppSettingViewSet)
router.register(r'referral-payouts', ReferralPayoutViewSet)

urlpatterns = [
    path('', include(router.urls)),
    path('profile/', ProfileView.as_view(), name='profile'),
    
    # Auth Endpoints
    path('auth/login/', LoginView.as_view(), name='login'),
    path('auth/signup/', SignupView.as_view(), name='signup'),
    path('auth/verify-otp/', VerifyOTPView.as_view(), name='verify_otp'),
    path('auth/resend-otp/', ResendVerificationView.as_view(), name='resend_otp'),
    path('auth/forgot-password/', ForgotPasswordView.as_view(), name='forgot_password'),
    path('auth/reset-password/', ResetPasswordView.as_view(), name='reset_password'),
    path('auth/change_password/', ChangePasswordView.as_view(), name='change_password'),
    
    # Razorpay Payment Gateway Endpoints
    path('auth/razorpay/create-order/', RazorpayCreateOrderView.as_view(), name='razorpay-create-order'),
    path('auth/razorpay/verify/', RazorpayVerifyPaymentView.as_view(), name='razorpay-verify'),
    
    # Customer Transactions
    path('customer/transactions/', CustomerTransactionsView.as_view(), name='customer-transactions'),
    
    # Legacy/Internal Endpoints (if needed by frontend)
    path('forgot-password/', ForgotPasswordView.as_view(), name='forgot_password_short'),
    path('reset-password/', ResetPasswordView.as_view(), name='reset_password_short'),
    
    # Token Refresh
    path('auth/token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    
    # Web Verification (Legacy support)
    path('auth/verify-email/<str:uidb64>/<str:token>/', VerifyEmailView.as_view(), name='verify_email'),
    
    # Admin Endpoints
    path('admin/dashboard/', AdminDashboardView.as_view(), name='admin-dashboard'),
    path('admin/payments/', AdminPaymentListView.as_view(), name='admin-payments'),
    path('admin/vouchers/', AdminVoucherListView.as_view(), name='admin-vouchers'),
    path('admin/notifications/', AdminNotificationView.as_view(), name='admin-notifications'),
    path('admin/notifications/<int:pk>/', AdminNotificationView.as_view(), name='admin-notifications-detail'),
    
    # Merchant Endpoints
    path('merchant/dashboard/', MerchantDashboardView.as_view(), name='merchant-dashboard'),
]
