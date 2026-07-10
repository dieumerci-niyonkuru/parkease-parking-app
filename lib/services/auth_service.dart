import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

import 'api_service.dart';
import '../utils/app_utils.dart';

class AuthUser {
  final int id;
  final String names;
  final String email;
  final String phone;
  final String role;
  final String createdAt;

  const AuthUser({
    required this.id,
    required this.names,
    required this.email,
    required this.phone,
    required this.role,
    required this.createdAt,
  });

  factory AuthUser.fromJson(Map<String, dynamic> j) => AuthUser(
    id:        j['id']                   ?? j['user_id'] ?? 0,
    names:     j['names']                ?? j['username'] ?? '',
    email:     j['email']                ?? '',
    phone:     j['primary_phone_number'] ?? j['phone'] ?? '',
    role:      j['role']                 ?? 'user',
    createdAt: j['created_at']           ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'names': names, 'email': email,
    'phone': phone, 'role': role, 'created_at': createdAt,
  };
}

class AuthService {
  static const String baseUrl = 'https://client-api.iteccone.com';
  static const Duration timeout = Duration(seconds: 12);
  static const String _keyToken = 'jwt_token';
  static const String _keyUser  = 'auth_user';
  static const String _keyCreds = 'biometric_credentials';
  static const String _keyBioEnabled = 'biometric_enabled';
  // NOTE: Do not expose secrets in client code. This is a legacy placeholder.
  static String get internalSecret => '';

  static const _secure = FlutterSecureStorage();
  static final _localAuth = LocalAuthentication();

  // ── Cached state ──────────────────────────────────────────────
  static String?   _token;
  static AuthUser? _user;
  static bool      _bioEnabled = false;

  static String?   get token => _token;
  static AuthUser? get user  => _user;
  static bool      get isLoggedIn => _token != null && _user != null;
  static bool      get isBiometricEnabled => _bioEnabled;

  // ── Biometrics ────────────────────────────────────────────────
  static Future<void> setBiometricEnabled(bool enabled) async {
    _bioEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyBioEnabled, enabled);
  }

  static Future<bool> hasStoredCredentials() async {
    final creds = await _secure.read(key: _keyCreds);
    return creds != null;
  }

  static Future<bool> canUseBiometrics() async {
    if (kIsWeb) return false;
    final bool canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
    final bool canAuthenticate = canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();
    return canAuthenticate;
  }

  static Future<bool> authenticateBiometrically() async {
    if (kIsWeb) return false;
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Please authenticate to log in to ITEC Parking',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (e) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> loginWithBiometrics() async {
    final creds = await _secure.read(key: _keyCreds);
    if (creds == null) return {'success': false, 'message': 'No biometric credentials stored'};

    final Map<String, dynamic> data = jsonDecode(creds);
    return await login(data['username'], data['password']);
  }

  // ── Persist / restore ─────────────────────────────────────────
  static Future<void> restore() async {
    _token = await _secure.read(key: _keyToken);
    final prefs = await SharedPreferences.getInstance();
    _bioEnabled = prefs.getBool(_keyBioEnabled) ?? false;
    final raw = prefs.getString(_keyUser);
    if (raw != null) {
      try { _user = AuthUser.fromJson(jsonDecode(raw)); } catch (e) { _user = null; }
    }
  }

  static Future<void> persistSession(String token, AuthUser user) async {
    _token = token;
    _user  = user;
    await _secure.write(key: _keyToken, value: token);
    
    // Automatically enable biometrics on first persistent login
    if (!_bioEnabled) {
      await setBiometricEnabled(true);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUser, jsonEncode(user.toJson()));
  }

  static Future<void> logout() async {
    _token = null;
    _user  = null;
    // We keep _keyUser and _keyCreds to support the "Offline Login" feature
    // only the active session token is removed to prevent unauthorized API calls
    await _secure.delete(key: _keyToken);
  }

  // ── Validate Token ────────────────────────────────────────────
  static Future<bool?> validateToken() async {
    if (_token == null) return false;
    // Allow offline and direct social sessions to bypass validation
    if (_token == "OFFLINE_SESSION" || (_token?.startsWith("SESSION_") ?? false)) return true;
    
    try {
      final resp = await http.post(
        Uri.parse('$baseUrl/auth/validate'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({}),
      ).timeout(const Duration(seconds: 8));

      final data = jsonDecode(resp.body);
      return resp.statusCode == 200 && data['status'] == 'success';
    } catch (_) {
      // Return null to indicate a connection error, not necessarily an invalid token
      return null;
    }
  }

  // ── Login ─────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final resp = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': email, 'password': password}),
      ).timeout(timeout);

      final data = jsonDecode(resp.body);
      if (resp.statusCode == 200 && data['status'] == 'success') {
        final token = data['token'] as String;
        _token = token;
        
        // Store credentials for biometrics & offline login
        await _secure.write(key: _keyCreds, value: jsonEncode({'username': email, 'password': password}));

        // If user object isn't in response, fetch it from /users/me
        AuthUser? user;
        if (data['user'] != null) {
          user = AuthUser.fromJson(data['user'] as Map<String, dynamic>);
        } else {
          user = await fetchProfile();
        }

        if (user != null) {
          await persistSession(token, user);
          return {'success': true};
        }
      }
      return {'success': false, 'message': data['message'] ?? 'Login failed'};
    } catch (e) {
      // ── OFFLINE LOGIN FALLBACK ────────────────────────────────
      final creds = await _secure.read(key: _keyCreds);
      if (creds != null) {
        final Map<String, dynamic> stored = jsonDecode(creds);
        if (stored['username'] == email && stored['password'] == password) {
          // Credentials match last successful login - allow offline entry
          final prefs = await SharedPreferences.getInstance();
          final rawUser = prefs.getString(_keyUser);
          if (rawUser != null) {
            _user = AuthUser.fromJson(jsonDecode(rawUser));
            // Set a placeholder token to allow the app to enter the dashboard in offline mode
            _token = "OFFLINE_SESSION";
            return {'success': true, 'offline': true};
          }
        }
      }
      return {'success': false, 'message': AppUtils.friendlyNetworkError()};
    }
  }

  // ── Register: step 1 — send OTP ──────────────────────────────
  static Future<Map<String, dynamic>> initiateRegister(String phone, String username) async {
    try {
      final resp = await http.post(
        Uri.parse('$baseUrl/auth/register/initiate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': phone,
          'username': username,
        }),
      ).timeout(timeout);

      final data = jsonDecode(resp.body);
      if (resp.statusCode == 200 && data['status'] == 'success') {
        return {
          'success': true,
          'message': data['message'] ?? 'OTP sent',
          'verification_payload': data['verification_payload'] ?? data['data']?['verification_payload'] ?? '',
        };
      }
      return {'success': false, 'message': data['message'] ?? 'Failed to send OTP'};
    } catch (e) {
      return {'success': false, 'message': AppUtils.friendlyNetworkError()};
    }
  }

  // ── Register: step 2 — verify OTP ────────────────────────────
  static Future<Map<String, dynamic>> verifyOtp(String phone, String otp, {String verificationPayload = ''}) async {
    try {
      final body = <String, dynamic>{
        'phone': phone,
        'otp': otp,
      };
      if (verificationPayload.isNotEmpty) {
        body['verification_payload'] = verificationPayload;
      }
      final resp = await http.post(
        Uri.parse('$baseUrl/auth/register/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(timeout);

      final data = jsonDecode(resp.body);
      if (resp.statusCode == 200 && data['status'] == 'success') {
        return {
          'success': true,
          'message': data['message'] ?? 'OTP verified',
          'registration_token': data['registration_token'] ?? data['data']?['registration_token'] ?? '',
        };
      }
      return {'success': false, 'message': data['message'] ?? 'Invalid OTP'};
    } catch (e) {
      return {'success': false, 'message': AppUtils.friendlyNetworkError()};
    }
  }

  // ── Register: step 2.5 — verify reclaim OTP ──────────────────
  static Future<Map<String, dynamic>> verifyReclaimOtp(String phone, String otp) async {
    try {
      final resp = await http.post(
        Uri.parse('$baseUrl/auth/register/verify-reclaim-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': phone,
          'otp': otp,
        }),
      ).timeout(timeout);

      final data = jsonDecode(resp.body);
      if (resp.statusCode == 200 && data['status'] == 'success') {
        return {
          'success': true,
          'message': data['message'] ?? 'OTP verified for reclaim',
        };
      }
      return {'success': false, 'message': data['message'] ?? 'Invalid OTP'};
    } catch (e) {
      return {'success': false, 'message': AppUtils.friendlyNetworkError()};
    }
  }

  // ── Register: step 3 — complete profile ──────────────────────
  static Future<Map<String, dynamic>> completeRegister({
    required String username,
    required String password,
    String registrationToken = '',
    Map<String, dynamic>? otherInfo,
  }) async {
    try {
      final body = <String, dynamic>{
        'username': username,
        'password': password,
        ...?otherInfo,
      };
      if (registrationToken.isNotEmpty) {
        body['registration_token'] = registrationToken;
      }
      final resp = await http.post(
        Uri.parse('$baseUrl/auth/register/complete'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(timeout);

      final data = jsonDecode(resp.body);
      if ((resp.statusCode == 200 || resp.statusCode == 201) && data['status'] == 'success') {
        // According to API 2.0, login usually follows registration
        return {'success': true, 'message': data['message'] ?? 'Registration complete'};
      }
      return {'success': false, 'message': data['message'] ?? 'Registration failed'};
    } catch (e) {
      return {'success': false, 'message': AppUtils.friendlyNetworkError()};
    }
  }

  // ── Fetch fresh profile ───────────────────────────────────────
  static Future<AuthUser?> fetchProfile() async {
    if (_token == null) return null;
    try {
      final resp = await http.get(
        Uri.parse('$baseUrl/users/me'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      ).timeout(timeout);

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        // /users/me returns the user fields at the top level; older builds wrapped them in `user`/`data`.
        final userData = (data['user'] ?? data['data'] ?? data) as Map<String, dynamic>;
        final user = AuthUser.fromJson(userData);
        _user = user;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_keyUser, jsonEncode(user.toJson()));
        return user;
      } else if (resp.statusCode == 401) {
        ApiService.onSessionExpired?.call();
      }
    } catch (_) {
      // Token validation failed — return current cached user
    }
    return _user;
  }

  // ── Phone Link Initiate ──────────────────────────────────────
  static Future<Map<String, dynamic>> phoneLinkInitiate(String phone) async {
    try {
      final resp = await http.post(
        Uri.parse('$baseUrl/auth/phone/link/initiate'),
        headers: authHeaders,
        body: jsonEncode({'phone': phone}),
      ).timeout(timeout);

      final data = jsonDecode(resp.body);
      if (resp.statusCode == 200 && data['status'] == 'success') {
        return {
          'success': true,
          'message': data['message'] ?? 'OTP sent',
          'verification_payload': data['verification_payload'] ?? '',
          'expires_in': data['expires_in'] ?? 600,
        };
      }
      return {'success': false, 'message': data['message'] ?? 'Failed to send OTP'};
    } catch (e) {
      return {'success': false, 'message': AppUtils.friendlyNetworkError()};
    }
  }

  // ── Phone Link Verify ────────────────────────────────────────
  static Future<Map<String, dynamic>> phoneLinkVerify(String phone, String otp, {String? password, String verificationPayload = ''}) async {
    try {
      final body = <String, dynamic>{
        'phone': phone,
        'otp': otp,
      };
      if (password != null && password.isNotEmpty) {
        body['password'] = password;
      }
      if (verificationPayload.isNotEmpty) {
        body['verification_payload'] = verificationPayload;
      }
      final resp = await http.post(
        Uri.parse('$baseUrl/auth/phone/link/verify'),
        headers: authHeaders,
        body: jsonEncode(body),
      ).timeout(timeout);

      final data = jsonDecode(resp.body);
      if (resp.statusCode == 200 && data['status'] == 'success') {
        // Update the local user's phone number
        if (_user != null && data['phone_number'] != null) {
          _user = AuthUser(
            id: _user!.id,
            names: _user!.names,
            email: _user!.email,
            phone: data['phone_number'].toString(),
            role: _user!.role,
            createdAt: _user!.createdAt,
          );
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_keyUser, jsonEncode(_user!.toJson()));
        }
        return {
          'success': true,
          'message': data['message'] ?? 'Phone linked',
          'phone_number': data['phone_number'] ?? '',
          'requires_phone': data['requires_phone'] ?? false,
        };
      }
      return {'success': false, 'message': data['message'] ?? 'Invalid OTP'};
    } catch (e) {
      return {'success': false, 'message': AppUtils.friendlyNetworkError()};
    }
  }

  // ── Set Password ─────────────────────────────────────────────
  static Future<Map<String, dynamic>> setPassword(String password) async {
    try {
      final resp = await http.post(
        Uri.parse('$baseUrl/auth/password/set'),
        headers: authHeaders,
        body: jsonEncode({'password': password}),
      ).timeout(timeout);

      final data = jsonDecode(resp.body);
      if (resp.statusCode == 200 && data['status'] == 'success') {
        return {'success': true, 'message': data['message'] ?? 'Password set'};
      }
      return {'success': false, 'message': data['message'] ?? 'Failed to set password'};
    } catch (e) {
      return {'success': false, 'message': AppUtils.friendlyNetworkError()};
    }
  }

  // ── Get User By ID ───────────────────────────────────────────
  static Future<AuthUser?> getUserById(int userId) async {
    try {
      final resp = await http.get(
        Uri.parse('$baseUrl/users/$userId'),
        headers: authHeaders,
      ).timeout(timeout);

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        // /users/{id} returns the user fields at the top level; older builds wrapped them in `user`/`data`.
        final userData = data['user'] ?? data['data'] ?? data;
        if (userData is Map<String, dynamic>) {
          return AuthUser.fromJson(userData);
        }
      }
    } catch (_) {
      // User fetch failed
    }
    return null;
  }

  // ── Auth header ───────────────────────────────────────────────
  static Map<String, String> get authHeaders => {
    'Content-Type':  'application/json',
    'Authorization': 'Bearer ${_token ?? ""}',
  };
}
