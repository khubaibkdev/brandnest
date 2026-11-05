import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

/// 10.0.2.2 is the host machine as seen from the Android emulator.
/// Override for a physical device: `--dart-define=API_BASE_URL=http://<lan-ip>:8000`
const _baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:8000',
);

class ApiClient {
  ApiClient({http.Client? httpClient, this.baseUrl = _baseUrl})
    : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;
  final String baseUrl;

  Future<List<Map<String, dynamic>>> fetchBrands() async {
    final response = await _httpClient.get(Uri.parse('$baseUrl/brands'));
    if (response.statusCode != 200) {
      throw Exception('GET /brands failed with ${response.statusCode}');
    }
    return (jsonDecode(response.body) as List).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> fetchSales() async {
    final response = await _httpClient.get(Uri.parse('$baseUrl/sales'));
    if (response.statusCode != 200) {
      throw Exception('GET /sales failed with ${response.statusCode}');
    }
    return (jsonDecode(response.body) as List).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> fetchOffers() async {
    final response = await _httpClient.get(Uri.parse('$baseUrl/offers'));
    if (response.statusCode != 200) {
      throw Exception('GET /offers failed with ${response.statusCode}');
    }
    return (jsonDecode(response.body) as List).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> fetchBrandOffers(String slug) async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/brands/$slug/offers'),
    );
    if (response.statusCode != 200) {
      throw Exception(
        'GET /brands/$slug/offers failed with ${response.statusCode}',
      );
    }
    return (jsonDecode(response.body) as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> fetchBrandConfig(String slug) async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/brands/$slug/config'),
    );
    if (response.statusCode != 200) {
      throw Exception(
        'GET /brands/$slug/config failed with ${response.statusCode}',
      );
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> fetchMyBanks(String idToken) async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/me/banks'),
      headers: {'Authorization': 'Bearer $idToken'},
    );
    if (response.statusCode != 200) {
      throw Exception('GET /me/banks failed with ${response.statusCode}');
    }
    return (jsonDecode(response.body) as List).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> putMyBanks(
    String idToken,
    List<Map<String, String>> cards,
  ) async {
    final response = await _httpClient.put(
      Uri.parse('$baseUrl/me/banks'),
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(cards),
    );
    if (response.statusCode != 200) {
      throw Exception('PUT /me/banks failed with ${response.statusCode}');
    }
    return (jsonDecode(response.body) as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> fetchPoints(String idToken) async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/me/points'),
      headers: {'Authorization': 'Bearer $idToken'},
    );
    if (response.statusCode != 200) {
      throw Exception('GET /me/points failed with ${response.statusCode}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> checkIn(String idToken) async {
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/me/points/checkin'),
      headers: {'Authorization': 'Bearer $idToken'},
    );
    if (response.statusCode != 200) {
      throw Exception(
        'POST /me/points/checkin failed with ${response.statusCode}',
      );
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> postRewardedAd(
    String idToken,
    String clientRef,
  ) async {
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/me/points/rewarded-ad'),
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'client_ref': clientRef}),
    );
    if (response.statusCode != 200) {
      throw Exception(
        'POST /me/points/rewarded-ad failed with ${response.statusCode}',
      );
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Report a completed order (US-18). A 400 means the server did not accept
  /// the page as a confirmation, which is a normal answer, not a failure.
  Future<Map<String, dynamic>?> postOrder(
    String idToken,
    String brandSlug,
    String url,
  ) async {
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/me/points/order'),
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'brand_slug': brandSlug, 'url': url}),
    );
    if (response.statusCode == 400) return null;
    if (response.statusCode != 200) {
      throw Exception('POST /me/points/order failed with ${response.statusCode}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Multipart, because the screenshot is the point of a deal report (US-14).
  Future<Map<String, dynamic>> createReport(
    String idToken, {
    required String text,
    String? screenshotPath,
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/me/reports'))
      ..headers['Authorization'] = 'Bearer $idToken'
      ..fields['text'] = text;
    if (screenshotPath != null) {
      request.files.add(
        await http.MultipartFile.fromPath('screenshot', screenshotPath),
      );
    }
    final response = await http.Response.fromStream(
      await _httpClient.send(request),
    );
    if (response.statusCode != 201) {
      throw Exception('POST /me/reports failed with ${response.statusCode}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> fetchMyReports(String idToken) async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/me/reports'),
      headers: {'Authorization': 'Bearer $idToken'},
    );
    if (response.statusCode != 200) {
      throw Exception('GET /me/reports failed with ${response.statusCode}');
    }
    return (jsonDecode(response.body) as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> searchProducts({
    required String query,
    List<String> brandSlugs = const [],
    List<String> categories = const [],
    List<String> rawCategories = const [],
    List<String> audiences = const [],
    double? minPrice,
    double? maxPrice,
    int page = 1,
  }) async {
    final url = Uri.parse('$baseUrl/search').replace(
      queryParameters: <String, dynamic>{
        'q': query,
        if (brandSlugs.isNotEmpty) 'brand': brandSlugs,
        if (categories.isNotEmpty) 'category': categories,
        if (rawCategories.isNotEmpty) 'raw_category': rawCategories,
        if (audiences.isNotEmpty) 'audience': audiences,
        if (minPrice != null) 'min_price': '$minPrice',
        if (maxPrice != null) 'max_price': '$maxPrice',
        'page': '$page',
      },
    );
    final response = await _httpClient.get(url);
    if (response.statusCode != 200) {
      throw Exception('GET /search failed with ${response.statusCode}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> fetchPriceHistory(int productId) async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/products/$productId/price-history'),
    );
    if (response.statusCode != 200) {
      throw Exception(
        'GET /products/$productId/price-history failed with ${response.statusCode}',
      );
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> fetchWatchStatus(
    String idToken,
    String brandSlug,
    String productUrl,
  ) async {
    final response = await _httpClient.get(
      Uri.parse(
        '$baseUrl/brands/$brandSlug/products/watch-status',
      ).replace(queryParameters: {'url': productUrl}),
      headers: {'Authorization': 'Bearer $idToken'},
    );
    if (response.statusCode != 200) {
      throw Exception(
        'GET /brands/$brandSlug/products/watch-status failed with ${response.statusCode}',
      );
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<void> createWatch(String idToken, int productId) async {
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/me/watches'),
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'product_id': productId}),
    );
    if (response.statusCode != 204) {
      throw Exception('POST /me/watches failed with ${response.statusCode}');
    }
  }

  Future<void> deleteWatch(String idToken, int productId) async {
    final response = await _httpClient.delete(
      Uri.parse('$baseUrl/me/watches/$productId'),
      headers: {'Authorization': 'Bearer $idToken'},
    );
    if (response.statusCode != 204) {
      throw Exception(
        'DELETE /me/watches/$productId failed with ${response.statusCode}',
      );
    }
  }

  // Shaadi Squad (US-21). Every write answers with the whole board, so the
  // screen redraws from one response instead of re-fetching after each tap.

  Future<List<Map<String, dynamic>>> fetchMySquads(String idToken) async =>
      ((await _squadRequest('GET', '/me/squads', idToken)) as List)
          .cast<Map<String, dynamic>>();

  Future<Map<String, dynamic>> createSquad(
    String idToken,
    Map<String, dynamic> squad,
  ) async => await _squadRequest('POST', '/me/squads', idToken, body: squad);

  /// Null when the code matches no squad.
  Future<Map<String, dynamic>?> fetchInvite(
    String idToken,
    String inviteCode,
  ) async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/me/squads/invites/${Uri.encodeComponent(inviteCode)}'),
      headers: {'Authorization': 'Bearer $idToken'},
    );
    if (response.statusCode == 404) return null;
    if (response.statusCode != 200) {
      throw Exception('GET invite failed with ${response.statusCode}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> joinSquad(
    String idToken,
    String inviteCode,
    String displayName,
  ) async => await _squadRequest(
    'POST',
    '/me/squads/join',
    idToken,
    body: {'invite_code': inviteCode, 'display_name': displayName},
  );

  Future<Map<String, dynamic>> fetchSquadBoard(String idToken, int squadId) async =>
      await _squadRequest('GET', '/me/squads/$squadId', idToken);

  Future<Map<String, dynamic>> updateSquadMe(
    String idToken,
    int squadId,
    Map<String, dynamic> changes,
  ) async =>
      await _squadRequest('PATCH', '/me/squads/$squadId/me', idToken, body: changes);

  Future<Map<String, dynamic>> pinToSquad(
    String idToken,
    int squadId,
    Map<String, dynamic> pin,
  ) async =>
      await _squadRequest('POST', '/me/squads/$squadId/items', idToken, body: pin);

  Future<Map<String, dynamic>> updateSquadItem(
    String idToken,
    int squadId,
    int itemId,
    Map<String, dynamic> changes,
  ) async => await _squadRequest(
    'PATCH',
    '/me/squads/$squadId/items/$itemId',
    idToken,
    body: changes,
  );

  Future<Map<String, dynamic>> removeSquadItem(
    String idToken,
    int squadId,
    int itemId,
  ) async =>
      await _squadRequest('DELETE', '/me/squads/$squadId/items/$itemId', idToken);

  Future<Map<String, dynamic>> voteOnSquadItem(
    String idToken,
    int squadId,
    int itemId,
    int value,
  ) async => await _squadRequest(
    'PUT',
    '/me/squads/$squadId/items/$itemId/vote',
    idToken,
    body: {'value': value},
  );

  Future<Map<String, dynamic>> commentOnSquadItem(
    String idToken,
    int squadId,
    int itemId,
    String body,
  ) async => await _squadRequest(
    'POST',
    '/me/squads/$squadId/items/$itemId/comments',
    idToken,
    body: {'body': body},
  );

  Future<dynamic> _squadRequest(
    String method,
    String path,
    String idToken, {
    Map<String, dynamic>? body,
  }) async {
    final request = http.Request(method, Uri.parse('$baseUrl$path'))
      ..headers['Authorization'] = 'Bearer $idToken';
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    final response = await http.Response.fromStream(
      await _httpClient.send(request),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('$method $path failed with ${response.statusCode}');
    }
    return jsonDecode(response.body);
  }

  Future<void> registerDeviceToken(String idToken, String fcmToken) async {
    final response = await _httpClient.put(
      Uri.parse('$baseUrl/me/device-token'),
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'fcm_token': fcmToken, 'platform': 'android'}),
    );
    if (response.statusCode != 204) {
      throw Exception(
        'PUT /me/device-token failed with ${response.statusCode}',
      );
    }
  }
}

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());
