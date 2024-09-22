import 'dart:async';
import 'dart:developer' as dev;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:googleapis/drive/v3.dart';
import 'package:googleapis_auth/googleapis_auth.dart';

/// Returns null if the file does not exist, otherwise returns its id
Future<String?> fileExists(DriveApi drive, String filename) async {
  var list = await getFileList(drive);
  var index = list.indexWhere((file) => file.name == filename);
  if (index < 0) {
    return null;
  } else {
    return list.elementAt(index).id;
  }
}

Future<List<File>> getFileList(DriveApi drive) async {
  var list = await drive.files.list(spaces: "appDataFolder");
  if (list.files == null) {
    dev.log("Error: null file list");
    throw IOException;
  }
  if (list.incompleteSearch != null && list.incompleteSearch!) {
    dev.log("Incomplete search!");
  }

  return list.files!;
}

Future<File> create(DriveApi drive, String filename, String data) async {
  var stream = Stream.value(data.codeUnits);
  return drive.files.create(File(name: "appDataFolder/$filename"),
      uploadMedia: Media(stream, data.length, contentType: "application/json"));
}

Future<File> update(DriveApi drive, String id, String data) async {
  var stream = Stream.value(data.codeUnits);
  return drive.files.update(File(), id,
      uploadMedia: Media(stream, data.length, contentType: "application/json"));
}

class DriveFilePicker extends StatefulWidget {
  final DriveApi drive;

  const DriveFilePicker({super.key, required this.drive});

  @override
  State<StatefulWidget> createState() => DriveFilePickerState();
}

class DriveFilePickerState extends State<DriveFilePicker> {
  int? selected;
  List<File>? list;

  @override
  void initState() {
    super.initState();
    selected = null;
    unawaited(loadList());
  }

  Future<void> loadList() async {
    getFileList(widget.drive).then((value) => setState(() {
          list = value;
        }));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: (list != null)
          ? Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: list?.length,
                    itemBuilder: (context, index) {
                      var entry = list!.elementAt(index);

                      return Card(
                          child: ListTile(
                        selected: index == selected,
                        title: Text(entry.name ?? ""),
                        onTap: () {
                          setState(() {
                            selected = index;
                          });
                        },
                        // TODO add file delete button.
                      ));
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 8),
                    ElevatedButton(
                        onPressed: (selected == null)
                            ? null
                            : () async {
                                var media = await widget.drive.files.get(
                                    list!.elementAt(selected!).id!,
                                    downloadOptions: DownloadOptions.fullMedia);
                                if (context.mounted) {
                                  Navigator.pop(context, media);
                                }
                              },
                        child: const Text("Ok")),
                    const Spacer(flex: 1),
                    ElevatedButton(
                        onPressed: () => Navigator.pop(context, null),
                        child: const Text("Cancel")),
                    const Spacer(flex: 8),
                  ],
                ),
              ],
            )
          : const Expanded(child: CircularProgressIndicator()),
    );
  }
}
