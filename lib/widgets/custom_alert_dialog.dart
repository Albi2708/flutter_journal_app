import 'package:flutter/material.dart';

Future<T?> showCustomDialog<T>({
  required BuildContext context,
  required String title,
  required String message,
  required List<Widget> actions,
}) {
  return showDialog<T>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: actions,
    ),
  );
}
