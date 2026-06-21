import 'package:frontend/services/api_service.dart';

String resolveAssetUrl(String? path) {
  if (path == null || path.isEmpty) return '';
  if (path.startsWith('http')) return path;
  
  String cleanPath = path.startsWith('/') ? path.substring(1) : path;
  
  // Dynamically resolve baseDomain from the active ApiService.baseUrl (local host or production domain)
  String baseDomain;
  try {
    Uri uri = Uri.parse(ApiService.baseUrl);
    String portStr = (uri.port == 80 && uri.scheme == 'http') || (uri.port == 443 && uri.scheme == 'https')
        ? ''
        : ':${uri.port}';
    baseDomain = '${uri.scheme}://${uri.host}$portStr';
  } catch (e) {
    baseDomain = 'https://api.thebaronclub.com';
  }
  if (baseDomain.isEmpty) {
    baseDomain = 'https://api.thebaronclub.com';
  }
  
  if (cleanPath.startsWith('storage/')) {
    return '$baseDomain/$cleanPath';
  }
  
  if (cleanPath.startsWith('app-storage/')) {
    return '$baseDomain/$cleanPath';
  }
  
  return '$baseDomain/storage/$cleanPath';
}

DateTime? parseLocalTime(String? dateStr) {
  if (dateStr == null || dateStr.isEmpty) return null;
  String formattedStr = dateStr;
  if (!formattedStr.endsWith('Z') && !formattedStr.contains('+') && !RegExp(r'-\d{2}:\d{2}$').hasMatch(formattedStr)) {
    formattedStr = formattedStr.endsWith(' ') ? '${formattedStr.trim()}Z' : '${formattedStr}Z';
  }
  return DateTime.tryParse(formattedStr)?.toLocal();
}

class Category {
  final int id;
  final String name;
  final String slug;
  final String iconType;

  Category({required this.id, required this.name, this.slug = '', this.iconType = 'storefront'});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'General',
      slug: json['slug'] ?? '',
      iconType: json['icon_type'] ?? 'storefront',
    );
  }
}

class Merchant {
  final int id;
  final int userId;
  final String businessName;
  final String description;
  final String address;
  final String logo;
  final String cardImage;
  final int discountPercent;
  final String status;
  final String city;
  final String state;
  final String categoryName;
  final double? latitude;
  final double? longitude;

  Merchant({
    required this.id,
    required this.userId,
    required this.businessName,
    required this.description,
    required this.address,
    required this.logo,
    required this.cardImage,
    required this.discountPercent,
    required this.status,
    this.city = '',
    this.state = '',
    this.categoryName = '',
    this.latitude,
    this.longitude,
  });

  // Legacy field aliases for backward compatibility
  String get name => businessName;
  String get profilePhoto => logo;
  String get profilePicture => logo;
  String get bannerImage => cardImage;
  int get discountPercentage => discountPercent;
  int get ownerId => userId;
  String? get category => categoryName;
  double get rating => 4.5;
  List<Offer> get offers => [];

  factory Merchant.fromJson(Map<String, dynamic> json) {
    return Merchant(
      id: json['id'] ?? 0,
      userId: json['user'] is int ? json['user'] : (json['user']?['id'] ?? 0),
      businessName: json['business_name'] ?? json['name'] ?? 'Unnamed Business',
      description: json['description'] ?? '',
      address: json['address'] ?? '',
      logo: resolveAssetUrl(json['logo']),
      cardImage: resolveAssetUrl(json['card_image']),
      discountPercent: json['discount_percent'] ?? 50,
      status: json['status'] ?? 'active',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      categoryName: json['category_name'] ?? '',
      latitude: json['latitude'] is num ? (json['latitude'] as num).toDouble() : double.tryParse(json['latitude']?.toString() ?? ''),
      longitude: json['longitude'] is num ? (json['longitude'] as num).toDouble() : double.tryParse(json['longitude']?.toString() ?? ''),
    );
  }
}

class AppUser {
  final int id;
  final String username;
  final String email;
  final String role;
  final String? phone;
  final String? profilePicture;
  final String status;
  final double referralBalance;
  final double referralTotalEarned;
  final String? bankAccountHolderName;
  final String? bankAccountNumber;
  final String? bankIfsc;
  final String? bankName;
  final String? bankUpiId;
  final int? customerNumber;
  final String? referralCode;
  final DateTime? emailVerifiedAt;
  final bool isPrime;
  final String? state;
  final DateTime? primeStartsAt;
  final DateTime? primeExpiresAt;
  final String signupMethod;
  final int referredMembershipCount;
  final String freePrimeRequested;

  AppUser({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    this.phone,
    this.profilePicture,
    required this.status,
    required this.referralBalance,
    required this.referralTotalEarned,
    this.bankAccountHolderName,
    this.bankAccountNumber,
    this.bankIfsc,
    this.bankName,
    this.bankUpiId,
    this.customerNumber,
    this.referralCode,
    this.emailVerifiedAt,
    this.isPrime = false,
    this.state,
    this.primeStartsAt,
    this.primeExpiresAt,
    this.signupMethod = "Direct",
    this.referredMembershipCount = 0,
    this.freePrimeRequested = 'none',
  });

  // bool get isPrime => role == 'customer' && referralBalance > 0;
  bool get isBlocked => status == 'inactive';

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] ?? 0,
      username: json['username'] ?? json['name'] ?? 'User',
      email: json['email'] ?? '',
      role: json['role'] ?? 'customer',
      phone: json['phone'],
      profilePicture: resolveAssetUrl(json['profile_picture']),
      status: json['status'] ?? 'active',
      referralBalance: double.tryParse((json['referral_balance'] ?? 0).toString()) ?? 0.0,
      referralTotalEarned: double.tryParse((json['referral_total_earned'] ?? 0).toString()) ?? 0.0,
      bankAccountHolderName: json['bank_account_holder_name'],
      bankAccountNumber: json['bank_account_number'],
      bankIfsc: json['bank_ifsc'],
      bankName: json['bank_name'],
      bankUpiId: json['bank_upi_id'],
      customerNumber: json['customer_number'],
      referralCode: json['referral_code'],
      emailVerifiedAt: parseLocalTime(json['email_verified_at']),
      isPrime: json['is_prime'] ?? false,
      state: json['state'],
      primeStartsAt: parseLocalTime(json['prime_starts_at']),
      primeExpiresAt: parseLocalTime(json['prime_expires_at']),
      signupMethod: json['signup_method'] ?? 'Direct',
      referredMembershipCount: json['referred_membership_count'] ?? 0,
      freePrimeRequested: json['free_prime_requested'] ?? 'none',
    );
  }
}

class Transaction {
  final String transactionId;
  final double amountPaid;
  final double amountSaved;
  final String status;
  final DateTime timestamp;
  final String userName;
  final String merchantName;
  final String paymentMethod;
  final int? merchantId;

  Transaction({
    required this.transactionId,
    required this.amountPaid,
    this.amountSaved = 0.0,
    required this.status,
    required this.timestamp,
    this.userName = '',
    this.merchantName = '',
    this.paymentMethod = 'ONLINE',
    this.merchantId,
  });
}

class Offer {
  final int id;
  final String title;
  final String description;
  final bool isActive;

  Offer({
    required this.id,
    required this.title,
    this.description = '',
    this.isActive = true,
  });
}

class AppSetting {
  final int id;
  final String key;
  final String value;

  AppSetting({
    required this.id,
    required this.key,
    required this.value,
  });

  factory AppSetting.fromJson(Map<String, dynamic> json) {
    return AppSetting(
      id: json['id'] ?? 0,
      key: json['key'] ?? '',
      value: json['value'] ?? '',
    );
  }
}

class AdminLog {
  final String action;
  final String details;
  final DateTime timestamp;
  final String adminName;

  AdminLog({
    required this.action,
    required this.details,
    required this.timestamp,
    this.adminName = 'Admin',
  });

  factory AdminLog.fromJson(Map<String, dynamic> json) {
    return AdminLog(
      action: json['action'] ?? 'Unknown Action',
      details: json['details'] ?? '',
      timestamp: parseLocalTime(json['timestamp']) ?? DateTime.now(),
      adminName: json['admin_name'] ?? 'System',
    );
  }
}

class StateRegion {
  final int id;
  final String name;
  final String code;
  StateRegion({required this.id, required this.name, required this.code});
}

class PrimeMembership {
  final int id;
  final int userId;
  final String source;
  final DateTime startsAt;
  final DateTime expiresAt;

  PrimeMembership({
    required this.id,
    required this.userId,
    required this.source,
    required this.startsAt,
    required this.expiresAt,
  });

  factory PrimeMembership.fromJson(Map<String, dynamic> json) {
    return PrimeMembership(
      id: json['id'] ?? 0,
      userId: json['user'] ?? 0,
      source: json['source'] ?? 'unknown',
      startsAt: parseLocalTime(json['starts_at']) ?? DateTime.now(),
      expiresAt: parseLocalTime(json['expires_at']) ?? DateTime.now().add(const Duration(days: 365)),
    );
  }
}

class Payment {
  final int id;
  final int userId;
  final String razorpayOrderId;
  final String? razorpayPaymentId;
  final int amount;
  final String status;
  final String purpose;

  Payment({
    required this.id,
    required this.userId,
    required this.razorpayOrderId,
    this.razorpayPaymentId,
    required this.amount,
    required this.status,
    required this.purpose,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] ?? 0,
      userId: json['user'] ?? 0,
      razorpayOrderId: json['razorpay_order_id'] ?? '',
      razorpayPaymentId: json['razorpay_payment_id'],
      amount: json['amount'] ?? 0,
      status: json['status'] ?? 'pending',
      purpose: json['purpose'] ?? 'prime_membership',
    );
  }
}

class HeroBanner {
  final int id;
  final String imageUrl;

  HeroBanner({
    required this.id,
    required this.imageUrl,
  });

  factory HeroBanner.fromJson(Map<String, dynamic> json) {
    return HeroBanner(
      id: json['id'] ?? 0,
      imageUrl: resolveAssetUrl(json['image']),
    );
  }
}

