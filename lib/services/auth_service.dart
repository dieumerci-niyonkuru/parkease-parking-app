import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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
  static const String _base    = 'https://client-api.iteccone.com';
  static const Duration _timeout = Duration(seconds: 12);
  static const String _keyToken = 'jwt_token';
  static const String _keyUser  = 'auth_user';

  // ── Cached state ──────────────────────────────────────────────
  static String?   _token;
  static AuthUser? _user;

  static String?   get token => _token;
  static AuthUser? get user  => _user;
  static bool      get isLoggedIn => _token != null && _user != null;

  // ── Persist / restore ─────────────────────────────────────────
  static Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_keyToken);
    final raw = prefs.getString(_keyUser);
    if (raw != null) {
      try { _user = AuthUser.fromJson(jsonDecode(raw)); } catch (_) {}
    }
  }

  static Future<void> _persist(String token, AuthUser user) async {
    _token = token;
    _user  = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
    await prefs.setString(_keyUser, jsonEncode(user.toJson()));
  }

  static Future<void> logout() async {
    _token = null;
    _user  = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUser);
  }

  // ── Validate Token ────────────────────────────────────────────
  static Future<bool> validateToken() async {
    if (_token == null) return false;
    try {
      final resp = await http.post(
        Uri.parse('$_base/auth/validate'),
        headers: authHeaders,
        body: jsonEncode({}),
      ).timeout(const Duration(seconds: 8));

      final data = jsonDecode(resp.body);
      return resp.statusCode == 200 && data['status'] == 'success';
    } catch (_) {
      return false; 
    }
  }

  // ── Login ─────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final resp = await http.post(
        Uri.parse('$_base/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': email, 'password': password}),
      ).timeout(_timeout);

      final data = jsonDecode(resp.body);
      if (resp.statusCode == 200 && data['status'] == 'success') {
        final token = data['token'] as String;
        _token = token;
        
        // If user object isn't in response, fetch it from /users/me
        AuthUser? user;
        if (data['user'] != null) {
          user = AuthUser.fromJson(data['user'] as Map<String, dynamic>);
        } else {
          user = await fetchProfile();
        }

        if (user != null) {
          await _persist(token, user);
          return {'success': true};
        }
      }
      return {'success': false, 'message': data['message'] ?? 'Login failed'};
    } catch (e) {
      return {'success': false, 'message': 'Connection error. Check your network.'};
    }
  }

  // ── Register: step 1 — send OTP ──────────────────────────────
  static Future<Map<String, dynamic>> initiateRegister(String phone, {String? username}) async {
    try {
      final resp = await http.post(
        Uri.parse('$_base/auth/register/initiate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': phone,
          'username': username ?? phone, // Postman shows username is expected
        }),
      ).timeout(_timeout);

      final data = jsonDecode(resp.body);
      if (resp.statusCode == 200 && data['status'] == 'success') {
        return {
          'success': true, 
          'verification_payload': data['verification_payload'] ?? phone // Fallback to phone if payload not sent
        };
      }
      return {'success': false, 'message': data['message'] ?? 'Failed to send OTP'};
    } catch (e) {
      return {'success': false, 'message': 'Connection error.'};
    }
  }

  // ── Register: step 2 — verify OTP ────────────────────────────
  static Future<Map<String, dynamic>> verifyOtp(String payload, String otp) async {
    try {
      final resp = await http.post(
        Uri.parse('$_base/auth/register/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'verification_payload': payload, 'otp': otp}),
      ).timeout(_timeout);

      final data = jsonDecode(resp.body);
      if (resp.statusCode == 200 && data['status'] == 'success') {
        return {'success': true, 'registration_token': data['registration_token']};
      }
      return {'success': false, 'message': data['message'] ?? 'Invalid OTP'};
    } catch (e) {
      return {'success': false, 'message': 'Connection error.'};
    }
  }

  // ── Register: step 3 — complete profile ──────────────────────
  static Future<Map<String, dynamic>> completeRegister({
    required String username,
    required String names,
    required String email,
    required String password,
    String? registrationToken,
  }) async {
    try {
      final resp = await http.post(
        Uri.parse('$_base/auth/register/complete'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          if (registrationToken != null) 'registration_token': registrationToken,
          'username': username,
          'names': names,
          'email': email,
          'password': password,
        }),
      ).timeout(_timeout);

      final data = jsonDecode(resp.body);
      if ((resp.statusCode == 200 || resp.statusCode == 201) && data['status'] == 'success') {
        final user = AuthUser.fromJson(data['user'] as Map<String, dynamic>);
        await _persist(data['token'] as String, user);
        return {'success': true};
      }
      return {'success': false, 'message': data['message'] ?? 'Registration failed'};
    } catch (e) {
      return {'success': false, 'message': 'Connection error.'};
    }
  }

  // ── Fetch fresh profile ───────────────────────────────────────
  static Future<AuthUser?> fetchProfile() async {
    if (_token == null) return null;
    try {
      final resp = await http.get(
        Uri.parse('$_base/users/me'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      ).timeout(_timeout);

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final user = AuthUser.fromJson(data['user'] as Map<String, dynamic>);
        _user = user;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_keyUser, jsonEncode(user.toJson()));
        return user;
      }
    } catch (_) {}
    return _user;
  }

  // ── Auth header ───────────────────────────────────────────────
  static Map<String, String> get authHeaders => {
    'Content-Type':  'application/json',
    'Authorization': 'Bearer ${_token ?? ""}',
  };
}
