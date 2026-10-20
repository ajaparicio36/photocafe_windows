import 'package:flutter/material.dart';

Future<bool> confirmDiscardSession(BuildContext context) async =>
    await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text(
          'Cancel and start over?',
          style: TextStyle(color: Color(0xff740000)),
        ),
        content: const Text(
          'Discard this session’s photos and unfinished motion or upload work?',
          style: TextStyle(color: Color(0xff740000)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xff740000),
            ),
            child: const Text('Keep session'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialog, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xff740000),
              foregroundColor: Colors.white,
            ),
            child: const Text('Cancel and start over'),
          ),
        ],
      ),
    ) ??
    false;
