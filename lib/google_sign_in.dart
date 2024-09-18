import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:googleapis_auth/googleapis_auth.dart' as auth show AuthClient;
import 'package:googleapis/gmail/v1.dart';
import 'package:googleapis/drive/v3.dart';

const List<String> scopes = [
  GmailApi.gmailSendScope,
  DriveApi.driveAppdataScope
];

GoogleSignIn googleSignIn = GoogleSignIn(scopes: scopes);

Future<void> mobileSignIn() async {
  try {
    await googleSignIn.signIn();
  } catch (e) {
    developer.log("Mobile sign in error: ", error: e);
  }
}

class Credentials extends ChangeNotifier {
  GoogleSignInAccount? _currentUser;
  bool _isAuthorized = false;
  auth.AuthClient? _client;
  GoogleSignInAccount? get user => _currentUser;
  bool get isAuthorized => _isAuthorized;
  auth.AuthClient? get client => _client;

  Future<void> setClient() async {
    _client ??= await googleSignIn.authenticatedClient();
  }

  Future<void> tryLogin(GoogleSignInAccount? account) async {
    bool isAuthorized = account != null;
    if (kIsWeb && isAuthorized) {
      isAuthorized = await googleSignIn.canAccessScopes(scopes);
    }

    _currentUser = account;
    _isAuthorized = isAuthorized;

    if (isAuthorized) {
      setClient();
    }

    notifyListeners();
  }

  Future<void> authorizeScopes() async {
    final bool isAuthorized = await googleSignIn.requestScopes(scopes);
    _isAuthorized = isAuthorized;
    if (isAuthorized) {
      setClient();
    }

    notifyListeners();
  }
}
