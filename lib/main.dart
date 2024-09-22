import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:googleapis/drive/v3.dart';

import 'package:assassins/auth_button.dart';
import 'package:assassins/drive.dart';
import 'package:assassins/save_send_tab.dart';
import 'package:assassins/google_sign_in.dart' as sign_in;
import 'package:assassins/people.dart';

void main() {
  runApp(const MyApp());
}

class AssignmentTab extends StatelessWidget {
  const AssignmentTab({super.key});
  @override
  Widget build(BuildContext context) {
    return Column(children: <Widget>[
      Expanded(child: Consumer<PeopleList>(
        builder: (context, people, child) {
          if (people.isEmpty()) {
            return const Center(
                child: Text(
                    "Please return to the Players tab and add players first."));
          } else if (people.ordered()) {
            return people.orderView();
          }
          return const Text(
              "Press the randomize button to generate target assignments.");
        },
      )),
      BottomAppBar(
          child: Row(children: [
        Expanded(
          child: FloatingActionButton(
            onPressed: () {
              Provider.of<PeopleList>(context, listen: false).makeOrder();
            },
            child: const Text("Randomize"),
          ),
        )
      ]))
    ]);
  }
}

class ListTab extends StatelessWidget {
  const ListTab({super.key});
  @override
  Widget build(BuildContext context) {
    return Consumer<PeopleList>(
      builder: (context, people, child) {
        if (people.numPeople > 0) {
          return Column(children: <Widget>[
            Expanded(
                child: ListView.builder(
                    itemCount: people.numPeople,
                    itemBuilder: (context, index) {
                      return people.personEntry(index);
                    })),
            child!
            // const BottomAppBar(child: PersonForm()),
          ]);
        } else {
          return Consumer<sign_in.Credentials>(
              builder: (context, credentials, _) {
            Widget button;
            if (credentials.user != null) {
              if (credentials.isAuthorized) {
                button = ElevatedButton(
                    onPressed: () {
                      var file = showDialog<Future<Object>?>(
                          context: context,
                          builder: (context) {
                            var drive = Provider.of<sign_in.Credentials>(
                                    context,
                                    listen: false)
                                .drive!;
                            return DriveFilePicker(drive: drive);
                          });
                      // TODO load players from file data
                      // file.then(onValue)
                    },
                    child: const Text("Load from Drive"));
              } else {
                button = ElevatedButton(
                  onPressed: credentials.authorizeScopes,
                  child: const Text('Authorize'),
                );
              }
            } else {
              button = renderButton(callback: sign_in.mobileSignIn);
            }
            return Column(children: [
              const Spacer(flex: 14),
              const Text(
                "Add players to the list using the fields at the bottom, or login to load a previously saved list from Google Drive.",
                textScaler: TextScaler.linear(1.3),
              ),
              const Spacer(flex: 1),
              button,
              const Spacer(flex: 14),
              child!
            ]);
          });
        }
      },
      child: const BottomAppBar(child: PersonForm()),
    );
    //
  }
}

// App root
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => PeopleList()),
          ChangeNotifierProvider(create: (context) => sign_in.Credentials()),
        ],
        child: MaterialApp(
            title: 'Assassins',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                  seedColor: Colors.deepPurple, brightness: Brightness.dark),
              useMaterial3: true,
            ),
            themeMode: ThemeMode.dark,
            home: const MyHomePage(title: "Assassins"))
        // child: const MyHomePage(title: 'Assassins')),
        );
  }
}

class MyHomePage extends StatelessWidget {
  final String title;
  const MyHomePage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    sign_in.googleSignIn.onCurrentUserChanged.listen((account) =>
        Provider.of<sign_in.Credentials>(context, listen: false)
            .tryLogin(account));
    return DefaultTabController(
        length: 3,
        initialIndex: 0,
        child: Scaffold(
          appBar: AppBar(
              backgroundColor: Theme.of(context).colorScheme.inversePrimary,
              title: Text(title),
              bottom: const TabBar(tabs: <Widget>[
                Tab(
                  icon: Icon(Icons.list),
                  text: "Players",
                ),
                Tab(icon: Icon(Icons.sports_kabaddi), text: "Assignments"),
                Tab(icon: Icon(Icons.send), text: "Save/Send"),
              ])),
          body: const TabBarView(
            children: <Widget>[ListTab(), AssignmentTab(), SignInTopLevel()],
          ),
        ));
  }
}

class PersonForm extends StatefulWidget {
  const PersonForm({super.key});

  @override
  State<StatefulWidget> createState() {
    return PersonFormState();
  }
}

class PersonFormState extends State<PersonForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  late FocusNode nameFocus;

  @override
  void initState() {
    super.initState();
    nameFocus = FocusNode();
  }

  @override
  void dispose() {
    nameFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
        key: _formKey,
        child: Row(
          children: [
            Expanded(
                child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: TextFormField(
                      autofocus: true,
                      focusNode: nameFocus,
                      onFieldSubmitted: (value) {
                        trySubmit();
                      },
                      controller: nameController,
                      decoration: const InputDecoration(
                          border: UnderlineInputBorder(), hintText: "Name"),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Please enter a name";
                        }
                        return null;
                      },
                    ))),
            Expanded(
                child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: TextFormField(
                      onFieldSubmitted: (value) {
                        trySubmit();
                      },
                      controller: emailController,
                      decoration: const InputDecoration(
                          border: UnderlineInputBorder(), hintText: "Email"),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Please enter an email address";
                        } else if (!value.contains("@") ||
                            !value.contains(".")) {
                          return "Please enter a valid email address";
                        }
                        return null;
                      },
                    ))),
            FloatingActionButton(
                onPressed: trySubmit, child: const Icon(Icons.add))
          ],
        ));
  }

  trySubmit() {
    if (_formKey.currentState!.validate()) {
      Provider.of<PeopleList>(context, listen: false)
          .add(Person(nameController.text, emailController.text));
      _formKey.currentState?.reset();
      nameFocus.requestFocus();
    }
  }
}
