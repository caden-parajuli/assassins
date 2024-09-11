import 'stub.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in_web/web_only.dart' as gweb;

Widget renderButton({SignInCallback? callback}) {
  return gweb.renderButton(
      configuration: gweb.GSIButtonConfiguration(
    theme: gweb.GSIButtonTheme.filledBlue,
    size: gweb.GSIButtonSize.large,
    text: gweb.GSIButtonText.continueWith,
    shape: gweb.GSIButtonShape.rectangular,
    logoAlignment: gweb.GSIButtonLogoAlignment.center,
  ));
}
