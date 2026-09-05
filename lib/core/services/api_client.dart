import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';

/// Talks to your PHP/MySQL REST API. Every syncable table is expected to
/// expose two endpoints on the server, matching this contract:
///
///   GET  {apiBaseUrl}/sync/{table}?since={epochMillis}&business_uuid=...
///        -> returns JSON array of rows changed after `since`
///
///   POST {apiBaseUrl}/sync/{table}
///        body: { "rows": [ {...row1}, {...row2} ] }
///        -> upserts rows server-side by `uuid` (client-generated key),
///           comparing `last_updated` to resolve conflicts
///           (last-write-wins by default; change server-side if you want
///           a different conflict policy).
///
/// See the included pos_api/ PHP stub for a working implementation of
/// this exact contract against MySQL.
class ApiClient {
  ApiClient._internal();
  static final ApiClient instance = ApiClient._internal();

  Future<List<Map<String, dynamic>>> pull({
    required String table,
    required int since,
    String? businessUuid,
  }) async {
    final uri = Uri.parse('${AppConstants.apiBaseUrl}/sync/$table').replace(
      queryParameters: {
        'since': since.toString(),
        if (businessUuid != null) 'business_uuid': businessUuid,
      },
    );

    final response = await http.get(uri).timeout(AppConstants.apiTimeout);
    if (response.statusCode != 200) {
      throw ApiException('Pull failed for $table: ${response.statusCode}');
    }
    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded.cast<Map<String, dynamic>>();
  }

  Future<void> push({
    required String table,
    required List<Map<String, dynamic>> rows,
  }) async {
    if (rows.isEmpty) return;
    final uri = Uri.parse('${AppConstants.apiBaseUrl}/sync/$table');

    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'rows': rows}),
        )
        .timeout(AppConstants.apiTimeout);

    if (response.statusCode != 200) {
      throw ApiException('Push failed for $table: ${response.statusCode}');
    }
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => 'ApiException: $message';
}
