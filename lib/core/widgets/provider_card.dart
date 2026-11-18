import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../theme/text_styles.dart';

/// Component D19: ProviderCard (Frontend Implementation Plan §D19).
/// Card for P17 AI key provider list.
/// Shows provider name, vision support capability, configuration/validation state,
/// and radio selection.
class ProviderCard extends StatelessWidget {
  final String providerId;
  final String providerName;
  final String modelName;
  final bool supportsVision;
  final bool isSelected;
  final bool isValidated;
  final String? validationDate;
  final String? errorMessage;
  final VoidCallback? onTap;

  const ProviderCard({
    super.key,
    required this.providerId,
    required this.providerName,
    required this.modelName,
    this.supportsVision = true,
    this.isSelected = false,
    this.isValidated = false,
    this.validationDate,
    this.errorMessage,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected
        ? AppTokens.neonPrimary
        : (errorMessage != null ? AppTokens.statusOut : AppTokens.borderSubtle);

    final semanticStatus = isValidated
        ? 'Validated ${validationDate ?? ''}'
        : (errorMessage != null ? 'Error: $errorMessage' : 'Not configured');

    return Semantics(
      selected: isSelected,
      label: '$providerName, model $modelName, ${supportsVision ? "Vision supported" : "No vision support"}, $semanticStatus',
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTokens.radiusCard),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(AppTokens.space16),
            decoration: BoxDecoration(
              color: AppTokens.bgSurface,
              borderRadius: BorderRadius.circular(AppTokens.radiusCard),
              border: Border.all(
                color: borderColor,
                width: isSelected ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Radio indicator
                Padding(
                  padding: const EdgeInsets.only(top: 2.0, right: AppTokens.space12),
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? AppTokens.neonPrimary : AppTokens.borderSubtle,
                        width: 2.0,
                      ),
                    ),
                    child: isSelected
                        ? Center(
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTokens.neonPrimary,
                              ),
                            ),
                          )
                        : null,
                  ),
                ),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              providerName,
                              style: AppTextStyles.headline.copyWith(
                                color: AppTokens.textPrimary,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Vision support pill
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: supportsVision
                                  ? AppTokens.statusAvailable.withValues(alpha: 0.15)
                                  : AppTokens.statusOut.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(AppTokens.radiusChip),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  supportsVision ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                  size: 12,
                                  color: supportsVision ? AppTokens.statusAvailable : AppTokens.statusOut,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  supportsVision ? 'Vision' : 'No vision',
                                  style: AppTextStyles.caption.copyWith(
                                    color: supportsVision ? AppTokens.statusAvailable : AppTokens.statusOut,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTokens.space4),
                      Text(
                        'Default: $modelName',
                        style: AppTextStyles.caption.copyWith(
                          color: AppTokens.textSecondary,
                        ),
                      ),
                      if (isValidated) ...[
                        const SizedBox(height: AppTokens.space8),
                        Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              size: 14,
                              color: AppTokens.statusAvailable,
                            ),
                            const SizedBox(width: AppTokens.space4),
                            Text(
                              validationDate != null
                                  ? 'Validated $validationDate'
                                  : 'Validated',
                              style: AppTextStyles.caption.copyWith(
                                color: AppTokens.statusAvailable,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ] else if (errorMessage != null) ...[
                        const SizedBox(height: AppTokens.space8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 14,
                              color: AppTokens.statusOut,
                            ),
                            const SizedBox(width: AppTokens.space4),
                            Expanded(
                              child: Text(
                                errorMessage!,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppTokens.statusOut,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
