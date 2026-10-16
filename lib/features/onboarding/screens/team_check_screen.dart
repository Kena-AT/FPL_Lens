import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/app_button.dart';

class TeamCheckScreen extends StatelessWidget {
  const TeamCheckScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.bgBase,
      appBar: AppBar(
        title: const Text('Your team', style: AppTextStyles.title),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.screenGutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.shield_outlined, size: 64.0, color: AppTokens.goldPrimary),
              const SizedBox(height: AppTokens.space24),
              const Text(
                'FPL Team Check',
                style: AppTextStyles.headline,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTokens.space8),
              Text(
                'Your account is verified. Team ID confirmation and squad load will continue in Sprint 8.',
                style: AppTextStyles.body.copyWith(color: AppTokens.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTokens.space32),
              AppButton(
                label: 'Go to Home Shell',
                onPressed: () => context.go('/home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
