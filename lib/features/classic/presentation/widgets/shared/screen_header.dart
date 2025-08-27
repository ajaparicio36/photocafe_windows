import 'package:flutter/material.dart';
import 'package:photocafe_windows/core/colors/colors.dart';
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
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEE),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IconButton(
            onPressed: () => context.go('/'),
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: Color(0xFF76220B),
              size: 28,
            ),
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
                  color: AppColors.lightCard,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontSize: 20,

                  color: AppColors.lightCard,
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
