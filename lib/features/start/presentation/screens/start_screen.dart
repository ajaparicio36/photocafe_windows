import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/colors/colors.dart';

class AppStartScreen extends ConsumerWidget {
  const AppStartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Container(
        color: AppColors.lightBackground,
        child: SafeArea(
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo Section
                    Expanded(
                      flex: 2,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/icons/clickclick_logo.png',
                            height: 200,
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),

                    Image.asset(
                      'assets/icons/choose_experience_button.png',
                      height: 90,
                    ),

                    // Mode Selection Buttons
                    Expanded(
                      flex: 3,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Classic Mode Button
                          Container(
                            width: double.infinity,
                            height: 120,
                            margin: const EdgeInsets.symmetric(vertical: 16),
                            color: AppColors.lightPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: GestureDetector(
                              onTap: () => context.go('/classic/start'),
                              child: Image.asset(
                                'assets/icons/classic_button.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),

                          // Flipbook Mode Button
                          Container(
                            width: double.infinity,
                            height: 120,
                            margin: const EdgeInsets.symmetric(vertical: 16),
                            color: AppColors.lightPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: GestureDetector(
                              onTap: () => context.go('/flipbook/start'),
                              child: Image.asset(
                                'assets/icons/flipbook_button.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 16,
                left: 16,
                child: IconButton(
                  onPressed: () => context.go('/settings'),
                  icon: Icon(
                    Icons.settings_rounded,
                    size: 32,
                    color: AppColors.lightPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
