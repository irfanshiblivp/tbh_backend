import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/models/models.dart';

class AppError implements Exception {
  final String message;
  AppError(this.message);

  @override
  String toString() => message;
}

class ApiService {
  static const String baseUrl =
      'https://api.thebaronclub.com/api'; // ✅ Production

  String? _token;
  void Function()? onSessionExpired;

  void setToken(String? token) {
    _token = token;
  }

  static AppError parseError(dynamic e) {
    if (e is AppError) return e;

    final String msg = e.toString();

    // Check for network connection issues
    if (msg.contains('SocketException') ||
        msg.contains('Connection refused') ||
        msg.contains('Network is unreachable') ||
        msg.contains('Connection failed') ||
        msg.contains('ClientException') ||
        msg.contains('HandshakeException')) {
      return AppError(
        "Unable to connect to our servers. Please check your internet connection and try again.",
      );
    }

    if (msg.contains('TimeoutException') ||
        msg.toLowerCase().contains('timeout')) {
      return AppError(
        "The connection timed out. Please check your internet strength and try again.",
      );
    }

    // Clean any existing Exception: prefixes
    String cleanMsg = msg;
    if (cleanMsg.startsWith('Exception: ')) {
      cleanMsg = cleanMsg.substring('Exception: '.length);
    } else if (cleanMsg.startsWith('Exception:')) {
      cleanMsg = cleanMsg.substring('Exception:'.length);
    }

    return AppError(cleanMsg);
  }

  static String _cleanBackendError(dynamic error) {
    if (error == null) return 'An unexpected error occurred.';
    if (error is List) {
      return error.map((e) => _cleanBackendError(e)).join(', ');
    }
    if (error is Map) {
      final List<String> fieldErrors = [];
      error.forEach((key, value) {
        final cleanKey = _capitalize(key.toString().replaceAll('_', ' '));
        if (value is List) {
          fieldErrors.add(
            '$cleanKey: ${value.map((v) => _cleanBackendError(v)).join(", ")}',
          );
        } else {
          fieldErrors.add('$cleanKey: ${_cleanBackendError(value)}');
        }
      });
      return fieldErrors.join('\n');
    }

    String msg = error.toString();
    if (msg.contains('Signature has expired')) {
      return 'Your session has expired. Please log in again.';
    }
    if (msg.contains('Invalid password')) {
      return 'The password you entered is incorrect.';
    }
    return msg;
  }

  static String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
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
      log("Token refresh error: $e");
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
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/login/'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'username': username, 'password': password}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['access'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', data['access']);
        await prefs.setString('refresh_token', data['refresh']);
        await prefs.setString('user_role', data['user']['role']);
        return data;
      }
      _handleResponse(response);
      return null;
    } catch (e) {
      throw parseError(e);
    }
  }

  Future<Map<String, dynamic>?> signup(Map<String, dynamic> userData) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/signup/'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(userData),
          )
          .timeout(const Duration(seconds: 15));

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
      _handleResponse(response);
      return null;
    } catch (e) {
      throw parseError(e);
    }
  }

  Future<List<Merchant>> getMerchants({String? category}) async {
    try {
      final url = category != null
          ? '$baseUrl/merchants/?category=$category'
          : '$baseUrl/merchants/';
      final response = await http
          .get(Uri.parse(url), headers: await _getHeaders())
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        List data = jsonDecode(response.body);
        return data.map((m) => Merchant.fromJson(m)).toList();
      }
      _handleResponse(response);
      return [];
    } catch (e) {
      throw parseError(e);
    }
  }

  Future<List<Category>> getCategories() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/categories/'), headers: await _getHeaders())
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        List data = jsonDecode(response.body);
        return data.map((c) => Category.fromJson(c)).toList();
      }
      _handleResponse(response);
      return [];
    } catch (e) {
      throw parseError(e);
    }
  }

  Future<AppUser> getProfile() async {
    try {
      final url = '$baseUrl/profile/';
      final response = await http
          .get(Uri.parse(url), headers: await _getHeaders())
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return AppUser.fromJson(data);
      }
      _handleResponse(response);
      throw AppError('Failed to load profile');
    } catch (e) {
      throw parseError(e);
    }
  }

  Future<AppUser> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await http
          .put(
            Uri.parse('$baseUrl/profile/'),
            headers: await _getHeaders(),
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        return AppUser.fromJson(jsonDecode(response.body));
      }
      _handleResponse(response);
      throw AppError('Failed to update profile');
    } catch (e) {
      throw parseError(e);
    }
  }

  Future<Map<String, dynamic>> getAdminDashboard() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/admin/dashboard/'),
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) return jsonDecode(response.body);
      _handleResponse(response);
      throw AppError('Failed to load dashboard');
    } catch (e) {
      throw parseError(e);
    }
  }

  Future<void> adminCreateStaff(Map<String, dynamic> data) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/users/admin_create_staff/'),
            headers: await _getHeaders(),
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 201) {
        _handleResponse(response);
      }
    } catch (e) {
      throw parseError(e);
    }
  }

  Future<List<AppUser>> getAppUsers() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/users/'), headers: await _getHeaders())
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        List data = jsonDecode(response.body);
        return data.map((u) => AppUser.fromJson(u)).toList();
      }
      _handleResponse(response);
      return [];
    } catch (e) {
      throw parseError(e);
    }
  }

  Future<void> deleteAppUser(int id) async {
    try {
      final response = await http
          .delete(
            Uri.parse('$baseUrl/users/$id/'),
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 204) {
        _handleResponse(response);
      }
    } catch (e) {
      throw parseError(e);
    }
  }

  Future<void> deleteMerchant(int id) async {
    try {
      final response = await http
          .delete(
            Uri.parse('$baseUrl/merchants/$id/'),
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 204) {
        _handleResponse(response);
      }
    } catch (e) {
      throw parseError(e);
    }
  }

  Future<void> grantPrime(int userId) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/users/$userId/grant_prime/'),
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200 && response.statusCode != 204) {
        _handleResponse(response);
      }
    } catch (e) {
      throw parseError(e);
    }
  }

  Future<void> revokePrime(int userId) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/users/$userId/revoke_prime/'),
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200 && response.statusCode != 204) {
        _handleResponse(response);
      }
    } catch (e) {
      throw parseError(e);
    }
  }

  Future<void> processPayout(int userId, double amount) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/users/$userId/process_payout/'),
            headers: await _getHeaders(),
            body: jsonEncode({'amount': amount}),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200 && response.statusCode != 204) {
        _handleResponse(response);
      }
    } catch (e) {
      throw parseError(e);
    }
  }

  Future<void> restoreMerchant(int id) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/merchants/$id/restore/'),
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200 && response.statusCode != 204) {
        _handleResponse(response);
      }
    } catch (e) {
      throw parseError(e);
    }
  }

  Future<void> updateUserStatus(int id, String status) async {
    try {
      final response = await http
          .patch(
            Uri.parse('$baseUrl/users/$id/'),
            headers: await _getHeaders(),
            body: jsonEncode({'status': status}),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200 && response.statusCode != 204) {
        _handleResponse(response);
      }
    } catch (e) {
      throw parseError(e);
    }
  }

  Future<void> updateMerchant(
    int id,
    Map<String, dynamic> data, {
    http.MultipartFile? imageFile,
  }) async {
    try {
      if (imageFile != null) {
        final uri = Uri.parse('$baseUrl/merchants/$id/');
        final request = http.MultipartRequest('PATCH', uri);

        final headers = await _getHeaders();
        headers.remove(
          'Content-Type',
        ); // Let the request set the correct boundary
        request.headers.addAll(headers);

        data.forEach((key, value) {
          if (value != null) request.fields[key] = value.toString();
        });

        request.files.add(imageFile);

        final streamedResponse = await request.send().timeout(
          const Duration(seconds: 30),
        );
        final response = await http.Response.fromStream(streamedResponse);
        if (response.statusCode != 200 &&
            response.statusCode != 201 &&
            response.statusCode != 204) {
          _handleResponse(response);
        }
      } else {
        final response = await http
            .patch(
              Uri.parse('$baseUrl/merchants/$id/'),
              headers: await _getHeaders(),
              body: jsonEncode(data),
            )
            .timeout(const Duration(seconds: 15));
        if (response.statusCode != 200 && response.statusCode != 204) {
          _handleResponse(response);
        }
      }
    } catch (e) {
      throw parseError(e);
    }
  }

  Future<Map<String, dynamic>> verifyUser(String query) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/merchants/verify_user/?query=$query'),
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) return jsonDecode(response.body);
      _handleResponse(response);
      throw AppError('User not found');
    } catch (e) {
      throw parseError(e);
    }
  }

  Future<void> redeem(int userId, double billAmount) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/merchants/redeem/'),
            headers: await _getHeaders(),
            body: jsonEncode({'user_id': userId, 'bill_amount': billAmount}),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200 && response.statusCode != 204) {
        _handleResponse(response);
      }
    } catch (e) {
      throw parseError(e);
    }
  }

  Future<List<dynamic>> getAdminPayments() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/admin/payments/'),
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) return jsonDecode(response.body);
      _handleResponse(response);
      return [];
    } catch (e) {
      throw parseError(e);
    }
  }

  Future<List<dynamic>> getAdminVouchers() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/admin/vouchers/'),
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) return jsonDecode(response.body);
      _handleResponse(response);
      return [];
    } catch (e) {
      throw parseError(e);
    }
  }

  // Generic methods
  Future<dynamic> get(String endpoint) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl$endpoint'), headers: await _getHeaders())
          .timeout(const Duration(seconds: 15));
      return _handleResponse(response);
    } catch (e) {
      throw parseError(e);
    }
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl$endpoint'),
            headers: await _getHeaders(),
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 15));
      return _handleResponse(response);
    } catch (e) {
      throw parseError(e);
    }
  }

  Future<dynamic> put(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http
          .put(
            Uri.parse('$baseUrl$endpoint'),
            headers: await _getHeaders(),
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 15));
      return _handleResponse(response);
    } catch (e) {
      throw parseError(e);
    }
  }

  Future<dynamic> patch(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http
          .patch(
            Uri.parse('$baseUrl$endpoint'),
            headers: await _getHeaders(),
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 15));
      return _handleResponse(response);
    } catch (e) {
      throw parseError(e);
    }
  }

  Future<dynamic> delete(String endpoint) async {
    try {
      final response = await http
          .delete(Uri.parse('$baseUrl$endpoint'), headers: await _getHeaders())
          .timeout(const Duration(seconds: 15));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response.body.isNotEmpty ? jsonDecode(response.body) : null;
      }
      return _handleResponse(response);
    } catch (e) {
      throw parseError(e);
    }
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode == 401 || response.statusCode == 403) {
      if (onSessionExpired != null) {
        onSessionExpired!();
      }
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        return response.body.isNotEmpty ? jsonDecode(response.body) : null;
      } catch (e) {
        throw AppError(
          'The server returned an invalid format. Please try again.',
        );
      }
    }

    try {
      final errorData = jsonDecode(response.body);
      if (errorData is Map) {
        if (errorData.containsKey('error') && errorData['error'] != null) {
          throw AppError(_cleanBackendError(errorData['error']));
        }
        if (errorData.containsKey('detail') && errorData['detail'] != null) {
          throw AppError(_cleanBackendError(errorData['detail']));
        }
        if (errorData.containsKey('non_field_errors') &&
            errorData['non_field_errors'] != null) {
          throw AppError(_cleanBackendError(errorData['non_field_errors']));
        }

        // Handle generic field errors like {"email": ["Enter a valid email address."]}
        final List<String> fieldErrors = [];
        errorData.forEach((key, value) {
          final cleanKey = _capitalize(key.toString().replaceAll('_', ' '));
          if (value is List) {
            fieldErrors.add(
              '$cleanKey: ${value.map((v) => _cleanBackendError(v)).join(", ")}',
            );
          } else if (value is Map) {
            fieldErrors.add('$cleanKey: ${_cleanBackendError(value)}');
          } else {
            fieldErrors.add('$cleanKey: ${_cleanBackendError(value)}');
          }
        });
        if (fieldErrors.isNotEmpty) {
          throw AppError(fieldErrors.join('\n'));
        }
      }
    } catch (_) {
      // Ignore JSON parse errors here, let standard status checks run
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw AppError(
        'Your session has expired or you do not have permission. Please log in again.',
      );
    }

    if (response.statusCode == 404) {
      throw AppError(
        'The requested resource could not be found. Please try again later.',
      );
    }

    if (response.statusCode >= 500) {
      throw AppError(
        'We are experiencing temporary server difficulties. Please try again shortly.',
      );
    }

    throw AppError('Request failed (Status: ${response.statusCode})');
  }

  Future<dynamic> postMultipart(
    String endpoint,
    Map<String, dynamic> data, {
    http.MultipartFile? file,
  }) async {
    try {
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

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final response = await http.Response.fromStream(streamedResponse);
      return _handleResponse(response);
    } catch (e) {
      throw parseError(e);
    }
  }

  Future<dynamic> customerPay(
    int merchantId,
    double billAmount, {
    String paymentMethod = 'ONLINE',
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/merchants/$merchantId/customer_pay/'),
            headers: await _getHeaders(),
            body: jsonEncode({
              'bill_amount': billAmount,
              'payment_method': paymentMethod,
            }),
          )
          .timeout(const Duration(seconds: 30));
      return _handleResponse(response);
    } catch (e) {
      throw parseError(e);
    }
  }

  Future<dynamic> createRazorpayOrder(double amount, {String? purpose}) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/razorpay/create-order/'),
            headers: await _getHeaders(),
            body: jsonEncode({'amount': amount, 'purpose': ?purpose}),
          )
          .timeout(const Duration(seconds: 30));
      return _handleResponse(response);
    } catch (e) {
      throw parseError(e);
    }
  }

  Future<dynamic> verifyRazorpayPayment(
    String orderId,
    String paymentId,
    String signature, {
    String? referralCode,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/razorpay/verify/'),
            headers: await _getHeaders(),
            body: jsonEncode({
              'razorpay_order_id': orderId,
              'razorpay_payment_id': paymentId,
              'razorpay_signature': signature,
              if (referralCode != null && referralCode.isNotEmpty)
                'referral_code': referralCode,
            }),
          )
          .timeout(const Duration(seconds: 30));
      return _handleResponse(response);
    } catch (e) {
      throw parseError(e);
    }
  }

  Future<dynamic> getCustomerTransactions() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/customer/transactions/'),
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: 30));
      return _handleResponse(response);
    } catch (e) {
      throw parseError(e);
    }
  }

  Future<List<HeroBanner>> getHeroBanners() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/hero-banners/'),
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: 15));
      final dynamic decoded = _handleResponse(response);
      if (decoded is List) {
        return decoded.map((json) => HeroBanner.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw parseError(e);
    }
  }

  Future<void> uploadHeroBanner(http.MultipartFile imageFile) async {
    try {
      final uri = Uri.parse('$baseUrl/hero-banners/');
      final request = http.MultipartRequest('POST', uri);

      final headers = await _getHeaders();
      headers.remove('Content-Type');
      request.headers.addAll(headers);

      request.files.add(imageFile);

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode != 200 &&
          response.statusCode != 201 &&
          response.statusCode != 204) {
        _handleResponse(response);
      }
    } catch (e) {
      throw parseError(e);
    }
  }

  Future<void> deleteHeroBanner(int bannerId) async {
    try {
      final response = await http
          .delete(
            Uri.parse('$baseUrl/hero-banners/$bannerId/'),
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200 && response.statusCode != 204) {
        _handleResponse(response);
      }
    } catch (e) {
      throw parseError(e);
    }
  }
}
