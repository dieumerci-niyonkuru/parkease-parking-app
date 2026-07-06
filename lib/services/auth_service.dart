import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'api_service.dart';

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
  static const String _keyCreds = 'biometric_credentials';

  static const _secure = FlutterSecureStorage();
  static final _localAuth = LocalAuthentication();
  static final _googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? '1053355555555-google-apps-default-id.apps.googleusercontent.com' : null,
    scopes: ['email', 'profile'],
  );

  // ── Cached state ──────────────────────────────────────────────
  static String?   _token;
  static AuthUser? _user;

  static String?   get token => _token;
  static AuthUser? get user  => _user;
  static bool      get isLoggedIn => _token != null && _user != null;

  // ── Biometrics ────────────────────────────────────────────────
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
    final raw = prefs.getString(_keyUser);
    if (raw != null) {
      try { _user = AuthUser.fromJson(jsonDecode(raw)); } catch (_) {}
    }
  }

  static Future<void> _persist(String token, AuthUser user) async {
    _token = token;
    _user  = user;
    await _secure.write(key: _keyToken, value: token);
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
    // Allow offline sessions to bypass validation
    if (_token == "OFFLINE_SESSION") return true;
    
    try {
      final resp = await http.post(
        Uri.parse('$_base/auth/validate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': _token}),
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
        Uri.parse('$_base/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': email, 'password': password}),
      ).timeout(_timeout);

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
          await _persist(token, user);
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
      return {'success': false, 'message': 'Connection error. Check your network.'};
    }
  }

  // ── Social Logins ──────────────────────────────────────────────

  static Future<Map<String, dynamic>> loginWithGoogle() async {
    if (kIsWeb) return await _socialAuthBackend('google', 'web_demo_token');
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return {'success': false, 'message': 'Google Sign-In cancelled'};

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) return {'success': false, 'message': 'Failed to retrieve Google ID Token'};

      return await _socialAuthBackend('google', idToken);
    } catch (e) {
      return {'success': false, 'message': 'Google Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> loginWithFacebook() async {
    if (kIsWeb) return await _socialAuthBackend('facebook', 'web_demo_token');
    try {
      final LoginResult result = await FacebookAuth.instance.login();
      if (result.status == LoginStatus.success) {
        final AccessToken accessToken = result.accessToken!;
        return await _socialAuthBackend('facebook', accessToken.token);
      } else {
        return {'success': false, 'message': 'Facebook Login failed: ${result.message}'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Facebook Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> loginWithApple() async {
    if (kIsWeb) return await _socialAuthBackend('apple', 'web_demo_token');
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      
      final String? identityToken = credential.identityToken;
      if (identityToken == null) return {'success': false, 'message': 'Failed to retrieve Apple Identity Token'};

      return await _socialAuthBackend('apple', identityToken);
    } catch (e) {
      return {'success': false, 'message': 'Apple Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> _socialAuthBackend(String provider, String token) async {
    // ── WEB DEMO MODE ──────────────────────────────────────────
    // This allows the app to be fully usable on Chrome for testing
    if (kIsWeb) {
      await Future.delayed(const Duration(seconds: 1));
      // Log in as a demo user for web testing
      _token = "DEMO_WEB_SESSION";
      _user = const AuthUser(
        id: 999,
        names: "Roger Driver",
        email: "roger@itec.rw",
        phone: "+250 788 000 000",
        role: "user",
        createdAt: "2026-07-04",
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyUser, jsonEncode(_user!.toJson()));
      return {'success': true};
    }

    try {
      final resp = await http.post(
        Uri.parse('$_base/auth/social'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'provider': provider,
          'token': token,
        }),
      ).timeout(_timeout);

      final data = jsonDecode(resp.body);
      if (resp.statusCode == 200 && data['status'] == 'success') {
        final jwtToken = data['token'] as String;
        final user = AuthUser.fromJson(data['user'] as Map<String, dynamic>);
        await _persist(jwtToken, user);
        return {'success': true};
      }
      return {'success': false, 'message': data['message'] ?? '$provider Login failed at server'};
    } catch (e) {
      return {'success': false, 'message': 'Backend Connection error.'};
    }
  }

  // ── Register: step 1 — send OTP ──────────────────────────────
  static Future<Map<String, dynamic>> initiateRegister(String phone) async {
    try {
      final resp = await http.post(
        Uri.parse('$_base/auth/register/initiate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': phone,
        }),
      ).timeout(_timeout);

      final data = jsonDecode(resp.body);
      if (resp.statusCode == 200 && data['status'] == 'success') {
        return {
          'success': true,
          'verification_payload': data['verification_payload'],
        };
      }
      return {'success': false, 'message': data['message'] ?? 'Failed to send OTP'};
    } catch (e) {
      return {'success': false, 'message': 'Connection error.'};
    }
  }

  // ── Register: step 2 — verify OTP ────────────────────────────
  static Future<Map<String, dynamic>> verifyOtp(String verificationPayload, String otp) async {
    try {
      final resp = await http.post(
        Uri.parse('$_base/auth/register/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'verification_payload': verificationPayload,
          'otp': otp,
        }),
      ).timeout(_timeout);

      final data = jsonDecode(resp.body);
      if (resp.statusCode == 200 && data['status'] == 'success') {
        return {
          'success': true,
          'registration_token': data['registration_token'],
        };
      }
      return {'success': false, 'message': data['message'] ?? 'Invalid OTP'};
    } catch (e) {
      return {'success': false, 'message': 'Connection error.'};
    }
  }

  // ── Register: step 2.5 — verify reclaim OTP ──────────────────
  static Future<Map<String, dynamic>> verifyReclaimOtp(String verificationPayload, String otp) async {
    try {
      final resp = await http.post(
        Uri.parse('$_base/auth/register/verify-reclaim-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'verification_payload': verificationPayload,
          'otp': otp,
        }),
      ).timeout(_timeout);

      final data = jsonDecode(resp.body);
      if (resp.statusCode == 200 && data['status'] == 'success') {
        return {
          'success': true,
          'registration_token': data['registration_token'],
          'phone_number': data['phone_number'],
        };
      }
      return {'success': false, 'message': data['message'] ?? 'Invalid OTP'};
    } catch (e) {
      return {'success': false, 'message': 'Connection error.'};
    }
  }

  // ── Register: step 3 — complete profile ──────────────────────
  static Future<Map<String, dynamic>> completeRegister({
    required String registrationToken,
    required String names,
    required String email,
    required String password,
  }) async {
    try {
      final resp = await http.post(
        Uri.parse('$_base/auth/register/complete'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'registration_token': registrationToken,
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
      } else if (resp.statusCode == 401) {
        ApiService.onSessionExpired?.call();
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
