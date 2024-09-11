import 'stub.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in_web/web_only.dart' as web;

Widget renderButton(SignInCallback callback) {
  return web.renderButton(
      configuration: web.GSIButtonConfiguration(
    theme: web.GSIButtonTheme.filledBlue,
    size: web.GSIButtonSize.large,
    text: web.GSIButtonText.continueWith,
    shape: web.GSIButtonShape.rectangular,
    logoAlignment: web.GSIButtonLogoAlignment.center,
  ));
}
