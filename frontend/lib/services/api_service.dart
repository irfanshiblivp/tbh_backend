import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/models/models.dart';

class ApiService {
  // Use production URL
  static const String baseUrl = 'http://10.71.54.62:8000/api';
  // static const String baseUrl = 'https://thebaronclub.com/api'; // Production URL

  String? _token;

  void setToken(String? token) {
    _token = token;
  }

  bool _isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;
      
      String payload = parts[1];
      int padding = 4 - (payload.length % 4);
      if (padding > 0 && padding < 4) {
        payload += '=' * padding;
      }
      
      final String decoded = utf8.decode(base64Url.decode(payload));
      final Map<String, dynamic> json = jsonDecode(decoded);
      final int? exp = json['exp'];
      if (exp == null) return false;
      
      final int nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      return exp < (nowSeconds + 10);
    } catch (e) {
      return true;
    }
  }

  Future<bool> refreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refresh = prefs.getString('refresh_token');
      if (refresh == null || refresh.isEmpty) return false;

      final response = await http.post(
        Uri.parse('$baseUrl/auth/token/refresh/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': refresh}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['access'];
        await prefs.setString('access_token', _token!);
        if (data['refresh'] != null) {
          await prefs.setString('refresh_token', data['refresh']);
        }
        return true;
      }
    } catch (e) {
      print("Token refresh error: $e");
    }
    return false;
  }

  Future<Map<String, String>> _getHeaders() async {
    if (_token == null) {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('access_token');
    }

    if (_token != null && _isTokenExpired(_token!)) {
      final success = await refreshToken();
      if (!success) {
        _token = null;
      }
    }

    return {
      'Content-Type': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
  }

  Future<Map<String, dynamic>?> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _token = data['access'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', data['access']);
      await prefs.setString('refresh_token', data['refresh']);
      await prefs.setString('user_role', data['user']['role']);
      return data;
    }
    final errorData = jsonDecode(response.body);
    throw Exception(errorData['error'] ?? errorData['detail'] ?? 'Login failed (${response.statusCode})');
  }

  Future<Map<String, dynamic>?> signup(Map<String, dynamic> userData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/signup/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(userData),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', data['access']);
      await prefs.setString('refresh_token', data['refresh']);
      if (data['user'] != null && data['user']['role'] != null) {
        await prefs.setString('user_role', data['user']['role']);
      }
      return data;
    }
    final errorData = jsonDecode(response.body);
    throw Exception(errorData['error'] ?? errorData['detail'] ?? 'Signup failed');
  }

  Future<List<Merchant>> getMerchants({String? category}) async {
    final url = category != null ? '$baseUrl/merchants/?category=$category' : '$baseUrl/merchants/';
    final response = await http.get(Uri.parse(url), headers: await _getHeaders()).timeout(const Duration(seconds: 15));
    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((m) => Merchant.fromJson(m)).toList();
    }
    throw Exception('Failed to load merchants');
  }

  Future<List<Category>> getCategories() async {
    final response = await http.get(Uri.parse('$baseUrl/categories/'), headers: await _getHeaders());
    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((c) => Category.fromJson(c)).toList();
    }
    throw Exception('Failed to load categories');
  }

  Future<AppUser> getProfile() async {
    final url = '$baseUrl/profile/';
    final response = await http.get(Uri.parse(url), headers: await _getHeaders()).timeout(const Duration(seconds: 15));
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return AppUser.fromJson(data);
    }
    throw Exception('Failed to load profile (Status: ${response.statusCode})');
  }

  Future<AppUser> updateProfile(Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/profile/'),
      headers: await _getHeaders(),
      body: jsonEncode(data),
    );
    if (response.statusCode == 200) {
      return AppUser.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to update profile');
  }

  Future<Map<String, dynamic>> getAdminDashboard() async {
    final response = await http.get(Uri.parse('$baseUrl/admin/dashboard/'), headers: await _getHeaders());
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load dashboard');
  }

  Future<void> adminCreateStaff(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/admin_create_staff/'),
      headers: await _getHeaders(),
      body: jsonEncode(data),
    );
    if (response.statusCode != 201) throw Exception('Failed to create staff');
  }

  Future<List<AppUser>> getAppUsers() async {
    final response = await http.get(Uri.parse('$baseUrl/users/'), headers: await _getHeaders());
    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((u) => AppUser.fromJson(u)).toList();
    }
    throw Exception('Failed to load users');
  }

  Future<void> deleteAppUser(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/users/$id/'), headers: await _getHeaders());
    if (response.statusCode != 204) throw Exception('Failed to delete user');
  }

  Future<void> deleteMerchant(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/merchants/$id/'), headers: await _getHeaders());
    if (response.statusCode != 204) throw Exception('Failed to delete merchant');
  }

  Future<void> grantPrime(int userId) async {
    await http.post(Uri.parse('$baseUrl/users/$userId/grant_prime/'), headers: await _getHeaders());
  }

  Future<void> revokePrime(int userId) async {
    await http.post(Uri.parse('$baseUrl/users/$userId/revoke_prime/'), headers: await _getHeaders());
  }

  Future<void> processPayout(int userId, double amount) async {
    await http.post(Uri.parse('$baseUrl/users/$userId/process_payout/'), headers: await _getHeaders(), body: jsonEncode({'amount': amount}));
  }

  Future<void> restoreMerchant(int id) async {
    await http.post(Uri.parse('$baseUrl/merchants/$id/restore/'), headers: await _getHeaders());
  }

  Future<void> updateUserStatus(int id, String status) async {
    await http.patch(Uri.parse('$baseUrl/users/$id/'), headers: await _getHeaders(), body: jsonEncode({'status': status}));
  }

  Future<void> updateMerchant(int id, Map<String, dynamic> data, {http.MultipartFile? imageFile}) async {
    if (imageFile != null) {
      final uri = Uri.parse('$baseUrl/merchants/$id/');
      final request = http.MultipartRequest('PATCH', uri);
      
      final headers = await _getHeaders();
      headers.remove('Content-Type'); // Let the request set the correct boundary
      request.headers.addAll(headers);

      data.forEach((key, value) {
        if (value != null) request.fields[key] = value.toString();
      });
      
      request.files.add(imageFile);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode != 200 && response.statusCode != 201 && response.statusCode != 204) {
        throw Exception('Failed to update merchant profile image: ${response.statusCode} - ${response.body}');
      }
    } else {
      final response = await http.patch(
        Uri.parse('$baseUrl/merchants/$id/'),
        headers: await _getHeaders(),
        body: jsonEncode(data),
      );
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to update merchant profile: ${response.statusCode}');
      }
    }
  }

  Future<Map<String, dynamic>> verifyUser(String query) async {
    final response = await http.get(Uri.parse('$baseUrl/merchants/verify_user/?query=$query'), headers: await _getHeaders());
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('User not found');
  }

  Future<void> redeem(int userId, double billAmount) async {
    await http.post(Uri.parse('$baseUrl/merchants/redeem/'), headers: await _getHeaders(), body: jsonEncode({
      'user_id': userId,
      'bill_amount': billAmount
    }));
  }

  Future<List<dynamic>> getAdminPayments() async {
    final response = await http.get(Uri.parse('$baseUrl/admin/payments/'), headers: await _getHeaders());
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load payments');
  }

  Future<List<dynamic>> getAdminVouchers() async {
    final response = await http.get(Uri.parse('$baseUrl/admin/vouchers/'), headers: await _getHeaders());
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load vouchers');
  }

  // Generic methods
  Future<dynamic> get(String endpoint) async {
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _getHeaders(),
    ).timeout(const Duration(seconds: 15));
    return _handleResponse(response);
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _getHeaders(),
      body: jsonEncode(data),
    ).timeout(const Duration(seconds: 15));
    return _handleResponse(response);
  }

  Future<dynamic> put(String endpoint, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _getHeaders(),
      body: jsonEncode(data),
    ).timeout(const Duration(seconds: 15));
    return _handleResponse(response);
  }

  Future<dynamic> patch(String endpoint, Map<String, dynamic> data) async {
    final response = await http.patch(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _getHeaders(),
      body: jsonEncode(data),
    ).timeout(const Duration(seconds: 15));
    return _handleResponse(response);
  }

  Future<dynamic> delete(String endpoint) async {
    final response = await http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _getHeaders(),
    ).timeout(const Duration(seconds: 15));
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response.body.isNotEmpty ? jsonDecode(response.body) : null;
    }
    return _handleResponse(response);
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        return response.body.isNotEmpty ? jsonDecode(response.body) : null;
      } catch (e) {
        throw Exception('Server returned invalid JSON format');
      }
    }
    if (response.statusCode == 401) {
      throw Exception('UNAUTHORIZED');
    }
    try {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['error'] ?? errorData['detail'] ?? 'Request failed (${response.statusCode})');
    } catch (e) {
      throw Exception('Request failed with status ${response.statusCode}');
    }
  }

  Future<dynamic> postMultipart(String endpoint, Map<String, dynamic> data, {http.MultipartFile? file}) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final request = http.MultipartRequest('POST', uri);
    
    final headers = await _getHeaders();
    headers.remove('Content-Type'); // Let the request set it for multipart
    request.headers.addAll(headers);
    
    data.forEach((key, value) {
      if (value != null) request.fields[key] = value.toString();
    });
    
    if (file != null) {
      request.files.add(file);
    }
    
    final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
    final response = await http.Response.fromStream(streamedResponse);
    return _handleResponse(response);
  }

  Future<dynamic> customerPay(int merchantId, double billAmount) async {
    final response = await http.post(
      Uri.parse('$baseUrl/merchants/$merchantId/customer_pay/'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'bill_amount': billAmount,
      }),
    ).timeout(const Duration(seconds: 30));
    return _handleResponse(response);
  }

  Future<dynamic> createRazorpayOrder(double amount, {String? purpose}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/razorpay/create-order/'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'amount': amount,
        if (purpose != null) 'purpose': purpose,
      }),
    ).timeout(const Duration(seconds: 30));
    return _handleResponse(response);
  }

  Future<dynamic> verifyRazorpayPayment(String orderId, String paymentId, String signature, {String? referralCode}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/razorpay/verify/'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'razorpay_order_id': orderId,
        'razorpay_payment_id': paymentId,
        'razorpay_signature': signature,
        if (referralCode != null && referralCode.isNotEmpty) 'referral_code': referralCode,
      }),
    ).timeout(const Duration(seconds: 30));
    return _handleResponse(response);
  }

  Future<dynamic> getCustomerTransactions() async {
    final response = await http.get(
      Uri.parse('$baseUrl/customer/transactions/'),
      headers: await _getHeaders(),
    ).timeout(const Duration(seconds: 30));
    return _handleResponse(response);
  }
}
