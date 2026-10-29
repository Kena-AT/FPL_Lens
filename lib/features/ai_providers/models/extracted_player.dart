/// Extracted player name and position slot from screenshot OCR.
class ExtractedPlayer {
  final String rawName;
  final String? slot;
  final int? purchasePriceTenths;

  const ExtractedPlayer({
    required this.rawName,
    this.slot,
    this.purchasePriceTenths,
  });

  Map<String, dynamic> toJson() => {
        'raw_name': rawName,
        if (slot != null) 'slot': slot,
        if (purchasePriceTenths != null)
          'purchase_price_tenths': purchasePriceTenths,
      };

  factory ExtractedPlayer.fromJson(Map<String, dynamic> json) {
    return ExtractedPlayer(
      rawName: json['raw_name'] as String? ?? json['name'] as String? ?? '',
      slot: json['slot'] as String? ?? json['position'] as String?,
      purchasePriceTenths: json['purchase_price_tenths'] as int?,
    );
  }
}
