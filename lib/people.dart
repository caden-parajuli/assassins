import 'dart:collection';

import 'package:flutter/material.dart';

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
    return Container(
        margin: const EdgeInsets.all(2.0),
        padding: const EdgeInsets.all(1.0),
        decoration: BoxDecoration(
            color: Colors.white12,
            border: Border.all(width: 1.0, color: Colors.white38)),
        child: Row(children: [
          Expanded(
              flex: 4,
              child: Padding(
                  padding: const EdgeInsets.only(left: 5.0),
                  child: Text(_people[index].name))),
          Expanded(flex: 4, child: Text(people[index].email)),
          // const Spacer(flex: 1),
          ElevatedButton(
              style: const ButtonStyle(
                  backgroundColor: WidgetStatePropertyAll<Color>(Colors.red)),
              onPressed: () => removeAt(index),
              child: const Icon(Icons.delete, color: Colors.white,))
        ]));
  }

  void remove(Person person) {
    _people.remove(person);
    notifyListeners();
  }

  void removeAt(int index) {
    _people.removeAt(index);
    notifyListeners();
  }
}
