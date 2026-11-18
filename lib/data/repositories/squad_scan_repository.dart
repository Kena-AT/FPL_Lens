import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../features/ai_providers/models/extracted_player.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../models/squad_resolve_models.dart';

class SquadScanRepository {
  final ApiClient _apiClient;

  SquadScanRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<SquadResolveResponse> resolveSquad(List<ExtractedPlayer> players) async {
    final payload = {
      'players': players.map((p) => p.toJson()).toList(),
    };

    final response = await _apiClient.dio.post(
      '/api/v1/squads/resolve',
      data: payload,
    );

    return SquadResolveResponse.fromJson(response.data as Map<String, dynamic>);
  }
}

final squadScanRepositoryProvider = Provider<SquadScanRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SquadScanRepository(apiClient: apiClient);
});
