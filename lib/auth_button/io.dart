import 'stub.dart';
import 'package:flutter/material.dart';

Widget renderButton({SignInCallback? callback}) {
  return ElevatedButton(
      onPressed: callback, child: const Text("Continue with Google"));
}
