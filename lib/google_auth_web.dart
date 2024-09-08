import 'dart:async';
import './people.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in_web/web_only.dart' as web;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:googleapis_auth/googleapis_auth.dart' as auth show AuthClient;
import 'package:googleapis/gmail/v1.dart';
import 'package:googleapis/drive/v3.dart';

const List<String> scopes = [
  GmailApi.gmailSendScope,
  DriveApi.driveAppdataScope
];

GoogleSignIn _googleSignIn = GoogleSignIn(
  // This is the "Web" client ID
  clientId:
      '936372921440-8hmb3lhi7s9j49907himf7vae8ko1u4d.apps.googleusercontent.com',
  scopes: scopes,
);

// class Credentials extends ChangeNotifier {
//   GoogleSignInAccount? _currentUser;
//   auth.AuthClient? _client;
//   GoogleSignInAccount? get user => _currentUser;
//   auth.AuthClient? get client => _client;
//
// }

class SignInWidget extends StatefulWidget {
  const SignInWidget({super.key});

  @override
  State<StatefulWidget> createState() => SignInState();
}

class SignInState extends State<SignInWidget> {
  GoogleSignInAccount? _currentUser;
  auth.AuthClient? client;
  bool _isAuthorized = false; // has granted permissions?

  @override
  void initState() {
    super.initState();

    _googleSignIn.onCurrentUserChanged
        .listen((GoogleSignInAccount? account) async {
      // In mobile, being authenticated means being authorized...
      bool isAuthorized = account != null;
      // However, on web...
      if (kIsWeb && account != null) {
        isAuthorized = await _googleSignIn.canAccessScopes(scopes);
      }

      setState(() {
        _currentUser = account;
        _isAuthorized = isAuthorized;
      });

      if (isAuthorized) {
        client ??= await _googleSignIn.authenticatedClient();
      }
    });
    // Trigger One Tap UI
    _googleSignIn.signInSilently();
  }

  Future<void> _handleAuthorizeScopes() async {
    final bool isAuthorized = await _googleSignIn.requestScopes(scopes);
    setState(() {
      _isAuthorized = isAuthorized;
    });
    if (isAuthorized) {
      client ??= await _googleSignIn.authenticatedClient();
    }
  }

  Future<void> _handleSignOut() => _googleSignIn.disconnect();

  @override
  Widget build(BuildContext context) {
    final GoogleSignInAccount? user = _currentUser;
    // Authenticated
    if (user != null) {
      // Authorized
      if (_isAuthorized) {
        return authorizedBuild(context);
      }
      // Authorization dialog
      else {
        return Column(children: [
          ElevatedButton(
            onPressed: _handleAuthorizeScopes,
            child: const Text('Give Permissions'),
          )
        ]);
      }
    }
    // Authentication button
    else {
      // return web.renderButton();
      return web.renderButton(
          configuration: web.GSIButtonConfiguration(
        theme: web.GSIButtonTheme.filledBlue,
        size: web.GSIButtonSize.large,
        // type: web.GSIButtonType.icon,
        text: web.GSIButtonText.continueWith,
        shape: web.GSIButtonShape.rectangular,
        logoAlignment: web.GSIButtonLogoAlignment.center,
      ));
    }
  }

  Widget authorizedBuild(BuildContext context) {
    return Column(children: [
      const Text("Authorized"),
      ElevatedButton(
          onPressed: () async {
            showDialog(context: context, builder: (BuildContext context) => AlertDialog(
            title: const Text("Sending emails"),
            content: LinearProgressIndicator(
              value: 0.5,
              semanticsLabel: "Emails sent",
            )
          ));
            await Provider.of<PeopleList>(context, listen: false)
                .sendEmails(client!, _currentUser!.email);
          },
          child: const Text("Send Emails")),
      ElevatedButton(onPressed: _handleSignOut, child: const Text("Sign out"))
    ]);
  }
}

// class EmailDialogue extends StatefulWidget {
//   const EmailDialogue({super.key});
//
//   @override
//   State<StatefulWidget> createState() => EmailDialogueState();
// }
//
// class EmailDialogueState extends State<EmailDialogue> {
//
//   @override
//   void initState() {
//     super.initState();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//       ElevatedButton(
//           onPressed: () async {
//             showDialog(context: context, builder: (BuildContext context) => AlertDialog(
//             title: const Text("Sending emails"),
//             content: LinearProgressIndicator(
//               value: 0.5,
//               semanticsLabel: "Emails sent",
//             )
//           ));
//             await Provider.of<PeopleList>(context, listen: false)
//                 .sendEmails(client!, _currentUser!.email);
//           },
//           child: const Text("Send Emails"));
//   }
// }
