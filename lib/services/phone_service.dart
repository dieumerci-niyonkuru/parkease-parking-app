import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class PhoneNumber {
  final int id;
  final String phone;
  final bool isPrimary;
  final bool isVerified;
  final String createdAt;

  const PhoneNumber({
    required this.id,
    required this.phone,
    required this.isPrimary,
    required this.isVerified,
    required this.createdAt,
  });

  factory PhoneNumber.fromJson(Map<String, dynamic> j) => PhoneNumber(
    id:         j['id']          ?? j['phone_id'] ?? 0,
    phone:      j['phone']       ?? j['phone_number'] ?? '',
    isPrimary:  j['is_primary']  ?? j['primary'] ?? false,
    isVerified: j['is_verified'] ?? j['verified'] ?? false,
    createdAt:  j['created_at']  ?? '',
  );
}

class PhoneService {
  static const String _base    = 'https://client-api.iteccone.com';
  static const Duration _timeout = Duration(seconds: 12);

  // ── List all phone numbers ────────────────────────────────────
  static Future<List<PhoneNumber>> getPhones() async {
    try {
      final resp = await http.get(
        Uri.parse('$_base/users/me/phones'),
        headers: AuthService.authHeaders,
      ).timeout(_timeout);

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final list = (data['phones'] ?? data['data'] ?? []) as List;
        return list.map((e) => PhoneNumber.fromJson(e)).toList();
      }
    } catch (_) {}

    // Fallback: build from auth user
    final user = AuthService.user;
    if (user != null && user.phone.isNotEmpty) {
      return [
        PhoneNumber(
          id: 1,
          phone: user.phone,
          isPrimary: true,
          isVerified: true,
          createdAt: user.createdAt,
        ),
      ];
    }
    return [];
  }

  // ── Quick Add (no OTP) ────────────────────────────────────────
  static Future<Map<String, dynamic>> quickAdd(String phone) async {
    try {
      final resp = await http.post(
        Uri.parse('$_base/users/me/phones'),
        headers: AuthService.authHeaders,
        body: jsonEncode({'phone': phone}),
      ).timeout(_timeout);

      final data = jsonDecode(resp.body);
      if (resp.statusCode == 200 || resp.statusCode == 201) {
        return {'success': true, 'message': 'Phone number added.'};
      }
      return {'success': false, 'message': data['message'] ?? 'Failed to add number.'};
    } catch (e) {
      return {'success': false, 'message': 'Connection error.'};
    }
  }

  // ── Step 1: initiate verify (send OTP) ───────────────────────
  static Future<Map<String, dynamic>> initiateVerify(String phone) async {
    try {
      final resp = await http.post(
        Uri.parse('$_base/users/phone/verify/initiate'),
        headers: AuthService.authHeaders,
        body: jsonEncode({'phone': phone}),
      ).timeout(_timeout);

      final data = jsonDecode(resp.body);
      if (resp.statusCode == 200 && data['status'] == 'success') {
        return {'success': true, 'verification_payload': data['verification_payload']};
      }
      return {'success': false, 'message': data['message'] ?? 'Failed to send OTP.'};
    } catch (_) {
      return {'success': false, 'message': 'Connection error.'};
    }
  }

  // ── Step 2: confirm OTP ───────────────────────────────────────
  static Future<Map<String, dynamic>> confirmVerify(
      String payload, String otp) async {
    try {
      final resp = await http.post(
        Uri.parse('$_base/users/phone/verify/complete'),
        headers: AuthService.authHeaders,
        body: jsonEncode({'verification_payload': payload, 'otp': otp}),
      ).timeout(_timeout);

      final data = jsonDecode(resp.body);
      if (resp.statusCode == 200 && data['status'] == 'success') {
        return {'success': true};
      }
      return {'success': false, 'message': data['message'] ?? 'Invalid OTP.'};
    } catch (_) {
      return {'success': false, 'message': 'Connection error.'};
    }
  }

  // ── Reclaim a phone number ────────────────────────────────────
  static Future<Map<String, dynamic>> reclaim(String phone) async {
    try {
      final resp = await http.post(
        Uri.parse('$_base/auth/phone/reclaim/initiate'),
        headers: AuthService.authHeaders,
        body: jsonEncode({'phone': phone}),
      ).timeout(_timeout);

      final data = jsonDecode(resp.body);
      if (resp.statusCode == 200 && data['status'] == 'success') {
        return {'success': true, 'verification_payload': data['verification_payload'] ?? phone};
      }
      return {'success': false, 'message': data['message'] ?? 'Failed to reclaim.'};
    } catch (_) {
      return {'success': false, 'message': 'Connection error.'};
    }
  }

  // ── Reclaim a phone number (Verify) ─────────────────────────
  static Future<Map<String, dynamic>> reclaimVerify(String phone, String otp) async {
    try {
      final resp = await http.post(
        Uri.parse('$_base/auth/phone/reclaim/verify'),
        headers: AuthService.authHeaders,
        body: jsonEncode({'phone': phone, 'otp': otp}),
      ).timeout(_timeout);

      final data = jsonDecode(resp.body);
      if (resp.statusCode == 200 && data['status'] == 'success') {
        return {'success': true};
      }
      return {'success': false, 'message': data['message'] ?? 'Invalid OTP.'};
    } catch (_) {
      return {'success': false, 'message': 'Connection error.'};
    }
  }
  static Future<Map<String, dynamic>> deletePhone(int id) async {
    try {
      final resp = await http.delete(
        Uri.parse('$_base/users/me/phones/$id'),
        headers: AuthService.authHeaders,
      ).timeout(_timeout);

      if (resp.statusCode == 200 || resp.statusCode == 204) {
        return {'success': true};
      }
      final data = jsonDecode(resp.body);
      return {'success': false, 'message': data['message'] ?? 'Failed to delete.'};
    } catch (_) {
      return {'success': false, 'message': 'Connection error.'};
    }
  }

  // ── Set primary phone ─────────────────────────────────────────
  static Future<Map<String, dynamic>> setPrimary(int id) async {
    try {
      final resp = await http.put(
        Uri.parse('$_base/users/me/phones/$id/primary'),
        headers: AuthService.authHeaders,
      ).timeout(_timeout);

      if (resp.statusCode == 200) {
        return {'success': true};
      }
      final data = jsonDecode(resp.body);
      return {'success': false, 'message': data['message'] ?? 'Failed to set primary.'};
    } catch (_) {
      return {'success': false, 'message': 'Connection error.'};
    }
  }
}
