import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class UserProfile {
  final String name;
  final String email;
  final String phone;

  const UserProfile({
    this.name  = '',
    this.email = '',
    this.phone = '',
  });

  UserProfile copyWith({String? name, String? email, String? phone}) =>
    UserProfile(
      name:  name  ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
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
    'name': name, 'email': email, 'phone': phone,
  };

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
    name:  j['name']  ?? '',
    email: j['email'] ?? '',
    phone: j['phone'] ?? '',
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

  static Future<void> update({String? name, String? email, String? phone}) async {
    await save(_profile.copyWith(name: name, email: email, phone: phone));
  }
}
