import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/theme/text_styles.dart';

class HomeShellScreen extends StatelessWidget {
  const HomeShellScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.bgBase,
      appBar: AppBar(
        title: const Text('FPL Lens', style: AppTextStyles.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppTokens.textPrimary),
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppTokens.screenGutter),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.sports_soccer_outlined, size: 64.0, color: AppTokens.neonPrimary),
                const SizedBox(height: AppTokens.space24),
                const Text(
                  'Home Shell',
                  style: AppTextStyles.headline,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTokens.space8),
                Text(
                  'Welcome to FPL Lens! Full squad pitch and lineup views will be implemented in Sprints 8 & 10.',
                  style: AppTextStyles.body.copyWith(color: AppTokens.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
