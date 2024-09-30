import 'package:assassins/drive.dart';
import 'package:assassins/google_sign_in.dart' as sign_in;
import 'package:assassins/people.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SaveDialog extends StatefulWidget {
  const SaveDialog({super.key});
  @override
  State<StatefulWidget> createState() {
    return SaveDialogState();
  }
}

class SaveDialogState extends State<SaveDialog> {
  bool loading = false;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController fileController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: loading ? Container() : const Text("Save Players"),
      content: loading
          ? const AspectRatio(
              aspectRatio: 1.0, child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    autofocus: true,
                    onFieldSubmitted: (value) {},
                    controller: fileController,
                    decoration: const InputDecoration(
                        border: UnderlineInputBorder(), hintText: "Filename"),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please enter a filename";
                      }
                      return null;
                    },
                  ),
                  Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          ElevatedButton(
                              onPressed: () async {
                                trySubmit().then((_) {
                                  Navigator.pop(context);
                                });
                              },
                              child: const Text("Ok")),
                          ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: const Text("Cancel")),
                        ],
                      ))
                ],
              ),
            ),
    );
  }

  Future<void> trySubmit() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        loading = true;
      });
      var filename = "${fileController.text}.json";
      var jsonData = Provider.of<PeopleList>(context, listen: false).encode();
      var drive =
          Provider.of<sign_in.Credentials>(context, listen: false).drive!;
      var id = await fileExists(drive, filename);
      if (id == null) {
        await create(drive, filename, jsonData);
      } else {
        await update(drive, id, jsonData);
      }

      _formKey.currentState?.reset();
      setState(() {
        loading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("File saved!")));
      }
    }
  }
}
