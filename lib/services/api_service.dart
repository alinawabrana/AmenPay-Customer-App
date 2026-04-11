import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:palmpay/services/storage_service.dart';

import '../features/authentication/models/profile/user_model.dart';

class ApiService {
  static const String baseUrl = 'https://amenpay.org/api';
  static const String _publicStorageBaseUrl =
      'https://amenpay.org/storage/app/public/';

  static final List<String> _debugLogBuffer = <String>[];
  static const int _debugLogBufferMaxLines = 400;

  static String getPalmEnrollmentLogDump() {
    return _debugLogBuffer.where((l) => l.contains('PALM ENROLL')).join('\n');
  }

  static Future<Map<String, String>> _bearerHeaders() async {
    final token = await StorageService.getAuthToken();
    if (token == null) {
      throw Exception('No authentication token found');
    }

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Utility logger
  static void _log(String title, dynamic data) {
    final ts = DateTime.now().toIso8601String();
    final line = '$ts | $title: ${_sanitizeForLog(data)}';

    _debugLogBuffer.add(line);
    if (_debugLogBuffer.length > _debugLogBufferMaxLines) {
      _debugLogBuffer.removeRange(
        0,
        _debugLogBuffer.length - _debugLogBufferMaxLines,
      );
    }

    // ignore: avoid_print
    print('📡 [API] $line');
  }

  static String _sanitizeForLog(dynamic data) {
    try {
      if (data == null) return 'null';
      if (data is Map || data is List) {
        return _sanitizeString(jsonEncode(_sanitizeObject(data)));
      }
      return _sanitizeString(data.toString());
    } catch (_) {
      return _sanitizeString(data.toString());
    }
  }

  static dynamic _sanitizeObject(dynamic obj) {
    if (obj is Map) {
      final out = <String, dynamic>{};
      for (final entry in obj.entries) {
        final key = entry.key.toString();
        final normalized = key.toLowerCase();
        if (normalized == 'password' ||
            normalized == 'password_confirmation' ||
            normalized == 'token' ||
            normalized == 'authorization' ||
            normalized == 'api_key' ||
            normalized == 'cvv') {
          out[key] = '******';
          continue;
        }
        if (normalized == 'card_number') {
          out[key] = '****';
          continue;
        }
        if (normalized == 'qr_data') {
          out[key] = '***';
          continue;
        }
        out[key] = _sanitizeObject(entry.value);
      }
      return out;
    }
    if (obj is List) {
      return obj.map(_sanitizeObject).toList();
    }
    if (obj is String) return _sanitizeString(obj);
    return obj;
  }

  static String _sanitizeString(String input) {
    var out = input;
    out = out.replaceAll(
      RegExp(r'Bearer\s+([A-Za-z0-9\-\._]+)'),
      'Bearer ******',
    );
    out = out.replaceAllMapped(
      RegExp(r'("token"\s*:\s*")[^"]*(")'),
      (m) => '${m[1]}******${m[2]}',
    );
    out = out.replaceAllMapped(
      RegExp(r'("api_key"\s*:\s*")[^"]*(")'),
      (m) => '${m[1]}******${m[2]}',
    );
    out = out.replaceAllMapped(
      RegExp(r'("qr_data"\s*:\s*")[^"]*(")'),
      (m) => '${m[1]}***${m[2]}',
    );
    return out;
  }

  static String? normalizePublicImageUrl(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      // Backend sometimes returns a full URL but missing /app/public.
      const wrongPrefix = 'https://amenpay.org/storage/';
      const correctPrefix = 'https://amenpay.org/storage/app/public/';
      if (trimmed.startsWith(wrongPrefix) &&
          !trimmed.startsWith(correctPrefix)) {
        return '$correctPrefix${trimmed.substring(wrongPrefix.length)}';
      }
      return trimmed;
    }

    final path = trimmed.startsWith('/') ? trimmed.substring(1) : trimmed;

    if (path.startsWith('storage/app/public/')) {
      return 'https://amenpay.org/$path';
    }

    if (path.startsWith('storage/')) {
      return '$_publicStorageBaseUrl${path.substring('storage/'.length)}';
    }

    return '$_publicStorageBaseUrl$path';
  }

  /// Login API
  /// POST /api/login
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final url = '$baseUrl/login';

      _log('LOGIN → URL', url);
      _log('LOGIN → BODY', {
        'email': email,
        'password': '******', // mask password
      });

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      _log('LOGIN → STATUS', response.statusCode);
      _log('LOGIN → RESPONSE', response.body);

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        if (responseData.containsKey('token')) {
          await StorageService.saveAuthToken(responseData['token'] as String);
        } else if (responseData.containsKey('data') &&
            responseData['data'] is Map &&
            (responseData['data'] as Map).containsKey('token')) {
          await StorageService.saveAuthToken(
            (responseData['data'] as Map)['token'] as String,
          );
        }
        return responseData;
      } else {
        throw Exception(responseData['message'] ?? 'Login failed');
      }
    } catch (e) {
      _log('LOGIN → ERROR', e);
      throw Exception('Login error: $e');
    }
  }

  /// Signup API
  /// POST /api/signup
  static Future<Map<String, dynamic>> signup({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
    required String passwordConfirmation,
    required String securityAnswer1,
    required String securityAnswer2,
  }) async {
    try {
      final url = '$baseUrl/signup';

      _log('SIGNUP → URL', url);
      _log('SIGNUP → BODY', {
        'full_name': fullName,
        'email': email,
        'phone_number': phoneNumber,
        'password': '******',
        'security_answer_1': '******',
        'security_answer_2': '******',
      });

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'fullname': fullName,
          'email': email,
          'phone': phoneNumber,
          'password': password,
          'password_confirmation': passwordConfirmation,
          'security_answer_1': securityAnswer1,
          'security_answer_2': securityAnswer2,
        }),
      );

      _log('SIGNUP → STATUS', response.statusCode);
      _log('SIGNUP → RESPONSE', response.body);

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (responseData.containsKey('token')) {
          await StorageService.saveAuthToken(responseData['token'] as String);
        } else if (responseData.containsKey('data') &&
            responseData['data'] is Map &&
            (responseData['data'] as Map).containsKey('token')) {
          await StorageService.saveAuthToken(
            (responseData['data'] as Map)['token'] as String,
          );
        }
        return responseData;
      } else {
        throw Exception(responseData['message'] ?? 'Signup failed');
      }
    } catch (e) {
      _log('SIGNUP → ERROR', e);
      throw Exception('Signup error: $e');
    }
  }

  /// Forgot Password via security questions
  /// POST /api/forgot-password
  static Future<Map<String, dynamic>> forgotPassword({
    required String email,
    required String securityAnswer1,
    required String securityAnswer2,
  }) async {
    try {
      final url = '$baseUrl/forgot-password';
      final body = {
        'email': email,
        'security_answer_1': securityAnswer1,
        'security_answer_2': securityAnswer2,
      };

      _log('FORGOT PASSWORD → URL', url);
      _log('FORGOT PASSWORD → BODY', {
        'email': email,
        'security_answer_1': '******',
        'security_answer_2': '******',
      });

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      );

      _log('FORGOT PASSWORD → STATUS', response.statusCode);
      _log('FORGOT PASSWORD → RESPONSE', response.body);

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 || response.statusCode == 201) {
        return responseData;
      }

      throw Exception(
        responseData['message'] ?? 'Failed to verify security questions',
      );
    } catch (e) {
      _log('FORGOT PASSWORD → ERROR', e);
      throw Exception('Forgot password error: $e');
    }
  }

  /// Reset Password
  /// POST /api/reset-password
  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String token,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final url = '$baseUrl/reset-password';
      final body = {
        'email': email,
        'token': token,
        'password': password,
        'password_confirmation': passwordConfirmation,
      };

      _log('RESET PASSWORD → URL', url);
      _log('RESET PASSWORD → BODY', {
        'email': email,
        'token': '******',
        'password': '******',
        'password_confirmation': '******',
      });

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      );

      _log('RESET PASSWORD → STATUS', response.statusCode);
      _log('RESET PASSWORD → RESPONSE', response.body);

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 || response.statusCode == 201) {
        return responseData;
      }

      throw Exception(responseData['message'] ?? 'Failed to reset password');
    } catch (e) {
      _log('RESET PASSWORD → ERROR', e);
      throw Exception('Reset password error: $e');
    }
  }

  /// Check if user has cards
  /// GET /api/account/has-cards
  static Future<Map<String, dynamic>> checkHasCards() async {
    try {
      final token = await StorageService.getAuthToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final url = '$baseUrl/account/has-cards';

      _log('HAS CARDS → URL', url);

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      _log('HAS CARDS → STATUS', response.statusCode);
      _log('HAS CARDS → RESPONSE', response.body);

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return responseData;
      } else {
        throw Exception(responseData['message'] ?? 'Failed to check cards');
      }
    } catch (e) {
      _log('HAS CARDS → ERROR', e);
      throw Exception('Check cards error: $e');
    }
  }

  /// Add card API
  /// POST /api/account/card
  static Future<Map<String, dynamic>> addCard({
    required String cardNumber,
    required String expiryDate,
    required String cvv,
    required String cardholderName,
    required String cardType,
  }) async {
    try {
      final token = await StorageService.getAuthToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final url = '$baseUrl/account/card';
      final expiryParts = expiryDate.split('/');
      final rawExpiryMonth = expiryParts.isNotEmpty ? expiryParts[0] : '';
      final expiryMonth = int.tryParse(rawExpiryMonth);
      final rawExpiryYear = expiryParts.length > 1 ? expiryParts[1] : '';
      final normalizedExpiryYear =
          rawExpiryYear.length == 2 ? '20$rawExpiryYear' : rawExpiryYear;
      final expiryYear = int.tryParse(normalizedExpiryYear);

      _log('ADD CARD → URL', url);
      _log('ADD CARD → BODY', {
        'card_number': '****${cardNumber.substring(cardNumber.length - 4)}',
        'expiry_date': expiryDate,
        'cvv': '***',
        'expiry_month': expiryMonth ?? rawExpiryMonth,
        'expiry_year': expiryYear ?? normalizedExpiryYear,
        'card_holder_name': cardholderName,
        'card_type': cardType,
      });

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'card_number': cardNumber,
          'expiry_date': expiryDate,
          'cvv': cvv,
          'card_number_encrypted': cardNumber,
          'expiry_month': expiryMonth,
          'expiry_year': expiryYear,
          'cvv_encrypted': cvv,
          'card_holder_name': cardholderName,
          'card_type': cardType,
        }),
      );

      _log('ADD CARD → STATUS', response.statusCode);
      _log('ADD CARD → RESPONSE', response.body);

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 || response.statusCode == 201) {
        return responseData;
      } else {
        throw Exception(responseData['message'] ?? 'Failed to add card');
      }
    } catch (e) {
      _log('ADD CARD → ERROR', e);
      throw Exception('Add card error: $e');
    }
  }

  /// Logout API
  /// POST /api/logout
  static Future<void> logout() async {
    try {
      final token = await StorageService.getAuthToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final url = '$baseUrl/logout';

      _log('LOGOUT → URL', url);

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      _log('LOGOUT → STATUS', response.statusCode);
      _log('LOGOUT → RESPONSE', response.body);

      if (response.statusCode == 200 || response.statusCode == 204) {
        // ✅ Remove token locally
        await StorageService.removeAuthToken();
      } else {
        final responseData = jsonDecode(response.body);
        throw Exception(responseData['message'] ?? 'Logout failed');
      }
    } catch (e) {
      _log('LOGOUT → ERROR', e);
      throw Exception('Logout error: $e');
    }
  }

  /// Get User Details API
  /// GET /api/user/details
  static Future<UserModel> getUserDetails() async {
    try {
      final token = await StorageService.getAuthToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final url = '$baseUrl/user/details';

      _log('USER DETAILS → URL', url);

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      _log('USER DETAILS → STATUS', response.statusCode);
      _log('USER DETAILS → RESPONSE', response.body);

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return UserModel.fromJson(responseData['user']);
      } else {
        throw Exception(
          responseData['message'] ?? 'Failed to fetch user details',
        );
      }
    } catch (e) {
      _log('USER DETAILS → ERROR', e);
      throw Exception('User details error: $e');
    }
  }

  /// User Cards API
  /// GET /api/user/cards
  static Future<Map<String, dynamic>> getUserCards() async {
    try {
      final token = await StorageService.getAuthToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final url = '$baseUrl/user/cards';

      _log('USER CARDS → URL', url);

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      _log('USER CARDS → STATUS', response.statusCode);
      _log('USER CARDS → RESPONSE', response.body);

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return responseData;
      } else {
        throw Exception(
          responseData['message'] ?? 'Failed to fetch user cards',
        );
      }
    } catch (e) {
      _log('USER CARDS → ERROR', e);
      throw Exception('User cards error: $e');
    }
  }

  /// Payment Methods API
  /// GET /api/account/payment-methods
  static Future<Map<String, dynamic>> getPaymentMethods() async {
    try {
      final token = await StorageService.getAuthToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final url = '$baseUrl/account/payment-methods';

      _log('PAYMENT METHODS → URL', url);

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      _log('PAYMENT METHODS → STATUS', response.statusCode);
      _log('PAYMENT METHODS → RESPONSE', response.body);

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return responseData;
      } else {
        throw Exception(
          responseData['message'] ?? 'Failed to fetch payment methods',
        );
      }
    } catch (e) {
      _log('PAYMENT METHODS → ERROR', e);
      throw Exception('Payment methods error: $e');
    }
  }

  /// Customer Transactions API
  /// GET /api/reciept/transactions/customer?customer_id={id}
  static Future<Map<String, dynamic>> getCustomerTransactions({
    required int customerId,
  }) async {
    try {
      final headers = await _bearerHeaders();
      final url = '$baseUrl/reciept/transactions/customer?customer_id=$customerId';

      _log('CUSTOMER TRANSACTIONS → URL', url);

      final response = await http.get(Uri.parse(url), headers: headers);

      _log('CUSTOMER TRANSACTIONS → STATUS', response.statusCode);
      _log('CUSTOMER TRANSACTIONS → RESPONSE', response.body);

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) {
        return responseData;
      }

      throw Exception(
        responseData['message'] ?? 'Failed to fetch customer transactions',
      );
    } catch (e) {
      _log('CUSTOMER TRANSACTIONS → ERROR', e);
      throw Exception('Customer transactions error: $e');
    }
  }

  /// Profile Image API
  /// GET /api/account/image
  static Future<Map<String, dynamic>> getProfileImage() async {
    try {
      final token = await StorageService.getAuthToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final url = '$baseUrl/account/image';

      _log('PROFILE IMAGE GET → URL', url);

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      _log('PROFILE IMAGE GET → STATUS', response.statusCode);
      _log('PROFILE IMAGE GET → RESPONSE', response.body);

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) {
        return responseData;
      }

      throw Exception(
        responseData['message'] ?? 'Failed to fetch profile image',
      );
    } catch (e) {
      _log('PROFILE IMAGE GET → ERROR', e);
      throw Exception('Get profile image error: $e');
    }
  }

  /// Profile Image API
  /// POST /api/account/image (multipart/form-data)
  /// field: image
  static Future<Map<String, dynamic>> uploadProfileImage({
    required File imageFile,
  }) async {
    try {
      final token = await StorageService.getAuthToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final url = '$baseUrl/account/image';

      _log('PROFILE IMAGE UPLOAD → URL', url);
      _log('PROFILE IMAGE UPLOAD → PATH', imageFile.path);

      final request = http.MultipartRequest('POST', Uri.parse(url));
      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });
      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );

      final streamedResponse = await request.send();
      final responseBody = await streamedResponse.stream.bytesToString();

      _log('PROFILE IMAGE UPLOAD → STATUS', streamedResponse.statusCode);
      _log('PROFILE IMAGE UPLOAD → RESPONSE', responseBody);

      final responseData = jsonDecode(responseBody) as Map<String, dynamic>;
      if (streamedResponse.statusCode == 200 ||
          streamedResponse.statusCode == 201) {
        return responseData;
      }

      throw Exception(
        responseData['message'] ?? 'Failed to upload profile image',
      );
    } catch (e) {
      _log('PROFILE IMAGE UPLOAD → ERROR', e);
      throw Exception('Upload profile image error: $e');
    }
  }

  /// Profile API
  /// POST /api/account/profile
  /// body: {"fullname": "...", "phone": "..."}
  static Future<Map<String, dynamic>> updateProfile({
    required String fullname,
    required String phone,
  }) async {
    try {
      final token = await StorageService.getAuthToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final url = '$baseUrl/account/profile';
      final body = {'fullname': fullname, 'phone': phone};

      _log('PROFILE UPDATE POST → URL', url);
      _log('PROFILE UPDATE POST → BODY', body);

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      _log('PROFILE UPDATE POST → STATUS', response.statusCode);
      _log('PROFILE UPDATE POST → RESPONSE', response.body);

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 || response.statusCode == 201) {
        return responseData;
      }

      throw Exception(responseData['message'] ?? 'Failed to update profile');
    } catch (e) {
      _log('PROFILE UPDATE POST → ERROR', e);
      throw Exception('Update profile error: $e');
    }
  }

  /// NFC Payment Methods Summary
  /// GET /api/payment-methods/with-status
  static Future<Map<String, dynamic>> getPaymentMethodsWithStatus() async {
    try {
      final headers = await _bearerHeaders();
      final url = '$baseUrl/payment-methods/with-status';

      _log('NFC METHODS STATUS → URL', url);

      final response = await http.get(Uri.parse(url), headers: headers);

      _log('NFC METHODS STATUS → STATUS', response.statusCode);
      _log('NFC METHODS STATUS → RESPONSE', response.body);

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) {
        return responseData;
      }

      throw Exception(
        responseData['message'] ?? 'Failed to fetch payment methods status',
      );
    } catch (e) {
      _log('NFC METHODS STATUS → ERROR', e);
      throw Exception('Payment methods status error: $e');
    }
  }

  /// Notifications
  /// GET /api/notifications
  static Future<Map<String, dynamic>> getNotifications() async {
    try {
      final headers = await _bearerHeaders();
      final url = '$baseUrl/notifications';

      _log('NOTIFICATIONS → URL', url);

      final response = await http.get(Uri.parse(url), headers: headers);

      _log('NOTIFICATIONS → STATUS', response.statusCode);
      _log('NOTIFICATIONS → RESPONSE', response.body);

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) {
        return responseData;
      }

      throw Exception(responseData['message'] ?? 'Failed to fetch notifications');
    } catch (e) {
      _log('NOTIFICATIONS → ERROR', e);
      throw Exception('Notifications error: $e');
    }
  }

  /// Notifications
  /// GET /api/unread-count
  static Future<Map<String, dynamic>> getUnreadNotificationsCount() async {
    try {
      final headers = await _bearerHeaders();
      final url = '$baseUrl/unread-count';

      _log('UNREAD COUNT → URL', url);

      final response = await http.get(Uri.parse(url), headers: headers);

      _log('UNREAD COUNT → STATUS', response.statusCode);
      _log('UNREAD COUNT → RESPONSE', response.body);

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) {
        return responseData;
      }

      throw Exception(
        responseData['message'] ?? 'Failed to fetch unread notification count',
      );
    } catch (e) {
      _log('UNREAD COUNT → ERROR', e);
      throw Exception('Unread count error: $e');
    }
  }

  /// Notifications
  /// POST /api/notifications/{id}/read
  static Future<Map<String, dynamic>> markNotificationAsRead(int id) async {
    try {
      final headers = await _bearerHeaders();
      final url = '$baseUrl/notifications/$id/read';

      _log('MARK NOTIFICATION READ → URL', url);

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode({}),
      );

      _log('MARK NOTIFICATION READ → STATUS', response.statusCode);
      _log('MARK NOTIFICATION READ → RESPONSE', response.body);

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 || response.statusCode == 201) {
        return responseData;
      }

      throw Exception(
        responseData['message'] ?? 'Failed to mark notification as read',
      );
    } catch (e) {
      _log('MARK NOTIFICATION READ → ERROR', e);
      throw Exception('Mark notification read error: $e');
    }
  }

  /// Payment Method Default Check
  /// GET /api/payment-methods/default/check
  static Future<Map<String, dynamic>> getDefaultPaymentMethodCheck() async {
    try {
      final headers = await _bearerHeaders();
      final url = '$baseUrl/payment-methods/default/check';

      _log('PAYMENT METHOD DEFAULT CHECK → URL', url);

      final response = await http.get(Uri.parse(url), headers: headers);

      _log('PAYMENT METHOD DEFAULT CHECK → STATUS', response.statusCode);
      _log('PAYMENT METHOD DEFAULT CHECK → RESPONSE', response.body);

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) {
        return responseData;
      }

      throw Exception(
        responseData['message'] ?? 'Failed to fetch default payment method',
      );
    } catch (e) {
      _log('PAYMENT METHOD DEFAULT CHECK → ERROR', e);
      throw Exception('Default payment method check error: $e');
    }
  }

  /// NFC Enrollment Session
  /// POST /api/payment-methods/{id}/nfc/session
  static Future<Map<String, dynamic>> createNfcSession({
    required int paymentMethodId,
  }) async {
    try {
      final headers = await _bearerHeaders();
      final url = '$baseUrl/payment-methods/$paymentMethodId/nfc/session';

      _log('NFC SESSION CREATE → URL', url);

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode({}),
      );

      _log('NFC SESSION CREATE → STATUS', response.statusCode);
      _log('NFC SESSION CREATE → RESPONSE', response.body);

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 || response.statusCode == 201) {
        return responseData;
      }

      throw Exception(
        responseData['message'] ?? 'Failed to create NFC enrollment session',
      );
    } catch (e) {
      _log('NFC SESSION CREATE → ERROR', e);
      throw Exception('Create NFC session error: $e');
    }
  }

  static Future<Map<String, dynamic>> getNfcSessionStatus({
    required String sessionId,
  }) async {
    try {
      final headers = await _bearerHeaders();
      final url = '$baseUrl/nfc/enroll/sessions/$sessionId';

      _log('NFC SESSION STATUS → URL', url);

      final response = await http.get(Uri.parse(url), headers: headers);

      _log('NFC SESSION STATUS → STATUS', response.statusCode);
      _log('NFC SESSION STATUS → RESPONSE', response.body);

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 || response.statusCode == 201) {
        return responseData;
      }

      throw Exception(
        responseData['message'] ?? 'Failed to fetch NFC session status',
      );
    } catch (e) {
      _log('NFC SESSION STATUS → ERROR', e);
      throw Exception('Get NFC session status error: $e');
    }
  }

  /// NFC Toggle
  /// POST /api/payment-methods/{id}/nfc/toggle
  static Future<Map<String, dynamic>> toggleNfc({
    required int paymentMethodId,
    required String action,
  }) async {
    try {
      final headers = await _bearerHeaders();
      final url = '$baseUrl/payment-methods/$paymentMethodId/nfc/toggle';
      final body = {'action': action};

      _log('NFC TOGGLE → URL', url);
      _log('NFC TOGGLE → BODY', body);

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );

      _log('NFC TOGGLE → STATUS', response.statusCode);
      _log('NFC TOGGLE → RESPONSE', response.body);

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 || response.statusCode == 201) {
        return responseData;
      }

      throw Exception(responseData['message'] ?? 'Failed to toggle NFC');
    } catch (e) {
      _log('NFC TOGGLE → ERROR', e);
      throw Exception('Toggle NFC error: $e');
    }
  }

  /// Palm Vein Enrollment: Create Session (Customer)
  /// POST /api/palm/enroll/sessions
  static Future<Map<String, dynamic>> createPalmEnrollSession({
    required int paymentMethodId,
  }) async {
    try {
      final url = '$baseUrl/palm/enroll/sessions';
      final headers = await _bearerHeaders();
      final body = {'payment_method_id': paymentMethodId};

      _log('PALM ENROLL SESSION CREATE → URL', url);
      _log('PALM ENROLL SESSION CREATE → BODY', body);

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );

      _log('PALM ENROLL SESSION CREATE → STATUS', response.statusCode);
      _log('PALM ENROLL SESSION CREATE → RESPONSE', response.body);

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 || response.statusCode == 201) {
        return responseData;
      }

      throw Exception(
        responseData['message'] ?? 'Failed to create palm enrollment session',
      );
    } catch (e) {
      _log('PALM ENROLL SESSION CREATE → ERROR', e);
      throw Exception('Create palm enrollment session error: $e');
    }
  }

  /// Payment Method Default Toggle
  /// POST /api/payment-methods/{id}/default
  static Future<Map<String, dynamic>> toggleDefaultPaymentMethod({
    required int paymentMethodId,
    required bool isDefault,
  }) async {
    try {
      final headers = await _bearerHeaders();
      final url = '$baseUrl/payment-methods/$paymentMethodId/default';
      final body = {
        'payment_method_id': paymentMethodId,
        'is_default': isDefault,
        'default': isDefault,
      };

      _log('PAYMENT METHOD DEFAULT TOGGLE → URL', url);
      _log('PAYMENT METHOD DEFAULT TOGGLE → BODY', body);

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );

      _log('PAYMENT METHOD DEFAULT TOGGLE → STATUS', response.statusCode);
      _log('PAYMENT METHOD DEFAULT TOGGLE → RESPONSE', response.body);

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 || response.statusCode == 201) {
        return responseData;
      }

      throw Exception(
        responseData['message'] ?? 'Failed to update default payment method',
      );
    } catch (e) {
      _log('PAYMENT METHOD DEFAULT TOGGLE → ERROR', e);
      throw Exception('Toggle default payment method error: $e');
    }
  }

  /// Palm Vein Enrollment: Get Session Status (Customer)
  /// GET /api/palm/enroll/sessions/{sessionId}
  static Future<Map<String, dynamic>> getPalmEnrollSessionStatus({
    required String sessionId,
  }) async {
    try {
      final url = '$baseUrl/palm/enroll/sessions/$sessionId';
      final headers = await _bearerHeaders();

      _log('PALM ENROLL SESSION STATUS → URL', url);

      final response = await http.get(Uri.parse(url), headers: headers);

      _log('PALM ENROLL SESSION STATUS → STATUS', response.statusCode);
      _log('PALM ENROLL SESSION STATUS → RESPONSE', response.body);

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) {
        return responseData;
      }

      throw Exception(
        responseData['message'] ?? 'Failed to fetch palm enrollment session',
      );
    } catch (e) {
      _log('PALM ENROLL SESSION STATUS → ERROR', e);
      throw Exception('Get palm enrollment session error: $e');
    }
  }

  /// Palm Vein Enrollment: Me Status (Customer)
  /// GET /api/palm/enroll/me/status
  static Future<Map<String, dynamic>> getPalmEnrollMeStatus() async {
    try {
      final url = '$baseUrl/palm/enroll/me/status';
      final headers = await _bearerHeaders();

      _log('PALM ENROLL ME STATUS → URL', url);

      final response = await http.get(Uri.parse(url), headers: headers);

      _log('PALM ENROLL ME STATUS → STATUS', response.statusCode);
      _log('PALM ENROLL ME STATUS → RESPONSE', response.body);

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) {
        return responseData;
      }

      throw Exception(
        responseData['message'] ?? 'Failed to fetch palm enrollment status',
      );
    } catch (e) {
      _log('PALM ENROLL ME STATUS → ERROR', e);
      throw Exception('Get palm enrollment status error: $e');
    }
  }

  /// Palm Vein Enrollment: Reset (Customer)
  /// POST /api/palm/enroll/me/reset
  static Future<Map<String, dynamic>> resetPalmEnrollment({
    required int paymentMethodId,
    required String reason,
  }) async {
    try {
      final url = '$baseUrl/palm/enroll/me/reset';
      final headers = await _bearerHeaders();
      final body = {'payment_method_id': paymentMethodId, 'reason': reason};

      _log('PALM ENROLL RESET → URL', url);
      _log('PALM ENROLL RESET → BODY', body);

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );

      _log('PALM ENROLL RESET → STATUS', response.statusCode);
      _log('PALM ENROLL RESET → RESPONSE', response.body);

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 || response.statusCode == 201) {
        return responseData;
      }

      throw Exception(responseData['message'] ?? 'Failed to reset enrollment');
    } catch (e) {
      _log('PALM ENROLL RESET → ERROR', e);
      throw Exception('Reset palm enrollment error: $e');
    }
  }
}
