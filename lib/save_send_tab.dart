import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:assassins/save_dialog.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:googleapis/gmail/v1.dart';

import 'people.dart';
import 'google_sign_in.dart' as sign_in;
import 'auth_button.dart' as auth_button;

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

    // Trigger One Tap UI
    if (Provider.of<sign_in.Credentials>(context, listen: false).user == null) {
      sign_in.googleSignIn.signInSilently();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<sign_in.Credentials>(
        builder: (context, credentials, child) {
      if (credentials.user != null) {
        if (credentials.isAuthorized) {
          return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            ElevatedButton(
                onPressed: () async {
                  showDialog(
                      context: context,
                      builder: (BuildContext context) => const EmailDialog());
                },
                child: const Text("Send Emails")),
            ElevatedButton(
                onPressed: () {
                  showDialog(
                      context: context,
                      builder: (context) {
                        return const SaveDialog();
                      });
                },
                child: const Text("Save Players")),
            ElevatedButton(
                onPressed: sign_in.googleSignIn.disconnect,
                child: const Text("Sign out"))
          ]);
        } else {
          return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            ElevatedButton(
              onPressed: credentials.authorizeScopes,
              child: const Text('Authorize'),
            )
          ]);
        }
      } else {
        return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          auth_button.renderButton(callback: sign_in.mobileSignIn)
        ]);
      }
    });
  }
}

class EmailDialog extends StatefulWidget {
  const EmailDialog({super.key});

  @override
  State<StatefulWidget> createState() => EmailDialogState();
}

class EmailDialogState extends State<EmailDialog> {
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
        Provider.of<sign_in.Credentials>(context, listen: false).user!.email;

    final GmailApi gmailApi = GmailApi(
        Provider.of<sign_in.Credentials>(context, listen: false).client!);

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
