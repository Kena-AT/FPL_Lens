import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/confirm_sheet.dart';
import '../../../core/widgets/disclosure_notice.dart';
import '../../../core/widgets/provider_card.dart';
import '../../ai_providers/providers/ai_key_provider.dart';
import '../../ai_providers/services/ai_provider_registry.dart';

/// Screen P17: AI key setup (/settings/ai)
/// Allows user to configure, validate, replace, or remove an AI provider key
/// for screenshot squad reading.
class AiKeySetupScreen extends ConsumerStatefulWidget {
  final String? next;

  const AiKeySetupScreen({super.key, this.next});

  @override
  ConsumerState<AiKeySetupScreen> createState() => _AiKeySetupScreenState();
}

class _AiKeySetupScreenState extends ConsumerState<AiKeySetupScreen> {
  late String _selectedProviderId;
  final TextEditingController _keyController = TextEditingController();
  bool _understandChecked = false;
  bool _isEditingKey = false;

  static const String _disclosureText =
      'FPL Lens sends your screenshot and the extraction prompt directly from your phone to the provider you choose. '
      'We do not receive, store or see your key, your screenshot or the provider\'s response. '
      'The provider\'s terms govern how it handles your data. '
      'The quality of what the model returns is the responsibility of the provider and the model, not FPL Lens. '
      'We check only that the extracted names match players in the FPL database.';

  @override
  void initState() {
    super.initState();
    final current = ref.read(aiKeyProvider);
    _selectedProviderId = current.providerId ?? 'google_gemini';
  }

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  void _onKeyChanged(String value) {
    final trimmed = value.trim();
    String? detectedProvider;
    if (trimmed.startsWith('AIzaSy')) {
      detectedProvider = 'google_gemini';
    } else if (trimmed.startsWith('sk-ant-')) {
      detectedProvider = 'anthropic_claude';
    } else if (trimmed.startsWith('sk-or-')) {
      detectedProvider = 'openrouter';
    } else if (trimmed.startsWith('xai-')) {
      detectedProvider = 'xai_grok';
    } else if (trimmed.startsWith('nvapi-')) {
      detectedProvider = 'nvidia_nim';
    } else if (trimmed.startsWith('sk-')) {
      detectedProvider = 'openai';
    }

    if (detectedProvider != null && detectedProvider != _selectedProviderId) {
      setState(() {
        _selectedProviderId = detectedProvider!;
        ref.read(aiKeyProvider.notifier).clearMessages();
      });
    } else {
      setState(() {});
    }
  }

  Future<void> _handleValidateAndSave() async {
    final key = _keyController.text.trim();
    if (key.isEmpty) return;

    final success = await ref.read(aiKeyProvider.notifier).validateAndSave(
          providerId: _selectedProviderId,
          rawKey: key,
        );

    if (success && mounted) {
      _keyController.clear();
      setState(() {
        _isEditingKey = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Key saved. Stored only on this phone.'),
          backgroundColor: AppTokens.statusAvailable,
        ),
      );

      if (widget.next != null && widget.next!.isNotEmpty) {
        context.go(widget.next!);
      }
    }
  }

  Future<void> _handleRemoveKey() async {
    final confirmed = await ConfirmSheet.show(
      context,
      title: 'Remove AI key?',
      body:
          'Removing your key will delete it from this device. You will need to enter a key again to scan screenshots.',
      confirmLabel: 'Remove key',
      cancelLabel: 'Cancel',
      isDestructive: true,
    );

    if (confirmed == true && mounted) {
      await ref.read(aiKeyProvider.notifier).removeKey();
      setState(() {
        _isEditingKey = true;
        _keyController.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Key removed.'),
            backgroundColor: AppTokens.textSecondary,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final aiState = ref.watch(aiKeyProvider);
    final hasStoredKey = aiState.isConfigured && !_isEditingKey;

    final canSave = _understandChecked &&
        !aiState.isValidating &&
        (_keyController.text.trim().isNotEmpty);

    return Scaffold(
      backgroundColor: AppTokens.bgBase,
      appBar: AppBar(
        backgroundColor: AppTokens.bgBase,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTokens.textPrimary),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/settings');
            }
          },
        ),
        title: Text(
          'AI key for screenshots',
          style: AppTextStyles.title.copyWith(fontSize: 22.0),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.screenGutter,
            vertical: AppTokens.space12,
          ),
          children: [
            // 1. Explanation Card
            Container(
              padding: const EdgeInsets.all(AppTokens.space16),
              decoration: BoxDecoration(
                color: AppTokens.bgSurface,
                borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                border: Border.all(color: AppTokens.borderSubtle),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: AppTokens.neonPrimary,
                    size: 20,
                  ),
                  const SizedBox(width: AppTokens.space12),
                  Expanded(
                    child: Text(
                      'Screenshots are read by an AI model you choose. You provide the key, and it stays on this phone.',
                      style: AppTextStyles.body.copyWith(
                        color: AppTokens.textSecondary,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTokens.space24),

            // 2. Provider selection list
            Text(
              'CHOOSE PROVIDER',
              style: AppTextStyles.label.copyWith(
                color: AppTokens.textDisabled,
                letterSpacing: 1.2,
                fontSize: 12.0,
              ),
            ),
            const SizedBox(height: AppTokens.space8),
            ...AiProviderRegistry.adapters.map((adapter) {
              final isSelected = adapter.providerId == _selectedProviderId;
              final isCurrentStored =
                  aiState.isConfigured && aiState.providerId == adapter.providerId;

              String? valDateStr;
              if (isCurrentStored && aiState.validatedAt != null) {
                final d = aiState.validatedAt!;
                valDateStr = '${d.day}/${d.month}/${d.year}';
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: AppTokens.space8),
                child: ProviderCard(
                  providerId: adapter.providerId,
                  providerName: adapter.displayName,
                  modelName: adapter.defaultModel,
                  supportsVision: adapter.supportsVision(),
                  isSelected: isSelected,
                  isValidated: isCurrentStored,
                  validationDate: valDateStr,
                  errorMessage: isSelected ? aiState.errorMessage : null,
                  onTap: () {
                    setState(() {
                      _selectedProviderId = adapter.providerId;
                      ref.read(aiKeyProvider.notifier).clearMessages();
                    });
                  },
                ),
              );
            }),
            const SizedBox(height: AppTokens.space16),

            // 3. Key Field or Masked Display
            Text(
              'API KEY',
              style: AppTextStyles.label.copyWith(
                color: AppTokens.textDisabled,
                letterSpacing: 1.2,
                fontSize: 12.0,
              ),
            ),
            const SizedBox(height: AppTokens.space8),
            if (hasStoredKey) ...[
              Container(
                padding: const EdgeInsets.all(AppTokens.space16),
                decoration: BoxDecoration(
                  color: AppTokens.bgSurface,
                  borderRadius: BorderRadius.circular(AppTokens.radiusInput),
                  border: Border.all(color: AppTokens.borderSubtle),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Stored API Key',
                          style: AppTextStyles.caption.copyWith(
                            color: AppTokens.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          aiState.maskedKey ?? '••••••••••••',
                          style: AppTextStyles.body.copyWith(
                            letterSpacing: 2.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isEditingKey = true;
                          _understandChecked = false;
                        });
                      },
                      child: Text(
                        'Replace key',
                        style: AppTextStyles.label.copyWith(
                          color: AppTokens.neonPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              AppTextField(
                label: 'API key, hidden',
                hint: 'Enter your API key',
                controller: _keyController,
                type: AppTextFieldType.password,
                error: aiState.errorMessage,
                onChanged: _onKeyChanged,
              ),
            ],
            const SizedBox(height: AppTokens.space24),

            // 4. Disclosure notice & Mandatory "I understand" checkbox
            if (!hasStoredKey) ...[
              const DisclosureNotice(
                text: _disclosureText,
              ),
              const SizedBox(height: AppTokens.space4),
              Padding(
                padding: const EdgeInsets.only(left: 4.0),
                child: Text(
                  'Draft wording',
                  style: AppTextStyles.caption.copyWith(
                    color: AppTokens.textDisabled,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const SizedBox(height: AppTokens.space12),
              InkWell(
                onTap: () {
                  setState(() {
                    _understandChecked = !_understandChecked;
                  });
                },
                borderRadius: BorderRadius.circular(AppTokens.radiusChip),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                  child: Row(
                    children: [
                      Checkbox(
                        value: _understandChecked,
                        onChanged: (val) {
                          setState(() {
                            _understandChecked = val ?? false;
                          });
                        },
                        activeColor: AppTokens.goldPrimary,
                        checkColor: AppTokens.bgBase,
                      ),
                      const SizedBox(width: AppTokens.space8),
                      Expanded(
                        child: Text(
                          'I understand',
                          style: AppTextStyles.body.copyWith(
                            color: AppTokens.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppTokens.space24),

              // 5. Save Button
              AppButton(
                label: 'Validate and save',
                onPressed: canSave ? _handleValidateAndSave : null,
                isLoading: aiState.isValidating,
                width: double.infinity,
              ),
              const SizedBox(height: AppTokens.space16),
            ],

            // 6. Remove key destructive button if key is configured
            if (aiState.isConfigured) ...[
              AppButton(
                label: 'Remove key',
                variant: AppButtonVariant.destructive,
                onPressed: _handleRemoveKey,
                width: double.infinity,
              ),
              const SizedBox(height: AppTokens.space24),
            ],
          ],
        ),
      ),
    );
  }
}
