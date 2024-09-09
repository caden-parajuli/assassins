import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in_web/web_only.dart' as web;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:googleapis_auth/googleapis_auth.dart' as auth show AuthClient;
import 'package:googleapis/gmail/v1.dart';
import 'package:googleapis/drive/v3.dart';

import './people.dart';

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

class Credentials extends ChangeNotifier {
  GoogleSignInAccount? _currentUser;
  bool _isAuthorized = false;
  auth.AuthClient? _client;
  GoogleSignInAccount? get user => _currentUser;
  bool get isAuthorized => _isAuthorized;
  auth.AuthClient? get client => _client;

  Future<void> setClient() async {
    _client ??= await _googleSignIn.authenticatedClient();
  }

  Future<void> tryLogin(GoogleSignInAccount? account) async {
    bool isAuthorized = account != null;
    if (kIsWeb && isAuthorized) {
      isAuthorized = await _googleSignIn.canAccessScopes(scopes);
    }

    _currentUser = account;
    _isAuthorized = isAuthorized;

    if (isAuthorized) {
      setClient();
    }

    notifyListeners();
  }

  Future<void> authorizeScopes() async {
    final bool isAuthorized = await _googleSignIn.requestScopes(scopes);
    _isAuthorized = isAuthorized;
    if (isAuthorized) {
      setClient();
    }

    notifyListeners();
  }
}

class SignInTopLevel extends StatelessWidget {
  const SignInTopLevel({super.key});
  @override
  Widget build(BuildContext context) {
    return const SignInWidget();
  }
}

class SignInWidget extends StatefulWidget {
  const SignInWidget({super.key});

  @override
  State<StatefulWidget> createState() => SignInState();
}

class SignInState extends State<SignInWidget> {
  @override
  void initState() {
    super.initState();

    _googleSignIn.onCurrentUserChanged.listen((account) =>
        Provider.of<Credentials>(context, listen: false).tryLogin(account));
    // Trigger One Tap UI
    _googleSignIn.signInSilently();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<Credentials>(builder: (context, credentials, child) {
      if (credentials.user != null) {
        if (credentials.isAuthorized) {
          return Column(children: [
            ElevatedButton(
                onPressed: () async {
                  showDialog(
                      context: context,
                      builder: (BuildContext context) => const EmailDialogue());
                },
                child: const Text("Send Emails")),
            ElevatedButton(
                onPressed: _googleSignIn.disconnect,
                child: const Text("Sign out"))
          ]);
        } else {
          return Column(children: [
            ElevatedButton(
              onPressed: () {
                Provider.of<Credentials>(context, listen: false)
                    .authorizeScopes();
              },
              child: const Text('Give Permissions'),
            )
          ]);
        }
      } else {
        return web.renderButton(
            configuration: web.GSIButtonConfiguration(
          theme: web.GSIButtonTheme.filledBlue,
          size: web.GSIButtonSize.large,
          text: web.GSIButtonText.continueWith,
          shape: web.GSIButtonShape.rectangular,
          logoAlignment: web.GSIButtonLogoAlignment.center,
        ));
      }
    });
  }
}

class EmailDialogue extends StatefulWidget {
  const EmailDialogue({super.key});

  @override
  State<StatefulWidget> createState() => EmailDialogueState();
}

class EmailDialogueState extends State<EmailDialogue> {
  int emailsSent = 0;
  int totalEmails = 1;

  @override
  void initState() {
    super.initState();

    totalEmails = Provider.of<PeopleList>(context, listen: false).people.length;
  }

  @override
  Widget build(BuildContext context) {
    sendEmails().then((erg) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Emails sent!")));
    });
    return AlertDialog(
        title: const Text("Sending emails"),
        content: LinearProgressIndicator(
          value: emailsSent / totalEmails,
          semanticsLabel: "Emails sent",
        ));
  }

  Future<void> sendEmails() async {
    final people = Provider.of<PeopleList>(context, listen: false).people;
    final order = Provider.of<PeopleList>(context, listen: false).order;
    final sendFrom =
        Provider.of<Credentials>(context, listen: false).user!.email;

    final GmailApi gmailApi =
        GmailApi(Provider.of<Credentials>(context, listen: false).client!);

    List<ApiRequestError> results = [];
    for (var i = 0; i < people.length; i++) {
      DateTime lastTime = DateTime.now();
      final assassin = people[order[i]];
      final target = people[order[(i + 1) % people.length]];
      Message message = Message(
          raw: base64UrlEncode(("Content-type: text/plain; charset=\"UTF-8\"\n"
                  "From: $sendFrom\n"
                  "To: ${assassin.email}\n"
                  "Subject: Assassins Target\n\n"
                  "Hi ${assassin.name},\n\nYour target is ${target.name}. Happy hunting!")
              .codeUnits));
      try {
        await gmailApi.users.messages.send(message, 'me');
        int msSince = DateTime.now().difference(lastTime).inMilliseconds;
        if (msSince < 500) {
          await Future.delayed(Duration(milliseconds: 500 - msSince));
        }
      } on ApiRequestError catch (e) {
        if (e.message != null) {
          developer.log(e.message!);
        }
        results.add(e);
      }
      setState(() {
        emailsSent += 1;
      });
    }
  }
}
