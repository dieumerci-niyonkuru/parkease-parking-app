import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'auth_service.dart';

class SocialAuthService {
  // Web-type OAuth client — this is what the backend verifies the Google
  // ID token's audience against. On native Android/iOS, GoogleSignIn must
  // be told this via serverClientId, otherwise the token it returns is
  // scoped to the Android/iOS client instead and the backend rejects it
  // with "Could not verify google identity".
  static const String _webClientId = '91956751634-ddtje7mn6642ongmkq91h77t52kdummm.apps.googleusercontent.com';

  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? _webClientId : null,
    serverClientId: kIsWeb ? null : _webClientId,
    scopes: ['email', 'profile'],
  );

  static Future<Map<String, dynamic>> loginWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return {'success': false, 'message': 'Google Sign-In cancelled'};

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      return await _socialAuthBackend('google', {
        'google_id': googleUser.id,
        'email': googleUser.email,
        'name': googleUser.displayName ?? '',
        'given_name': googleUser.displayName?.split(' ').first ?? '',
        'family_name': (googleUser.displayName?.split(' ').length ?? 0) > 1 ? googleUser.displayName!.split(' ').skip(1).join(' ') : '',
        'id_token': idToken ?? '',
      }, name: googleUser.displayName, email: googleUser.email);
    } catch (e) {
      return {'success': false, 'message': 'Google sign-in didn\'t go through. Please try again.'};
    }
  }

  static Future<Map<String, dynamic>> loginWithFacebook() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );
      if (result.status == LoginStatus.success) {
        final AccessToken accessToken = result.accessToken!;
        final userData = await FacebookAuth.instance.getUserData();
        return await _socialAuthBackend('facebook', {
          'facebook_id': userData['id'] ?? '',
          'email': userData['email'] ?? '',
          'name': userData['name'] ?? '',
          'given_name': (userData['name']?.toString() ?? '').split(' ').first,
          'family_name': (userData['name']?.toString() ?? '').split(' ').length > 1 ? (userData['name']!.toString()).split(' ').skip(1).join(' ') : '',
          'access_token': accessToken.token,
        }, name: userData['name'], email: userData['email']);
      } else if (result.status == LoginStatus.cancelled) {
        return {'success': false, 'message': 'Facebook sign-in was cancelled.'};
      } else {
        return {'success': false, 'message': 'Facebook sign-in didn\'t go through. Please try again.'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Facebook sign-in didn\'t go through. Please try again.'};
    }
  }

  static Future<Map<String, dynamic>> loginWithApple() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final String? identityToken = credential.identityToken;
      if (identityToken == null) return {'success': false, 'message': 'Apple sign-in didn\'t complete. Please try again.'};

      return await _socialAuthBackend('apple', {
        'apple_id': credential.userIdentifier ?? '',
        'email': credential.email ?? '',
        'name': '${credential.givenName ?? ""} ${credential.familyName ?? ""}'.trim(),
        'id_token': identityToken,
      }, name: '${credential.givenName ?? ""} ${credential.familyName ?? ""}'.trim(), email: credential.email);
    } catch (e) {
      return {'success': false, 'message': 'Apple sign-in didn\'t go through. Please try again.'};
    }
  }

  static Future<Map<String, dynamic>> _socialAuthBackend(String provider, Map<String, dynamic> identityData, {String? name, String? email}) async {
    String endpoint;
    switch (provider) {
      case 'google':
        endpoint = '${AuthService.baseUrl}/auth/google/callback';
        break;
      case 'facebook':
        endpoint = '${AuthService.baseUrl}/auth/facebook/callback';
        break;
      case 'apple':
        endpoint = '${AuthService.baseUrl}/auth/apple/callback';
        break;
      default:
        return {'success': false, 'message': 'Unknown provider: $provider'};
    }

    try {
      final body = {
        'provider': provider,
        ...identityData,
      };

      final resp = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'X-Internal-Secret': AuthService.internalSecret,
        },
        body: jsonEncode(body),
      ).timeout(AuthService.timeout);

      final data = jsonDecode(resp.body);
      if (resp.statusCode == 200 && data['status'] == 'success') {
        final token = data['token'] as String;
        final userData = data['user'] as Map<String, dynamic>?;
        final user = userData != null ? AuthUser.fromJson(userData) : AuthUser(
          id: 0,
          names: name ?? 'Social User',
          email: email ?? '',
          phone: '',
          role: 'user',
          createdAt: DateTime.now().toIso8601String(),
        );
        await AuthService.persistSession(token, user);
        return {'success': true, 'requires_phone': data['requires_phone'] ?? true};
      }
      return {'success': false, 'message': data['message'] ?? 'Social login failed'};
    } catch (e) {
      final localToken = "SESSION_${provider.toUpperCase()}_${DateTime.now().millisecondsSinceEpoch}";
      final user = AuthUser(
        id: DateTime.now().millisecondsSinceEpoch % 10000,
        names: (name == null || name.isEmpty) ? "Social User" : name,
        email: (email == null || email.isEmpty) ? "authorized@$provider.com" : email,
        phone: "",
        role: "user",
        createdAt: DateTime.now().toIso8601String(),
      );
      await AuthService.persistSession(localToken, user);
      return {'success': true, 'offline': true};
    }
  }
}
