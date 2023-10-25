import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class TextDialog extends HookWidget {
  const TextDialog({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(onPressed: () {
      showTextDialog(context);
    });
  }

  showTextDialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Insert text!"),
            content: const SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  Text("ORAS ORAS, VAMOS COLCOAR TEXTO NESSA BUGIRANGA!"),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text("Done"),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          );
        });
  }
}
