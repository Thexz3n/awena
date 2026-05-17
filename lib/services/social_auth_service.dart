import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

class SocialAuthService {
  static final SocialAuthService instance = SocialAuthService._();
  SocialAuthService._();

  // Read IDs from the .env file
  static String get _googleClientId => dotenv.get('GOOGLE_CLIENT_ID', fallback: '');

  GoogleSignIn? _googleSignIn;

  GoogleSignIn _getGoogleSignIn() {
    if (_googleSignIn != null) return _googleSignIn!;
    
    final clientId = _googleClientId;
    print('DEBUG: Initializing GoogleSignIn with Client ID: ${clientId.isEmpty ? "EMPTY!" : clientId.substring(0, 10) + "..."}');
    
    _googleSignIn = GoogleSignIn(
      clientId: kIsWeb ? clientId : null,
      scopes: ['email', 'openid'], // Minimal scopes often work better for ID Tokens
    );
    return _googleSignIn!;
  }

  /// Triggers Google Sign-In and returns the ID Token.
  Future<String?> signInWithGoogle() async {
    try {
      print('DEBUG: Starting Google Sign-In...');
      final googleService = _getGoogleSignIn();
      
      // 1. Trigger the sign-in flow
      final GoogleSignInAccount? account = await googleService.signIn();
      
      if (account == null) {
        print('DEBUG: Google Sign-In returned null (User cancelled or blocked).');
        return null;
      }

      print('DEBUG: Google Sign-In successful for: ${account.email}');

      // 2. Get authentication details
      print('DEBUG: Requesting authentication tokens...');
      final GoogleSignInAuthentication auth = await account.authentication;
      
      if (auth.idToken == null) {
        print('DEBUG: idToken is null. Using AccessToken as fallback for Web.');
      }

      return auth.idToken ?? auth.accessToken;
    } catch (e, stack) {
      print('CRITICAL: Google Sign-In Error: $e');
      print('STACKTRACE: $stack');
      return null;
    }
  }

  Future<void> signOut() async {
    if (_googleSignIn != null) {
      await _googleSignIn!.signOut();
    }
    await FacebookAuth.instance.logOut();
  }

  /// Triggers Facebook Sign-In and returns the Access Token.
  Future<String?> signInWithFacebook() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['public_profile', 'email'],
      );

      if (result.status == LoginStatus.success) {
        return result.accessToken?.tokenString;
      }
      return null;
    } catch (e) {
      print('Facebook Sign-In Error: $e');
      return null;
    }
  }
}
