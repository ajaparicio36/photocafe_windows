import 'package:flutter/material.dart';

class ScreenContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;

  const ScreenContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(40),
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.background,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(padding: padding!, child: child),
        ),
      ),
    );
  }
}
