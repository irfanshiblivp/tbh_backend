import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/models/models.dart';
import 'package:frontend/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';

class AppState extends ChangeNotifier {
  final ApiService _api = ApiService();
  
  // App state management
  AppState() {
    checkLoginStatus();
  }

  Future<void> checkLoginStatus() async {
    _isCheckingAuth = true;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      final role = prefs.getString('user_role');
      
      if (token != null && token.isNotEmpty) {
        _isLoggedIn = true;
        _userRole = role;
        await refreshData();
      } else {
        await loadPublicData();
      }
    } catch (e) {
      print("Auth check error: $e");
    } finally {
      _isCheckingAuth = false;
      _isInitialized = true;
      notifyListeners();
    }
  }

  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;

  bool _isCheckingAuth = true;
  bool get isCheckingAuth => _isCheckingAuth;

  String? _userRole;
  String? get userRole => _userRole;

  bool _isInitialized = false;
  bool _hasConnection = true;
  bool _serverAvailable = true;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get hasConnection => _hasConnection;
  bool get serverAvailable => _serverAvailable;

  AppUser? _profile;
  AppUser? get profile => _profile;
  
  Merchant? get merchantProfile {
    if (_profile == null || _userRole != 'merchant') return null;
    try {
      return _merchants.firstWhere((m) => m.userId == _profile!.id);
    } catch (e) {
      return null;
    }
  }
  
  bool get isVerified {
    if (_profile == null) return false;
    return _profile!.emailVerifiedAt != null;
  }

  Future<void> resendVerification() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _api.post('/auth/resend_verification/', {});
    } catch (e) {
      throw Exception('Failed to resend verification: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> verifyOtp(String otp) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _api.post('/auth/verify-otp/', {'otp': otp});
      if (response != null && (response['message'] == 'Email verified successfully' || response['user'] != null)) {
        await refreshData();
        return true;
      }
      return false;
    } catch (e) {
      String msg = e.toString().replaceAll('Exception: ', '');
      throw Exception(msg);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> forgotPassword(String email) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _api.post('/forgot-password/', {'email': email});
    } catch (e) {
      throw Exception('Failed to send verification code: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> resetPassword(String email, String otp, String newPassword) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _api.post('/reset-password/', {
        'email': email,
        'otp': otp,
        'password': newPassword,
      });
    } catch (e) {
      throw Exception('Failed to reset password: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<Merchant> _merchants = [];
  List<Merchant> get merchants => _merchants;

  Position? _devicePosition;
  Position? get devicePosition => _devicePosition;

  Future<void> fetchLocationAndSort() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint("Location services are disabled.");
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint("Location permissions are denied.");
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        debugPrint("Location permissions are permanently denied.");
        return;
      }

      try {
        _devicePosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 5),
        );
      } catch (e) {
        debugPrint("Timeout fetching location, trying last known position: $e");
        _devicePosition = await Geolocator.getLastKnownPosition();
      }

      if (_devicePosition != null && _merchants.isNotEmpty) {
        _merchants.sort((a, b) {
          if (a.latitude == null || a.longitude == null) return 1;
          if (b.latitude == null || b.longitude == null) return -1;
          
          double distA = Geolocator.distanceBetween(
            _devicePosition!.latitude,
            _devicePosition!.longitude,
            a.latitude!,
            a.longitude!,
          );
          double distB = Geolocator.distanceBetween(
            _devicePosition!.latitude,
            _devicePosition!.longitude,
            b.latitude!,
            b.longitude!,
          );
          return distA.compareTo(distB);
        });
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error fetching location or sorting: $e");
    }
  }

  List<Category> _categories = [];
  List<Category> get categories => _categories;

  Map<String, dynamic>? _dashboardStats;
  Map<String, dynamic>? get dashboardStats => _dashboardStats;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<AppSetting> _settings = [];
  List<AppSetting> get settings => _settings;

  List<AdminLog> _adminActivity = [];
  List<AdminLog> get adminActivity => _adminActivity;

  Map<String, dynamic> get adminAnalytics => _dashboardStats ?? {};

  // Filter fields
  String? _selectedStateFilter;
  String? get selectedStateFilter => _selectedStateFilter;
  
  String? _selectedCityFilter;
  String? get selectedCityFilter => _selectedCityFilter;
  
  bool _isNearMeFilter = false;
  bool get isNearMeFilter => _isNearMeFilter;

  List<Transaction> _transactions = [];
  List<Transaction> get transactions => _transactions;

  double get totalSaved {
    double total = 0.0;
    for (var tx in _transactions) {
      if (tx.status == 'REDEEMED') {
        total += tx.amountSaved;
      }
    }
    return total;
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await _api.login(username, password);
      if (data != null) {
        _isLoggedIn = true;
        _userRole = data['user']['role'];
        await refreshData();
        return true;
      }
      return false;
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signup(Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();
    try {
      final result = await _api.signup(data);
      if (result != null) {
        _isLoggedIn = true;
        _userRole = result['user']['role'];
        await refreshData();
        return true;
      }
      return false;
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadPublicData() async {
    try {
      _categories = await _api.getCategories();
      _merchants = await _api.getMerchants();
      await fetchLocationAndSort();
      notifyListeners();
    } catch (e) {
      print("Error loading public data: $e");
    }
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();
    try {
      _profile = await _api.updateProfile(data);
      notifyListeners();
    } catch (e) {
      debugPrint("Error updating profile: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> requestWithdrawal(double amount) async {
    final data = await _api.post('/profile/', {'amount': amount});
    if (data['user'] != null) {
      _profile = AppUser.fromJson(data['user']);
      notifyListeners();
    }
  }

  Future<List<dynamic>> getPayoutHistory() async {
    try {
      return await _api.get('/referral-payouts/');
    } catch (e) {
      print("Error getting payout history: $e");
      return [];
    }
  }

  Future<void> markPayoutCompleted(int id) async {
    await _api.post('/referral-payouts/$id/mark_completed/', {});
  }

  Future<void> declinePayout(int id, String remark) async {
    await _api.post('/referral-payouts/$id/decline_payout/', {'remark': remark});
  }

  Future<List<dynamic>> getAnnouncements() async {
    return await _api.get('/admin/notifications/');
  }

  Future<void> refreshData() async {
    if (!_isLoggedIn) return;
    
    _isLoading = true;
    _hasConnection = true;
    _serverAvailable = true;
    notifyListeners();
    
    try {
      final profileFuture = _api.getProfile();
      final categoriesFuture = _api.getCategories();
      final merchantsFuture = _api.getMerchants();
      
      // Wait for all to complete
      final results = await Future.wait([profileFuture, categoriesFuture, merchantsFuture]);
      
      _profile = results[0] as AppUser;
      _categories = results[1] as List<Category>;
      _merchants = results[2] as List<Merchant>;
      await fetchLocationAndSort();
      
      if (_userRole == 'admin') {
        final dashboardData = await _api.getAdminDashboard();
        _dashboardStats = dashboardData['stats'];
        if (dashboardData['recent_activity'] != null) {
          _adminActivity = (dashboardData['recent_activity'] as List)
              .map((log) => AdminLog.fromJson(log))
              .toList();
        }
        await loadSettings();
      } else if (_userRole == 'merchant') {
        final merchantData = await _api.get('/merchant/dashboard/');
        _dashboardStats = merchantData['stats'];
        if (merchantData['transactions'] != null) {
          final txList = merchantData['transactions'] as List;
          _transactions = txList
              .map((tx) => Transaction(
                transactionId: tx['code'] ?? 'TX-${tx['id']}',
                amountPaid: (tx['amount_paid'] ?? 0).toDouble(),
                amountSaved: (tx['amount_saved'] ?? 0).toDouble(),
                status: tx['status'] ?? 'completed',
                timestamp: DateTime.tryParse(tx['timestamp'] ?? '') ?? DateTime.now(),
                userName: tx['user_name'] ?? 'Customer',
              ))
              .toList();
          print("Merchant transactions loaded: ${_transactions.length}");
        }
      } else if (_userRole == 'customer') {
        try {
          final customerData = await _api.getCustomerTransactions();
          List<Transaction> all = [];
          if (customerData['payments'] != null) {
            final list = customerData['payments'] as List;
            for (var p in list) {
              all.add(Transaction(
                transactionId: p['razorpay_order_id'] ?? 'TX-${p['id']}',
                amountPaid: (p['amount'] ?? 0) / 100.0,
                status: p['status']?.toString().toUpperCase() ?? 'SUCCESS',
                timestamp: DateTime.tryParse(p['created_at'] ?? '') ?? DateTime.now(),
                userName: p['user_name'] ?? _profile?.username ?? "Me",
                merchantName: "Prime Membership Upgrade",
              ));
            }
          }
          if (customerData['vouchers'] != null) {
            final list = customerData['vouchers'] as List;
            for (var v in list) {
              all.add(Transaction(
                transactionId: v['code'] ?? 'VC-${v['id']}',
                amountPaid: (double.tryParse(v['bill_amount']?.toString() ?? '0') ?? 0),
                amountSaved: (double.tryParse(v['amount_saved']?.toString() ?? '0') ?? 0),
                status: v['used_at'] != null ? 'REDEEMED' : 'PENDING',
                timestamp: DateTime.tryParse(v['used_at'] ?? v['created_at'] ?? '') ?? DateTime.now(),
                userName: v['user_name'] ?? _profile?.username ?? "Me",
                merchantName: v['merchant_name'] ?? "Merchant #${v['merchant_profile']}",
              ));
            }
          }
          all.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          _transactions = all;
          print("Customer transactions loaded: ${_transactions.length}");
        } catch (e) {
          print("Error fetching customer transactions: $e");
        }
      }
      
      print("Data refreshed: ${_profile?.username}, ${_categories.length} categories, ${_merchants.length} merchants");
    } catch (e) {
      debugPrint("Error refreshing data: $e");
      
      String errorStr = e.toString().toLowerCase();
      if (errorStr.contains('socketexception') || 
          errorStr.contains('network is unreachable') || 
          errorStr.contains('connection timed out') || 
          errorStr.contains('failed host lookup') || 
          errorStr.contains('connection failed') || 
          errorStr.contains('connection refused') || 
          errorStr.contains('clientexception')) {
        _hasConnection = false;
        _serverAvailable = true;
      } else if (errorStr.contains('unauthorized') || errorStr.contains('401')) {
        await logout();
      } else {
        _serverAvailable = false;
        _hasConnection = true;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> checkStatus() async {
    try {
      await _api.get('/categories/');
      _hasConnection = true;
      _serverAvailable = true;
    } catch (e) {
      debugPrint("Error checkStatus: $e");
      String errorStr = e.toString().toLowerCase();
      if (errorStr.contains('socketexception') || 
          errorStr.contains('network is unreachable') || 
          errorStr.contains('connection timed out') || 
          errorStr.contains('failed host lookup') || 
          errorStr.contains('connection failed') || 
          errorStr.contains('connection refused') || 
          errorStr.contains('clientexception')) {
        _hasConnection = false;
        _serverAvailable = true;
      } else if (errorStr.contains('unauthorized') || errorStr.contains('401')) {
        await logout();
      } else {
        _serverAvailable = false;
        _hasConnection = true;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadSettings() async {
    try {
      final data = await _api.get('/settings/');
      _settings = (data as List).map((s) => AppSetting.fromJson(s)).toList();
      notifyListeners();
    } catch (e) {
      print("Error loading settings: $e");
      if (e.toString().contains('UNAUTHORIZED')) {
        await logout();
      }
    }
  }

  Future<void> createAppSetting(String key, String value) async {
    try {
      await _api.post('/settings/', {
        'key': key,
        'value': value,
      });
      await loadSettings();
    } catch (e) {
      throw Exception('Failed to create setting: $e');
    }
  }

  Future<void> updateAppSetting(int id, String value) async {
    try {
      await _api.patch('/settings/$id/', {'value': value});
      await loadSettings();
    } catch (e) {
      throw Exception('Failed to update setting: $e');
    }
  }

  Future<void> deleteAppSetting(int id) async {
    try {
      await _api.delete('/settings/$id/');
      await loadSettings();
    } catch (e) {
      throw Exception('Failed to delete setting: $e');
    }
  }

  Future<void> grantPrime(int userId) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _api.grantPrime(userId);
      await refreshData();
    } catch (e) {
      throw Exception('Failed to grant Prime: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> revokePrime(int userId) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _api.revokePrime(userId);
      await refreshData();
    } catch (e) {
      throw Exception('Failed to revoke Prime: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> processPayout(int userId, double amount) async {
    await _api.processPayout(userId, amount);
    await refreshData();
  }

  Future<void> restoreMerchant(int id) async {
    await _api.restoreMerchant(id);
    await refreshData();
  }

  Future<void> adminResetUserPassword(int userId, String newPass) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _api.post('/users/$userId/reset_password/', {'password': newPass});
    } catch (e) {
      throw Exception('Failed to reset password: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> changePassword(String old, String newPass) async {
    try {
      await _api.post('/auth/change_password/', {
        'old_password': old,
        'new_password': newPass,
      });
    } catch (e) {
      throw Exception('Failed to change password: $e');
    }
  }

  Future<void> updateMerchant(int id, Map<String, dynamic> data, {http.MultipartFile? imageFile}) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _api.updateMerchant(id, data, imageFile: imageFile);
      await refreshData();
    } catch (e) {
      debugPrint("Error updating merchant: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> upgradeToPrime(double price, {String? referralCode}) async {
    _isLoading = true;
    notifyListeners();
    try {
      if (_profile != null) {
        await _api.post('/users/${_profile!.id}/grant_prime/', {
          'price': price,
          'referral_code': referralCode,
        });
        await refreshData();
      }
    } catch (e) {
      debugPrint('Upgrade error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> buyPrimeSimulated({String? referralCode}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _api.post('/users/fake_purchase_prime/', {
        if (referralCode != null && referralCode.isNotEmpty) 'referral_code': referralCode,
      });
      if (response != null && response['status'] == 'success') {
        await refreshData();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Simulated purchase error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendNotification(String target, String title, String msg) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _api.post('/admin/notifications/', {
        'target': target,
        'title': title,
        'message': msg,
      });
    } catch (e) {
      throw Exception('Failed to send announcement: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteAnnouncement(int id) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _api.delete('/admin/notifications/$id/');
    } catch (e) {
      throw Exception('Failed to delete announcement: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> filterMerchants(String? category, {String? state, String? city, bool? nearMe}) async {
    _selectedStateFilter = state;
    _selectedCityFilter = city;
    _isNearMeFilter = nearMe ?? false;
    _merchants = await _api.getMerchants(category: category);
    notifyListeners();
  }

  Future<List<AppUser>> getAppUsers() async {
    try {
      final response = await _api.get('/users/');
      return (response as List).map((u) => AppUser.fromJson(u)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> deleteMerchant(int id) async {
    try {
      await _api.delete('/merchants/$id/');
      await refreshData();
    } catch (e) {
      throw Exception('Failed to delete merchant: $e');
    }
  }

  Future<void> deleteAppUser(int id) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _api.delete('/users/$id/');
      await refreshData();
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> adminCreateStaff(Map<String, dynamic> data) async {
    try {
      await _api.post('/users/admin_create_staff/', data);
      await refreshData();
    } catch (e) {
      throw Exception('Failed to create staff: $e');
    }
  }

  Future<void> adminCreateMerchant(Map<String, dynamic> data, {http.MultipartFile? imageFile}) async {
    try {
      if (imageFile != null) {
        await _api.postMultipart('/users/admin_create_merchant/', data, file: imageFile);
      } else {
        await _api.post('/users/admin_create_merchant/', data);
      }
      await refreshData();
    } catch (e) {
      throw Exception('Failed to create merchant: $e');
    }
  }

  Future<void> toggleAppUserBlock(int id) async {
    _isLoading = true;
    notifyListeners();
    try {
      final users = await getAppUsers();
      final user = users.firstWhere((u) => u.id == id);
      final newStatus = user.status == 'active' ? 'blocked' : 'active';
      await _api.patch('/users/$id/', {'status': newStatus});
      await refreshData();
    } catch (e) {
      throw Exception('Failed to toggle user status: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addCategory(String name) async {
    try {
      await _api.post('/categories/', {'name': name, 'slug': name.toLowerCase().replaceAll(' ', '-')});
      await refreshData();
    } catch (e) {
      throw Exception('Failed to add category: $e');
    }
  }

  Future<void> deleteCategory(int id) async {
    try {
      await _api.delete('/categories/$id/');
      await refreshData();
    } catch (e) {
      throw Exception('Failed to delete category: $e');
    }
  }

  Future<List<Transaction>> getAdminTransactions({
    int? merchantId,
    String? status,
    String? dateFrom,
    String? dateTo,
  }) async {
    try {
      final paymentsJson = await _api.getAdminPayments();
      final vouchersJson = await _api.getAdminVouchers();
      
      List<Transaction> all = [];
      
      for (var p in paymentsJson) {
        final purpose = p['purpose']?.toString() ?? 'prime_membership';
        final isPrime = purpose == 'prime_membership';
        all.add(Transaction(
          transactionId: p['razorpay_order_id'] ?? 'TX-${p['id']}',
          amountPaid: (p['amount'] ?? 0) / 100.0,
          status: p['status']?.toString().toUpperCase() ?? 'SUCCESS',
          timestamp: DateTime.tryParse(p['created_at'] ?? '') ?? DateTime.now(),
          userName: p['user_name'] ?? "User #${p['user']}",
          merchantName: isPrime ? "System (Prime)" : purpose,
        ));
      }
      
      for (var v in vouchersJson) {
        all.add(Transaction(
          transactionId: v['code'] ?? 'VC-${v['id']}',
          amountPaid: double.tryParse(v['bill_amount']?.toString() ?? '0') ?? 0.0,
          amountSaved: double.tryParse(v['amount_saved']?.toString() ?? '0') ?? 0.0,
          status: v['used_at'] != null ? 'REDEEMED' : 'PENDING',
          timestamp: DateTime.tryParse(v['used_at'] ?? v['created_at'] ?? '') ?? DateTime.now(),
          userName: v['user_name'] ?? "User #${v['user']}",
          merchantName: v['merchant_name'] ?? "Merchant #${v['merchant_profile']}",
        ));
      }

      all.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      _transactions = all;
      notifyListeners();
      return all;
    } catch (e) {
      print("Error fetching transactions: $e");
      return [];
    }
  }

  Future<dynamic> createRazorpayOrder(double amount, {String? purpose}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await _api.createRazorpayOrder(amount, purpose: purpose);
      return res;
    } catch (e) {
      debugPrint("Error creating Razorpay order: $e");
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> verifyRazorpayPayment({
    required String orderId,
    required String paymentId,
    required String signature,
    String? referralCode,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _api.verifyRazorpayPayment(orderId, paymentId, signature, referralCode: referralCode);
      if (response != null && response['status'] == 'success') {
        await refreshData();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Error verifying payment: $e");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _api.setToken(null);
    _isLoggedIn = false;
    _userRole = null;
    _profile = null;
    notifyListeners();
  }

  Future<Map<String, dynamic>?> verifyUser(String query) async {
    _isLoading = true;
    notifyListeners();
    try {
      return await _api.verifyUser(query);
    } catch (e) {
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> redeemDiscount(int userId, double billAmount) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _api.redeem(userId, billAmount);
      await refreshData();
      return true;
    } catch (e) {
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> customerPay(int merchantId, double billAmount) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _api.customerPay(merchantId, billAmount);
      await refreshData();
      return true;
    } catch (e) {
      debugPrint("Error in customerPay: $e");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }}
