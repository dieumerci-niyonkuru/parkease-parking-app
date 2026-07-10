import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

class UserProfile {
  final String name;
  final String email;
  final String phone;
  final String profilePic;

  const UserProfile({
    this.name  = '',
    this.email = '',
    this.phone = '',
    this.profilePic = '',
  });

  UserProfile copyWith({String? name, String? email, String? phone, String? profilePic}) =>
    UserProfile(
      name:  name  ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profilePic: profilePic ?? this.profilePic,
    );

  String get displayInitials {
    if (name.trim().isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name[0].toUpperCase();
  }

  String get displayName => name.trim().isEmpty ? 'Guest User' : name.trim();

  bool get hasData => name.isNotEmpty || email.isNotEmpty || phone.isNotEmpty;

  Map<String, dynamic> toJson() => {
    'name': name, 'email': email, 'phone': phone, 'profilePic': profilePic,
  };

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
    name:  j['name']  ?? '',
    email: j['email'] ?? '',
    phone: j['phone'] ?? '',
    profilePic: j['profilePic'] ?? '',
  );
}

class ProfileService {
  static const _key = 'user_profile_v1';
  static UserProfile _profile = const UserProfile();

  static UserProfile get profile => _profile;

  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw != null) _profile = UserProfile.fromJson(jsonDecode(raw));
    } catch (_) {}
  }

  static Future<void> save(UserProfile profile) async {
    _profile = profile;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(profile.toJson()));
  }

  static Future<void> update({String? name, String? email, String? phone, String? profilePic}) async {
    await save(_profile.copyWith(name: name, email: email, phone: phone, profilePic: profilePic));
  }

  static Future<bool> syncToServer() async {
    try {
      final resp = await http.put(
        Uri.parse('${AuthService.baseUrl}/users/me'),
        headers: AuthService.authHeaders,
        body: jsonEncode(_profile.toJson()),
      ).timeout(const Duration(seconds: 12));
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
