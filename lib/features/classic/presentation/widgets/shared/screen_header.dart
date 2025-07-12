import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ScreenHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String backRoute;
  final Widget? trailingWidget;

  const ScreenHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.backRoute,
    this.trailingWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).colorScheme.outline),
          ),
          child: IconButton(
            onPressed: () => context.go(backRoute),
            icon: Icon(
              Icons.arrow_back_rounded,
              size: 32,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            padding: const EdgeInsets.all(16),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontSize: 20,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
        if (trailingWidget != null) ...[
          const SizedBox(width: 24),
          trailingWidget!,
        ],
      ],
    );
  }
}
