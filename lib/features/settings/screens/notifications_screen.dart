import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
  bool _permissionDenied = false;

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
    return Scaffold(
      backgroundColor: AppTokens.bgBase,
      appBar: AppBar(
        title: const Text('Notifications', style: AppTextStyles.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTokens.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTokens.neonPrimary))
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
                        color: AppTokens.statusDoubtful.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                        border: Border.all(color: AppTokens.statusDoubtful),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.notifications_off_outlined, color: AppTokens.statusDoubtful, size: 20),
                              const SizedBox(width: AppTokens.space8),
                              Expanded(
                                child: Text(
                                  'Notifications are off in Android settings.',
                                  style: AppTextStyles.label.copyWith(color: AppTokens.statusDoubtful),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8.0),
                          const Text(
                            'Turn them on in Android settings to get deadline reminders and injury alerts.',
                            style: AppTextStyles.caption,
                          ),
                          const SizedBox(height: 8.0),
                          Align(
                            alignment: Alignment.centerRight,
                            child: AppButton(
                              label: 'Open settings',
                              variant: AppButtonVariant.tertiary,
                              onPressed: () {
                                // Request rationale trigger
                                setState(() {
                                  _permissionDenied = false;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Section: Deadline Reminders
                  Text(
                    'DEADLINE REMINDERS',
                    style: AppTextStyles.label.copyWith(
                      color: AppTokens.textDisabled,
                      fontSize: 12.0,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: AppTokens.space8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppTokens.bgSurface,
                      borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                      border: Border.all(color: AppTokens.borderSubtle),
                    ),
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text('Remind me before deadline', style: AppTextStyles.body),
                          subtitle: Text(
                            'Receive notifications before each gameweek deadline lock.',
                            style: AppTextStyles.caption.copyWith(color: AppTokens.textSecondary),
                          ),
                          value: _deadlineReminders,
                          activeThumbColor: AppTokens.goldPrimary,
                          onChanged: (val) {
                            setState(() => _deadlineReminders = val);
                            _savePreferences();
                          },
                        ),
                        if (_deadlineReminders) ...[
                          const Divider(height: 1.0, color: AppTokens.borderSubtle),
                          Padding(
                            padding: const EdgeInsets.all(AppTokens.space12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Reminder timing',
                                  style: AppTextStyles.label.copyWith(
                                    color: AppTokens.textSecondary,
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
                                      selectedColor: AppTokens.neonPrimary.withValues(alpha: 0.25),
                                      backgroundColor: AppTokens.bgElevated,
                                      labelStyle: AppTextStyles.label.copyWith(
                                        color: isSelected ? AppTokens.neonPrimary : AppTokens.textSecondary,
                                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                      ),
                                      side: BorderSide(
                                        color: isSelected ? AppTokens.neonPrimary : AppTokens.borderSubtle,
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
                      color: AppTokens.textDisabled,
                      fontSize: 12.0,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: AppTokens.space8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppTokens.bgSurface,
                      borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                      border: Border.all(color: AppTokens.borderSubtle),
                    ),
                    child: SwitchListTile(
                      title: const Text('Squad injury & status alerts', style: AppTextStyles.body),
                      subtitle: Text(
                        'Tell me when a player in my squad is injured, suspended, or doubtful. Alerts use official FPL status [DECIDED pending A7].',
                        style: AppTextStyles.caption.copyWith(color: AppTokens.textSecondary),
                      ),
                      value: _injuryAlerts,
                      activeThumbColor: AppTokens.goldPrimary,
                      onChanged: (val) {
                        setState(() => _injuryAlerts = val);
                        _savePreferences();
                      },
                    ),
                  ),

                  if (_isSaving) ...[
                    const SizedBox(height: AppTokens.space16),
                    const Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 14.0,
                            height: 14.0,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.0,
                              color: AppTokens.neonPrimary,
                            ),
                          ),
                          SizedBox(width: 8.0),
                          Text('Saving preferences...', style: AppTextStyles.caption),
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
