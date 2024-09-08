import 'dart:collection';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:googleapis/gmail/v1.dart';
import 'package:googleapis_auth/googleapis_auth.dart' as auth show AuthClient;

class Person {
  final String name;
  final String email;
  Person(this.name, this.email);
}

class PeopleList extends ChangeNotifier {
  final List<Person> _people = [];
  List<int> _order = [];
  int get numPeople => _people.length;
  UnmodifiableListView<int> get order => UnmodifiableListView(_order);
  UnmodifiableListView<Person> get people => UnmodifiableListView(_people);

  void add(Person person) {
    _people.add(person);
    notifyListeners();
  }

  bool isEmpty() {
    return _people.isEmpty;
  }

  void makeOrder() {
    _order = Iterable<int>.generate(_people.length).toList();
    _order.shuffle();
    notifyListeners();
  }

  bool ordered() {
    return _people.length == _order.length && _order.every((any) => any >= 0);
  }

  Widget orderView() {
    var entries = <Widget>[];
    for (var i = 0; i < _people.length - 1; i++) {
      entries.add(
          Text("${_people[_order[i]].name} -> ${_people[_order[i + 1]].name}"));
    }
    entries.add(Text(
        "${_people[_order[_people.length - 1]].name} -> ${_people[_order[0]].name}"));
    return ListView(children: entries);
  }

  Widget personEntry(int index) {
    return Row(children: [
      Expanded(
          flex: 4,
          child: Padding(
              padding: const EdgeInsets.only(left: 5.0),
              child: Text(_people[index].name))),
      Expanded(flex: 4, child: Text(people[index].email)),
      const Spacer(flex: 1),
    ]);
  }

  void remove(Person person) {
    _people.remove(person);
    notifyListeners();
  }

  void removeAt(int index) {
    _people.removeAt(index);
    notifyListeners();
  }

  Future<List<ApiRequestError>> sendEmails(
      auth.AuthClient client, String sendFrom) async {
    final GmailApi gmailApi = GmailApi(client);

    List<ApiRequestError> results = [];
    for (var i = 0; i < _people.length; i++) {
      final assassin = _people[_order[i]];
      final target = _people[_order[(i + 1) % _people.length]];
      Message message = Message(
          raw: base64UrlEncode(("Content-type: text/plain; charset=\"UTF-8\"\n"
                  "From: $sendFrom\n"
                  "To: ${assassin.email}\n"
                  "Subject: Assassins Target\n\n"
                  "Hi ${assassin.name},\n\nYour target is ${target.name}. Happy hunting!")
              .codeUnits));
      try {
        await gmailApi.users.messages.send(message, 'me');
      } on ApiRequestError catch (e) {
        print(e.message);
        results.add(e);
      }
    }
    return results;
  }
}
