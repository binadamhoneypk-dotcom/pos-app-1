import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';

/// Fetches gold/silver rate per gram when a provider is configured via
/// `METAL_RATE_API_URL` / `METAL_RATE_API_KEY` (see AppConstants). No
/// provider is free-and-keyless in a way that's safe to hardcode here,
/// so Phase 2 ships with this OFF by default — the Zakat Calculator
/// always lets the shopkeeper type today's rate manually instead, and
/// only shows the "ابھی ریٹ لائیں" (fetch now) button when a provider
/// URL has actually been configured at build time.
///
/// TO ENABLE: sign up for a free-tier key at metals-api.com,
/// metalpriceapi.com, or goldapi.io, then run:
///   flutter run \
///     --dart-define=METAL_RATE_API_URL=https://your-provider/endpoint \
///     --dart-define=METAL_RATE_API_KEY=your_key
/// and adapt [_parseResponse] below to that provider's exact JSON shape
/// (they differ) — this is the one place that needs to change.
class MetalRateService {
  MetalRateService._internal();
  static final MetalRateService instance = MetalRateService._internal();

  bool get isConfigured => AppConstants.metalRateApiUrl.isNotEmpty;

  /// Returns (goldPricePerGram, silverPricePerGram) in the shopkeeper's
  /// local currency, or null if no provider is configured or the
  /// request fails — callers should fall back to manual entry either way.
  Future<({double goldPerGram, double silverPerGram})?> fetchRates() async {
    if (!isConfigured) return null;
    try {
      final uri = Uri.parse(AppConstants.metalRateApiUrl);
      final response = await http.get(
        uri,
        headers: {
          if (AppConstants.metalRateApiKey.isNotEmpty)
            'x-access-token': AppConstants.metalRateApiKey,
        },
      ).timeout(const Duration(seconds: 12));

      if (response.statusCode != 200) return null;
      return _parseResponse(jsonDecode(response.body) as Map<String, dynamic>);
    } catch (_) {
      // Any network/parse failure just means "use manual entry" — never
      // block the Zakat Calculator on a flaky external API.
      return null;
    }
  }

  /// ADAPT THIS to your chosen provider's response shape. As shipped it
  /// expects `{"gold_per_gram": 000.0, "silver_per_gram": 000.0}` — the
  /// simplest possible contract, meant to be fronted by a tiny proxy
  /// endpoint on your own `pos_api/` if your chosen provider's raw JSON
  /// looks different (keeps the API key server-side too, which is safer
  /// than shipping it inside the compiled app).
  ({double goldPerGram, double silverPerGram})? _parseResponse(Map<String, dynamic> json) {
    final gold = json['gold_per_gram'];
    final silver = json['silver_per_gram'];
    if (gold == null || silver == null) return null;
    return (
      goldPerGram: (gold as num).toDouble(),
      silverPerGram: (silver as num).toDouble(),
    );
  }
}
