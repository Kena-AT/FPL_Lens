import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/confirm_sheet.dart';
import '../../../core/widgets/disclosure_notice.dart';
import '../../ai_providers/providers/ai_key_provider.dart';
import '../../auth/providers/auth_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _shareAnalytics = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final analyticsService = ref.read(analyticsServiceProvider);
      setState(() {
        _shareAnalytics = analyticsService.isEnabled;
      });
    });
  }

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

  void _showAboutDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTokens.bgSurface,
        title: const Text('About FPL Lens', style: AppTextStyles.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Version: 0.1.0\nBuild: 1\nCommit: 3827681',
                style: AppTextStyles.body.copyWith(color: AppTokens.textSecondary),
              ),
              const SizedBox(height: AppTokens.space16),
              Text(
                'Data Attribution:',
                style: AppTextStyles.label.copyWith(color: AppTokens.goldPrimary),
              ),
              const SizedBox(height: AppTokens.space4),
              Text(
                'Data sourced from public Fantasy Premier League endpoints.',
                style: AppTextStyles.body.copyWith(fontSize: 13.0),
              ),
              const SizedBox(height: AppTokens.space16),
              Text(
                'Disclaimer:',
                style: AppTextStyles.label.copyWith(color: AppTokens.goldPrimary),
              ),
              const SizedBox(height: AppTokens.space4),
              Text(
                'FPL Lens is an independent analytics tool. It is not affiliated with, endorsed by, or sponsored by the Football Association Premier League Limited or Fantasy Premier League.',
                style: AppTextStyles.caption.copyWith(color: AppTokens.textSecondary),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              showLicensePage(
                context: context,
                applicationName: 'FPL Lens',
                applicationVersion: '0.1.0 (Build 1)',
              );
            },
            child: const Text('Licences', style: TextStyle(color: AppTokens.goldPrimary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close', style: TextStyle(color: AppTokens.textPrimary)),
          ),
        ],
      ),
    );
  }

  void _showPrivacyNoteDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTokens.bgSurface,
        title: const Text('Privacy & Security Note', style: AppTextStyles.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Client-Side AI Key Storage:',
                style: AppTextStyles.label.copyWith(color: AppTokens.goldPrimary),
              ),
              const SizedBox(height: AppTokens.space4),
              Text(
                'Your AI vision keys (Gemini, Claude, OpenAI) are encrypted and stored exclusively on your device using Android KeyStore. They are never sent to or stored on FPL Lens servers.',
                style: AppTextStyles.body.copyWith(fontSize: 13.0),
              ),
              const SizedBox(height: AppTokens.space12),
              Text(
                'Zero Screenshot Upload:',
                style: AppTextStyles.label.copyWith(color: AppTokens.goldPrimary),
              ),
              const SizedBox(height: AppTokens.space4),
              Text(
                'Squad screenshots are processed directly on your device and sent solely to your chosen AI provider using your own key. Screenshots are never transmitted to or stored on FPL Lens servers.',
                style: AppTextStyles.body.copyWith(fontSize: 13.0),
              ),
              const SizedBox(height: AppTokens.space12),
              Text(
                'Server Caching & Public Data:',
                style: AppTextStyles.label.copyWith(color: AppTokens.goldPrimary),
              ),
              const SizedBox(height: AppTokens.space4),
              Text(
                'Public Premier League reference data and mathematical projection bundles are cached on our servers to ensure deterministic projections.',
                style: AppTextStyles.body.copyWith(fontSize: 13.0),
              ),
              const SizedBox(height: AppTokens.space12),
              Text(
                'Notification Tokens:',
                style: AppTextStyles.label.copyWith(color: AppTokens.goldPrimary),
              ),
              const SizedBox(height: AppTokens.space4),
              Text(
                'Push tokens (FCM) are used solely to deliver deadline reminders and injury status alerts according to your preferences.',
                style: AppTextStyles.body.copyWith(fontSize: 13.0),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Got it', style: TextStyle(color: AppTokens.goldPrimary)),
          ),
        ],
      ),
    );
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTokens.radiusInput),
        child: ListTile(
          title: Text(title, style: AppTextStyles.body.copyWith(fontSize: 14.0)),
          subtitle: Text(value, style: AppTextStyles.caption.copyWith(color: AppTokens.textSecondary)),
          trailing: trailing,
          onTap: onTap,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final aiState = ref.watch(aiKeyProvider);
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

            // 2. Appearance Group (§3.1, §8.17)
            _buildGroupHeader('Appearance'),
            Container(
              margin: const EdgeInsets.only(bottom: AppTokens.space8),
              padding: const EdgeInsets.all(AppTokens.space12),
              decoration: BoxDecoration(
                color: AppTokens.bgSurface,
                borderRadius: BorderRadius.circular(AppTokens.radiusInput),
                border: Border.all(color: AppTokens.borderSubtle, width: 1.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Theme mode', style: AppTextStyles.body.copyWith(fontSize: 14.0)),
                  const SizedBox(height: AppTokens.space8),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment(
                          value: ThemeMode.dark,
                          label: Text('Dark'),
                          icon: Icon(Icons.dark_mode_outlined, size: 16),
                        ),
                        ButtonSegment(
                          value: ThemeMode.light,
                          label: Text('Light'),
                          icon: Icon(Icons.light_mode_outlined, size: 16),
                        ),
                        ButtonSegment(
                          value: ThemeMode.system,
                          label: Text('System'),
                          icon: Icon(Icons.brightness_auto_outlined, size: 16),
                        ),
                      ],
                      selected: {ref.watch(themeModeProvider)},
                      onSelectionChanged: (modes) {
                        ref.read(themeModeProvider.notifier).setThemeMode(modes.first);
                      },
                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.only(bottom: AppTokens.space4),
              decoration: BoxDecoration(
                color: AppTokens.bgSurface,
                borderRadius: BorderRadius.circular(AppTokens.radiusInput),
                border: Border.all(color: AppTokens.borderSubtle, width: 1.0),
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(AppTokens.radiusInput),
                child: SwitchListTile(
                  title: Text(
                    'Reduce motion',
                    style: AppTextStyles.body.copyWith(fontSize: 14.0),
                  ),
                  subtitle: Text(
                    'Turns off reveals and counting animations.',
                    style: AppTextStyles.caption.copyWith(color: AppTokens.textSecondary),
                  ),
                  value: ref.watch(motionPolicyProvider),
                  activeThumbColor: AppTokens.accent,
                  onChanged: (val) {
                    ref.read(motionPolicyProvider.notifier).setReduceMotion(val);
                  },
                ),
              ),
            ),

            // 3. Preferences Group
            _buildGroupHeader('Preferences'),
            _buildTile(
              title: 'Notifications',
              value: 'Deadline reminders and injury alerts',
              trailing: const Icon(Icons.chevron_right, color: AppTokens.textDisabled),
              onTap: () => context.push('/settings/notifications'),
            ),
            _buildTile(
              title: 'AI key for screenshots',
              value: aiState.isConfigured ? 'Added' : 'Not added',
              trailing: const Icon(Icons.chevron_right, color: AppTokens.textDisabled),
              onTap: () => context.push('/settings/ai'),
            ),
            Container(
              margin: const EdgeInsets.only(bottom: AppTokens.space4),
              decoration: BoxDecoration(
                color: AppTokens.bgSurface,
                borderRadius: BorderRadius.circular(AppTokens.radiusInput),
                border: Border.all(color: AppTokens.borderSubtle, width: 1.0),
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(AppTokens.radiusInput),
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
                  onChanged: (val) async {
                    setState(() => _shareAnalytics = val);
                    await ref.read(analyticsServiceProvider).setEnabled(val);
                  },
                ),
              ),
            ),

            // 3. Privacy and Data Group
            _buildGroupHeader('Privacy and Data'),
            _buildTile(
              title: 'Privacy note',
              value: 'Local key storage, zero screenshot upload, server caching',
              trailing: const Icon(Icons.chevron_right, color: AppTokens.textDisabled),
              onTap: () => _showPrivacyNoteDialog(context),
            ),
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
              title: 'About FPL Lens',
              value: 'Version 0.1.0, data attribution, and disclaimer',
              trailing: const Icon(Icons.chevron_right, color: AppTokens.textDisabled),
              onTap: () => _showAboutDialog(context),
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
