import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpl_lens/core/network/api_client.dart';
import 'package:fpl_lens/core/network/error_mapper.dart';
import 'package:fpl_lens/data/models/fpl_models.dart';
import 'package:fpl_lens/features/auth/providers/auth_provider.dart';

class DerivedPlayerPrice {
  final int purchasePriceTenths;
  final int sellingPriceTenths;
  final String priceSource; // 'FROM_TRANSFER' or 'CONFIRM'
  final bool isConfirmed;

  const DerivedPlayerPrice({
    required this.purchasePriceTenths,
    required this.sellingPriceTenths,
    required this.priceSource,
    required this.isConfirmed,
  });
}

abstract class IFplRepository {
  Future<EntryModel> getEntry(int teamId);
  Future<SquadPicksResponse> getSquad(int teamId, {int? gw, bool force = false});
  Future<HistoryResponse> getHistory(int teamId);
  Future<List<TransferItemModel>> getTransfers(int teamId);
  Future<CurrentGameweekResponse> getCurrentGameweek();
  Future<Map<String, dynamic>> getProjectionBundle(int gw);
  Future<Map<String, dynamic>> getPlayerProjection(int gw, int fplId);
  Future<List<Map<String, dynamic>>> searchPlayers(String query, {int limit = 20});

  DerivedPlayerPrice derivePlayerPrice({
    required int playerFplId,
    required int nowCostTenths,
    required List<TransferItemModel> transferHistory,
    int? savedPurchasePriceTenths,
    bool? isUserConfirmed,
  });

  int computeSellingPriceTenths({
    required int purchasePriceTenths,
    required int nowCostTenths,
  });
}

class FplRepository implements IFplRepository {
  final ApiClient? _apiClient;
  final Dio? _dioOverride;

  FplRepository({ApiClient? apiClient, Dio? dio})
      : _apiClient = apiClient,
        _dioOverride = dio;

  Dio get _dio => _dioOverride ?? _apiClient?.dio ?? Dio();

  @override
  Future<EntryModel> getEntry(int teamId) async {
    try {
      final response = await _dio.get('/api/v1/fpl/entry/$teamId');
      return EntryModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ErrorMapper.fromException(e);
    }
  }

  @override
  Future<SquadPicksResponse> getSquad(int teamId, {int? gw, bool force = false}) async {
    try {
      final queryParams = <String, dynamic>{
        if (gw != null) 'gw': gw,
        if (force) 'force': true,
      };
      final response = await _dio.get(
        '/api/v1/fpl/entry/$teamId/squad',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      return SquadPicksResponse.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ErrorMapper.fromException(e);
    }
  }

  @override
  Future<HistoryResponse> getHistory(int teamId) async {
    try {
      final response = await _dio.get('/api/v1/fpl/entry/$teamId/history');
      return HistoryResponse.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ErrorMapper.fromException(e);
    }
  }

  @override
  Future<List<TransferItemModel>> getTransfers(int teamId) async {
    try {
      final response = await _dio.get('/api/v1/fpl/entry/$teamId/transfers');
      final list = response.data as List<dynamic>;
      return list.map((item) => TransferItemModel.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      throw ErrorMapper.fromException(e);
    }
  }

  @override
  Future<CurrentGameweekResponse> getCurrentGameweek() async {
    try {
      final response = await _dio.get('/api/v1/gameweeks/current');
      return CurrentGameweekResponse.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ErrorMapper.fromException(e);
    }
  }

  @override
  Future<Map<String, dynamic>> getProjectionBundle(int gw) async {
    try {
      final response = await _dio.get('/api/v1/projections/$gw');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw ErrorMapper.fromException(e);
    }
  }

  @override
  Future<Map<String, dynamic>> getPlayerProjection(int gw, int fplId) async {
    try {
      final response = await _dio.get('/api/v1/projections/$gw/players/$fplId');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw ErrorMapper.fromException(e);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> searchPlayers(String query, {int limit = 20}) async {
    try {
      final response = await _dio.get(
        '/api/v1/players/search',
        queryParameters: {'q': query, 'limit': limit},
      );
      final list = response.data as List<dynamic>;
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Derives purchase and selling price per spec §12.2 and Frontend Plan P7:
  /// - Players brought in by transfer take `element_in_cost` and are marked `FROM TRANSFER`.
  /// - Other players are marked `CONFIRM` with `nowCost` used as initial defaulted estimate.
  /// - If user has already confirmed a price, it is retained as `CONFIRMED_USER`.
  @override
  DerivedPlayerPrice derivePlayerPrice({
    required int playerFplId,
    required int nowCostTenths,
    required List<TransferItemModel> transferHistory,
    int? savedPurchasePriceTenths,
    bool? isUserConfirmed,
  }) {
    if (savedPurchasePriceTenths != null && isUserConfirmed == true) {
      final sellingPrice = computeSellingPriceTenths(
        purchasePriceTenths: savedPurchasePriceTenths,
        nowCostTenths: nowCostTenths,
      );
      return DerivedPlayerPrice(
        purchasePriceTenths: savedPurchasePriceTenths,
        sellingPriceTenths: sellingPrice,
        priceSource: 'CONFIRMED_USER',
        isConfirmed: true,
      );
    }

    // Search transfer records for this player brought in, newest first
    final matchingTransfers = transferHistory.where((t) => t.elementIn == playerFplId).toList()
      ..sort((a, b) => b.time.compareTo(a.time));

    if (matchingTransfers.isNotEmpty) {
      final purchasePrice = matchingTransfers.first.elementInCost;
      final sellingPrice = computeSellingPriceTenths(
        purchasePriceTenths: purchasePrice,
        nowCostTenths: nowCostTenths,
      );
      return DerivedPlayerPrice(
        purchasePriceTenths: purchasePrice,
        sellingPriceTenths: sellingPrice,
        priceSource: 'FROM_TRANSFER',
        isConfirmed: true,
      );
    }

    // Defaulted to current price, marked CONFIRM
    final purchasePrice = savedPurchasePriceTenths ?? nowCostTenths;
    final sellingPrice = computeSellingPriceTenths(
      purchasePriceTenths: purchasePrice,
      nowCostTenths: nowCostTenths,
    );
    return DerivedPlayerPrice(
      purchasePriceTenths: purchasePrice,
      sellingPriceTenths: sellingPrice,
      priceSource: 'CONFIRM',
      isConfirmed: false,
    );
  }

  /// Calculates selling price:
  /// - If `nowCost > purchasePrice`, seller keeps 50% of the rise (rounded down to 0.1m / 1 tenth):
  ///   `purchasePrice + ((nowCost - purchasePrice) ~/ 2)`
  /// - If `nowCost <= purchasePrice`, selling price is `nowCost` (fall rule).
  @override
  int computeSellingPriceTenths({
    required int purchasePriceTenths,
    required int nowCostTenths,
  }) {
    if (nowCostTenths > purchasePriceTenths) {
      final profitTenths = nowCostTenths - purchasePriceTenths;
      return purchasePriceTenths + (profitTenths ~/ 2);
    } else {
      return nowCostTenths;
    }
  }
}

final fplRepositoryProvider = Provider<FplRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return FplRepository(apiClient: apiClient);
});
