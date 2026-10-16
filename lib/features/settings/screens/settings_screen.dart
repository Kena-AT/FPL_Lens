import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/confirm_sheet.dart';
import '../../../core/widgets/disclosure_notice.dart';
import '../../auth/providers/auth_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _shareAnalytics = true;

  String _maskEmail(String? email) {
    if (email == null || email.isEmpty) return 'None';
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final name = parts[0];
    final domain = parts[1];
    if (name.length <= 2) return '$name***@$domain';
    return '${name.substring(0, 2)}***@$domain';
  }

  Future<void> _handleSignOut() async {
    final confirmed = await ConfirmSheet.show(
      context,
      title: 'Sign out?',
      body: 'You will need to sign in again to access your squad.',
      confirmLabel: 'Sign out',
      cancelLabel: 'Cancel',
      isDestructive: false,
    );

    if (confirmed == true && mounted) {
      await ref.read(authNotifierProvider.notifier).logout();
      if (mounted) context.go('/auth');
    }
  }

  Future<void> _handleDeleteAccount() async {
    final confirmed = await ConfirmSheet.show(
      context,
      title: 'Delete your account?',
      body:
          'Your account and data will be removed after a 3-day grace period. You can sign in during that time to cancel. Your squad stays on this phone until you sign out.',
      confirmLabel: 'Delete account',
      cancelLabel: 'Keep account',
      isDestructive: true,
    );

    if (confirmed == true && mounted) {
      await ref.read(authNotifierProvider.notifier).deleteAccount();
      if (mounted) context.go('/auth');
    }
  }

  Widget _buildGroupHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppTokens.space4,
        top: AppTokens.space24,
        bottom: AppTokens.space8,
      ),
      child: Text(
        title.toUpperCase(),
        style: AppTextStyles.label.copyWith(
          color: AppTokens.textDisabled,
          letterSpacing: 1.2,
          fontSize: 12.0,
        ),
      ),
    );
  }

  Widget _buildTile({
    required String title,
    required String value,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTokens.space4),
      decoration: BoxDecoration(
        color: AppTokens.bgSurface,
        borderRadius: BorderRadius.circular(AppTokens.radiusInput),
        border: Border.all(color: AppTokens.borderSubtle, width: 1.0),
      ),
      child: ListTile(
        title: Text(title, style: AppTextStyles.body.copyWith(fontSize: 14.0)),
        subtitle: Text(value, style: AppTextStyles.caption.copyWith(color: AppTokens.textSecondary)),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: AppTokens.bgBase,
      appBar: AppBar(
        title: const Text('Settings', style: AppTextStyles.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTokens.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: AppTokens.screenGutter, vertical: AppTokens.space8),
          children: [
            // 1. Account Group
            _buildGroupHeader('Account'),
            _buildTile(
              title: 'Display name',
              value: user?.displayName ?? 'Manager',
            ),
            _buildTile(
              title: 'Email',
              value: _maskEmail(user?.email),
            ),
            _buildTile(
              title: 'FPL team ID',
              value: user?.fplTeamId != null ? user!.fplTeamId.toString() : 'Not linked',
            ),
            _buildTile(
              title: 'Sign-in method',
              value: user?.provider == 'google' ? 'Google' : 'Email',
            ),

            // 2. Preferences Group
            _buildGroupHeader('Preferences'),
            _buildTile(
              title: 'Notifications',
              value: 'Deadline reminders and injury alerts',
              trailing: const Icon(Icons.chevron_right, color: AppTokens.textDisabled),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Notifications settings opened.')),
                );
              },
            ),
            _buildTile(
              title: 'AI key for screenshots',
              value: 'Not added',
              trailing: const Icon(Icons.chevron_right, color: AppTokens.textDisabled),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('AI key configuration opened.')),
                );
              },
            ),
            Container(
              margin: const EdgeInsets.only(bottom: AppTokens.space4),
              decoration: BoxDecoration(
                color: AppTokens.bgSurface,
                borderRadius: BorderRadius.circular(AppTokens.radiusInput),
                border: Border.all(color: AppTokens.borderSubtle, width: 1.0),
              ),
              child: SwitchListTile(
                title: Text(
                  'Share anonymous usage data',
                  style: AppTextStyles.body.copyWith(fontSize: 14.0),
                ),
                subtitle: Text(
                  'Helps improve projection accuracy. No squad or personal data is collected.',
                  style: AppTextStyles.caption.copyWith(color: AppTokens.textSecondary),
                ),
                value: _shareAnalytics,
                activeThumbColor: AppTokens.goldPrimary,
                onChanged: (val) => setState(() => _shareAnalytics = val),
              ),
            ),

            // 3. Privacy and Data Group
            _buildGroupHeader('Privacy and Data'),
            _buildTile(
              title: 'What data we store',
              value: 'Account email, FPL team ID, public reference data, and cache.',
            ),
            Container(
              padding: const EdgeInsets.all(AppTokens.space12),
              decoration: BoxDecoration(
                color: AppTokens.bgSurface,
                borderRadius: BorderRadius.circular(AppTokens.radiusInput),
                border: Border.all(color: AppTokens.borderSubtle, width: 1.0),
              ),
              child: Text(
                'Squad and history data comes from Fantasy Premier League and is provided through FPL Lens servers.',
                style: AppTextStyles.caption.copyWith(color: AppTokens.textSecondary),
              ),
            ),

            // 4. About Group
            _buildGroupHeader('About'),
            _buildTile(
              title: 'Version',
              value: '0.1.0 (Build 1)',
            ),
            const SizedBox(height: AppTokens.space8),
            const DisclosureNotice(),

            // 5. Danger Zone
            _buildGroupHeader('Account Actions'),
            AppButton(
              label: 'Sign out',
              variant: AppButtonVariant.secondary,
              onPressed: _handleSignOut,
            ),
            const SizedBox(height: AppTokens.space12),
            AppButton(
              label: 'Delete account',
              variant: AppButtonVariant.destructive,
              onPressed: _handleDeleteAccount,
            ),
            const SizedBox(height: AppTokens.space32),
          ],
        ),
      ),
    );
  }
}
