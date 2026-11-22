import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_button.dart';
import '../../auth/providers/auth_provider.dart';

/// Screen P18: NotificationsScreen (/settings/notifications)
/// Manages deadline reminders, reminder timing choices (1, 3, 6, 12, 24 hours),
/// injury alerts, and Android notification permission banner.
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  bool _deadlineReminders = true;
  bool _injuryAlerts = true;
  int _selectedHours = 6;
  final bool _permissionDenied = false;

  final List<int> _timingOptions = const [1, 3, 6, 12, 24];

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final authRepo = ref.read(authRepositoryProvider);
      final data = await authRepo.getNotificationPreferences();
      if (mounted) {
        setState(() {
          _deadlineReminders = (data['deadline_reminders'] as bool?) ?? true;
          _injuryAlerts = (data['injury_alerts'] as bool?) ?? true;
          _selectedHours = (data['deadline_reminder_hours'] as int?) ?? 6;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _savePreferences() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.updateNotificationPreferences(
        deadlineReminders: _deadlineReminders,
        injuryAlerts: _injuryAlerts,
        deadlineReminderHours: _selectedHours,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification preferences saved.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save preferences. Changes will sync when online.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgSurface,
        elevation: 0,
        title: Text('Notifications', style: AppTextStyles.title.copyWith(color: colors.textPrimary)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: colors.accent))
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.screenGutter,
                  vertical: AppTokens.space12,
                ),
                children: [
                  // Permission Banner (if denied)
                  if (_permissionDenied) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: AppTokens.space16),
                      padding: const EdgeInsets.all(AppTokens.space12),
                      decoration: BoxDecoration(
                        color: colors.statusWarn.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                        border: Border.all(color: colors.statusWarn),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.notifications_off_outlined,
                                color: colors.statusWarn,
                                size: 20.0,
                              ),
                              const SizedBox(width: AppTokens.space8),
                              Expanded(
                                child: Text(
                                  'Notifications are blocked',
                                  style: AppTextStyles.label.copyWith(
                                    color: colors.statusWarn,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTokens.space4),
                          Text(
                            'Allow notifications in your phone\'s settings to get deadline reminders.',
                            style: AppTextStyles.caption.copyWith(color: colors.textSecondary),
                          ),
                          const SizedBox(height: AppTokens.space8),
                          AppButton(
                            label: 'Open Settings',
                            variant: AppButtonVariant.secondary,
                            size: AppButtonSize.medium,
                            onPressed: () {
                              // Deep-link to app notification settings
                            },
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Section: Deadline Reminders
                  Text(
                    'DEADLINE REMINDERS',
                    style: AppTextStyles.label.copyWith(
                      color: colors.textDisabled,
                      fontSize: 12.0,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppTokens.space8),
                  Material(
                    color: colors.bgSurface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                      side: BorderSide(color: colors.borderSubtle),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: Text('Remind me before deadline', style: AppTextStyles.body.copyWith(color: colors.textPrimary)),
                          subtitle: Text(
                            'Receive notifications before each gameweek deadline lock.',
                            style: AppTextStyles.caption.copyWith(color: colors.textSecondary),
                          ),
                          value: _deadlineReminders,
                          activeThumbColor: colors.accent,
                          onChanged: (val) {
                            setState(() => _deadlineReminders = val);
                            _savePreferences();
                          },
                        ),
                        if (_deadlineReminders) ...[
                          Divider(height: 1.0, color: colors.borderSubtle),
                          Padding(
                            padding: const EdgeInsets.all(AppTokens.space12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Reminder timing',
                                  style: AppTextStyles.label.copyWith(
                                    color: colors.textSecondary,
                                    fontSize: 11.5,
                                  ),
                                ),
                                const SizedBox(height: 8.0),
                                Wrap(
                                  spacing: 8.0,
                                  runSpacing: 8.0,
                                  children: _timingOptions.map((hours) {
                                    final isSelected = _selectedHours == hours;
                                    return ChoiceChip(
                                      label: Text('$hours ${hours == 1 ? "hour" : "hours"}'),
                                      selected: isSelected,
                                      selectedColor: colors.accentSoft,
                                      backgroundColor: colors.bgElevated,
                                      labelStyle: AppTextStyles.label.copyWith(
                                        color: isSelected ? colors.accent : colors.textSecondary,
                                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                      ),
                                      side: BorderSide(
                                        color: isSelected ? colors.accent : colors.borderSubtle,
                                      ),
                                      onSelected: (selected) {
                                        if (selected) {
                                          setState(() => _selectedHours = hours);
                                          _savePreferences();
                                        }
                                      },
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: AppTokens.space24),

                  // Section: Injury Alerts
                  Text(
                    'INJURY ALERTS',
                    style: AppTextStyles.label.copyWith(
                      color: colors.textDisabled,
                      fontSize: 12.0,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppTokens.space8),
                  Material(
                    color: colors.bgSurface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                      side: BorderSide(color: colors.borderSubtle),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: SwitchListTile(
                      title: Text('Squad injury & status alerts', style: AppTextStyles.body.copyWith(color: colors.textPrimary)),
                      subtitle: Text(
                        'Tell me when a player in my squad is injured, suspended, or doubtful.',
                        style: AppTextStyles.caption.copyWith(color: colors.textSecondary),
                      ),
                      value: _injuryAlerts,
                      activeThumbColor: colors.accent,
                      onChanged: (val) {
                        setState(() => _injuryAlerts = val);
                        _savePreferences();
                      },
                    ),
                  ),

                  if (_isSaving) ...[
                    const SizedBox(height: AppTokens.space16),
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 14.0,
                            height: 14.0,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.0,
                              color: colors.accent,
                            ),
                          ),
                          const SizedBox(width: AppTokens.space8),
                          Text(
                            'Saving preferences...',
                            style: AppTextStyles.caption.copyWith(color: colors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
