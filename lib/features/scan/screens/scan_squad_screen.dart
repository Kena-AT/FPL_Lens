import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/storage/app_database.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/confirm_sheet.dart';
import '../../../data/models/squad_resolve_models.dart';
import '../../../data/repositories/squad_scan_repository.dart';
import '../../ai_providers/providers/ai_key_provider.dart';
import '../../ai_providers/services/ai_provider_registry.dart';
import '../../auth/providers/auth_provider.dart';
import '../../squad/providers/squad_provider.dart';

enum ScanStep {
  capture,
  preview,
  checkingImage,
  readingSquad,
  matchingPlayers,
  error,
}

/// Screen P15: Scan Squad (/scan)
/// Allows user to photograph or pick an FPL team screenshot,
/// extracts names via on-device AI provider, and resolves them on the backend.
/// The image is NEVER uploaded to the FPL Lens server.
class ScanSquadScreen extends ConsumerStatefulWidget {
  const ScanSquadScreen({super.key});

  @override
  ConsumerState<ScanSquadScreen> createState() => _ScanSquadScreenState();
}

class _ScanSquadScreenState extends ConsumerState<ScanSquadScreen> {
  final ImagePicker _picker = ImagePicker();
  Uint8List? _imageBytes;
  String? _mimeType;

  ScanStep _currentStep = ScanStep.capture;
  String? _errorMessage;
  String? _errorAction; // 'retry', 'change_key', 'pick_another'
  bool _showTips = true;
  bool _isCancelled = false;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 85,
      );
      if (file == null) return;

      final bytes = await file.readAsBytes();
      final pathLower = file.path.toLowerCase();

      // Format check (JPEG or PNG)
      String detectedMime = 'image/jpeg';
      if (pathLower.endsWith('.png')) {
        detectedMime = 'image/png';
      } else if (!pathLower.endsWith('.jpg') && !pathLower.endsWith('.jpeg')) {
        setState(() {
          _errorMessage = "That file type isn't supported. Use a JPEG or PNG.";
          _currentStep = ScanStep.error;
          _errorAction = 'pick_another';
        });
        return;
      }

      // Size check (max 8MB)
      if (bytes.lengthInBytes > 8 * 1024 * 1024) {
        setState(() {
          _errorMessage = 'That image is too large. Try a smaller capture.';
          _currentStep = ScanStep.error;
          _errorAction = 'pick_another';
        });
        return;
      }

      setState(() {
        _imageBytes = bytes;
        _mimeType = detectedMime;
        _currentStep = ScanStep.preview;
        _errorMessage = null;
      });
    } catch (_) {
      setState(() {
        _errorMessage = 'Could not access image. Please check app permissions.';
        _currentStep = ScanStep.error;
        _errorAction = 'pick_another';
      });
    }
  }

  Future<void> _startExtraction() async {
    if (_imageBytes == null || _mimeType == null) return;
    _isCancelled = false;

    final secureStore = ref.read(secureStoreProvider);
    final providerId = await secureStore.getAiProvider();
    final apiKey = await secureStore.getAiKey();

    if (providerId == null || apiKey == null || apiKey.isEmpty) {
      if (!mounted) return;
      context.go('/settings/ai?next=/scan');
      return;
    }

    final adapter = AiProviderRegistry.getAdapter(providerId);
    if (adapter == null) {
      setState(() {
        _errorMessage = 'Configured AI provider is not supported.';
        _currentStep = ScanStep.error;
        _errorAction = 'change_key';
      });
      return;
    }

    // Step 1: Checking image
    setState(() {
      _currentStep = ScanStep.checkingImage;
      _errorMessage = null;
    });
    await Future.delayed(const Duration(milliseconds: 300));
    if (_isCancelled) return;

    // Step 2: Reading squad with AI Provider
    setState(() {
      _currentStep = ScanStep.readingSquad;
    });

    final dio = Dio();
    List<dynamic> extracted = [];

    try {
      // First attempt
      extracted = await adapter.extract(
        imageBytes: _imageBytes!,
        mimeType: _mimeType!,
        key: apiKey,
        dio: dio,
        strict: false,
      );

      // Single retry with stricter prompt if first attempt was empty
      if (extracted.isEmpty && !_isCancelled) {
        extracted = await adapter.extract(
          imageBytes: _imageBytes!,
          mimeType: _mimeType!,
          key: apiKey,
          dio: dio,
          strict: true,
        );
      }
    } on DioException catch (e) {
      if (_isCancelled) return;
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        setState(() {
          _errorMessage = 'The provider took too long. Try again.';
          _currentStep = ScanStep.error;
          _errorAction = 'retry';
        });
        return;
      }
      final code = e.response?.statusCode;
      if (code == 401 || code == 403) {
        setState(() {
          _errorMessage =
              'That key was rejected by the provider. Check it and try again.';
          _currentStep = ScanStep.error;
          _errorAction = 'change_key';
        });
        return;
      } else if (code == 429) {
        setState(() {
          _errorMessage =
              'Your ${adapter.displayName} key has reached its limit. Try another provider or try later.';
          _currentStep = ScanStep.error;
          _errorAction = 'change_key';
        });
        return;
      }
    } catch (_) {
      // General error
    }

    if (_isCancelled) return;

    if (extracted.isEmpty) {
      setState(() {
        _errorMessage =
            "That screenshot couldn't be read. Try a clear, full-screen capture.";
        _currentStep = ScanStep.error;
        _errorAction = 'retry';
      });
      return;
    }

    // Step 3: Matching players on FPL Lens server (names only, NEVER image)
    setState(() {
      _currentStep = ScanStep.matchingPlayers;
    });

    try {
      final scanRepo = ref.read(squadScanRepositoryProvider);
      final resolveResponse = await scanRepo.resolveSquad(
        extracted.cast(),
      );

      if (_isCancelled) return;

      if (resolveResponse.allResolved) {
        // Save to Drift squad with CONFIRM prices
        await _saveResolvedSquad(resolveResponse.results);
        if (mounted) {
          context.go('/squad/prices');
        }
      } else {
        // Navigate to Resolve Players (P16) with response payload
        if (mounted) {
          context.push('/scan/resolve', extra: resolveResponse);
        }
      }
    } catch (e) {
      if (_isCancelled) return;
      setState(() {
        _errorMessage =
            'Could not match squad players on the server. Please try again.';
        _currentStep = ScanStep.error;
        _errorAction = 'retry';
      });
    }
  }

  Future<void> _saveResolvedSquad(List<ResolvedPlayerResult> results) async {
    final companions = <SquadPlayersTableCompanion>[];

    for (int i = 0; i < results.length; i++) {
      final res = results[i];
      final candidate = res.candidates.isNotEmpty ? res.candidates[0] : null;

      final fplId = res.bestMatchFplId ?? candidate?.fplId ?? (9000 + i);
      final webName = candidate?.webName ?? res.rawName;
      final position = candidate?.position ?? (res.slot ?? 'MID');
      final teamShortName = candidate?.teamShortName ?? 'PL';
      final nowCost = candidate?.nowCostTenths ?? 60;

      companions.add(
        SquadPlayersTableCompanion(
          fplId: drift.Value(fplId),
          webName: drift.Value(webName),
          position: drift.Value(position),
          teamId: drift.Value(candidate?.teamFplId ?? 1),
          teamShortName: drift.Value(teamShortName),
          purchasePriceTenths: drift.Value(nowCost),
          sellingPriceTenths: drift.Value(nowCost),
          nowCostTenths: drift.Value(nowCost),
          status: const drift.Value('a'),
          chanceOfPlayingNextRound: const drift.Value(100),
          isCaptain: drift.Value(i == 0),
          isViceCaptain: drift.Value(i == 1),
          multiplier: drift.Value(i == 0 ? 2 : 1),
          positionOrder: drift.Value(i + 1),
          priceSource: const drift.Value('CONFIRM'),
          updatedAt: drift.Value(DateTime.now()),
        ),
      );
    }

    await ref.read(squadNotifierProvider.notifier).saveScanResolvedSquad(companions);
  }

  Future<void> _handleClose() async {
    final isExtracting = _currentStep == ScanStep.checkingImage ||
        _currentStep == ScanStep.readingSquad ||
        _currentStep == ScanStep.matchingPlayers;

    if (isExtracting) {
      final confirmed = await ConfirmSheet.show(
        context,
        title: 'Cancel scan?',
        body: 'Squad extraction is currently in progress. Do you want to stop?',
        confirmLabel: 'Stop scan',
        cancelLabel: 'Keep scanning',
        isDestructive: true,
      );
      if (confirmed == true) {
        _isCancelled = true;
        if (mounted) context.pop();
      }
    } else {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final aiState = ref.watch(aiKeyProvider);
    final providerName =
        AiProviderRegistry.getAdapter(aiState.providerId ?? '')?.displayName ??
            'AI Provider';

    return Scaffold(
      backgroundColor: AppTokens.bgBase,
      appBar: AppBar(
        backgroundColor: AppTokens.bgBase,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppTokens.textPrimary),
          onPressed: _handleClose,
        ),
        title: Text(
          'Scan squad',
          style: AppTextStyles.headline.copyWith(fontSize: 18.0),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.help_outline,
              color: _showTips ? AppTokens.goldPrimary : AppTokens.textSecondary,
            ),
            tooltip: 'Tips',
            onPressed: () {
              setState(() {
                _showTips = !_showTips;
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.screenGutter,
            vertical: AppTokens.space12,
          ),
          child: Column(
            children: [
              // Tips Card (toggleable)
              if (_showTips) ...[
                Container(
                  padding: const EdgeInsets.all(AppTokens.space16),
                  decoration: BoxDecoration(
                    color: AppTokens.bgSurface,
                    borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                    border: Border.all(color: AppTokens.borderSubtle),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'SCREENSHOT TIPS',
                            style: AppTextStyles.label.copyWith(
                              color: AppTokens.goldPrimary,
                              letterSpacing: 1.1,
                            ),
                          ),
                          InkWell(
                            onTap: () => setState(() => _showTips = false),
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: AppTokens.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTokens.space8),
                      _buildTipRow('Capture the full squad, all 15 players.'),
                      _buildTipRow('Keep the screen bright and avoid glare.'),
                      _buildTipRow('Use a full-screen capture, not a cropped image.'),
                      _buildTipRow(
                        'Nothing is sent to FPL Lens. The image goes only to your chosen provider.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTokens.space16),
              ],

              // Main State Views
              Expanded(
                child: _buildCurrentStateView(providerName),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTipRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 4.0, right: 8.0),
            child: Icon(
              Icons.check_circle_outline,
              size: 14,
              color: AppTokens.statusAvailable,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.caption.copyWith(
                color: AppTokens.textSecondary,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStateView(String providerName) {
    switch (_currentStep) {
      case ScanStep.capture:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.camera_alt_outlined,
              size: 64,
              color: AppTokens.neonPrimary,
            ),
            const SizedBox(height: AppTokens.space16),
            Text(
              'Capture your FPL squad',
              style: AppTextStyles.headline.copyWith(color: AppTokens.textPrimary),
            ),
            const SizedBox(height: AppTokens.space8),
            Text(
              'Take a photo of another screen or choose a screenshot from your gallery.',
              style: AppTextStyles.body.copyWith(
                color: AppTokens.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTokens.space32),
            AppButton(
              label: 'Take photo',
              onPressed: () => _pickImage(ImageSource.camera),
              width: double.infinity,
            ),
            const SizedBox(height: AppTokens.space12),
            AppButton(
              label: 'Choose from gallery',
              variant: AppButtonVariant.secondary,
              onPressed: () => _pickImage(ImageSource.gallery),
              width: double.infinity,
            ),
          ],
        );

      case ScanStep.preview:
        return Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTokens.bgSurface,
                  borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                  border: Border.all(color: AppTokens.borderSubtle),
                ),
                clipBehavior: Clip.antiAlias,
                child: _imageBytes != null
                    ? Image.memory(
                        _imageBytes!,
                        fit: BoxFit.contain,
                      )
                    : const SizedBox.shrink(),
              ),
            ),
            const SizedBox(height: AppTokens.space16),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Retake',
                    variant: AppButtonVariant.secondary,
                    onPressed: () {
                      setState(() {
                        _currentStep = ScanStep.capture;
                        _imageBytes = null;
                      });
                    },
                  ),
                ),
                const SizedBox(width: AppTokens.space12),
                Expanded(
                  child: AppButton(
                    label: 'Use this image',
                    onPressed: _startExtraction,
                  ),
                ),
              ],
            ),
          ],
        );

      case ScanStep.checkingImage:
      case ScanStep.readingSquad:
      case ScanStep.matchingPlayers:
        return _buildProgressView(providerName);

      case ScanStep.error:
        return _buildErrorView();
    }
  }

  Widget _buildProgressView(String providerName) {
    int currentStepIndex = 1;
    String stepLabel = 'Checking image';
    double progress = 0.33;

    if (_currentStep == ScanStep.readingSquad) {
      currentStepIndex = 2;
      stepLabel = 'Reading squad';
      progress = 0.66;
    } else if (_currentStep == ScanStep.matchingPlayers) {
      currentStepIndex = 3;
      stepLabel = 'Matching players';
      progress = 1.0;
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(
          width: 48,
          height: 48,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTokens.neonPrimary),
            strokeWidth: 3.0,
          ),
        ),
        const SizedBox(height: AppTokens.space24),
        Text(
          stepLabel,
          style: AppTextStyles.headline.copyWith(fontSize: 18),
        ),
        const SizedBox(height: AppTokens.space4),
        Text(
          'Step $currentStepIndex of 3 • Read by $providerName',
          style: AppTextStyles.caption.copyWith(color: AppTokens.textSecondary),
        ),
        const SizedBox(height: AppTokens.space24),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: AppTokens.bgSurface,
          valueColor: const AlwaysStoppedAnimation<Color>(AppTokens.neonPrimary),
          minHeight: 4.0,
        ),
        const SizedBox(height: AppTokens.space32),
        AppButton(
          label: 'Cancel',
          variant: AppButtonVariant.tertiary,
          onPressed: () {
            _isCancelled = true;
            setState(() {
              _currentStep = ScanStep.capture;
            });
          },
        ),
      ],
    );
  }

  Widget _buildErrorView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.error_outline,
          size: 56,
          color: AppTokens.statusOut,
        ),
        const SizedBox(height: AppTokens.space16),
        Text(
          'Screenshot reading failed',
          style: AppTextStyles.headline.copyWith(fontSize: 18),
        ),
        const SizedBox(height: AppTokens.space8),
        Text(
          _errorMessage ?? 'Something went wrong while processing the image.',
          style: AppTextStyles.body.copyWith(
            color: AppTokens.textSecondary,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppTokens.space32),
        if (_errorAction == 'change_key') ...[
          AppButton(
            label: 'Change key',
            onPressed: () => context.push('/settings/ai?next=/scan'),
            width: double.infinity,
          ),
        ] else if (_errorAction == 'retry') ...[
          AppButton(
            label: 'Retry',
            onPressed: _startExtraction,
            width: double.infinity,
          ),
          const SizedBox(height: AppTokens.space12),
          AppButton(
            label: 'Choose another image',
            variant: AppButtonVariant.secondary,
            onPressed: () {
              setState(() {
                _currentStep = ScanStep.capture;
              });
            },
            width: double.infinity,
          ),
        ] else ...[
          AppButton(
            label: 'Choose another image',
            onPressed: () {
              setState(() {
                _currentStep = ScanStep.capture;
              });
            },
            width: double.infinity,
          ),
        ],
      ],
    );
  }
}
