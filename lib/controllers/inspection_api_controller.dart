import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import '../models/inspection_model.dart';

const String _baseUrl = 'https://dev-api.tankiq.com/v2/api';

// Run json decoding off the main isolate to avoid blocking the UI thread.
// Must be a top-level function to be usable with `compute()`.
dynamic _parseJson(String source) => json.decode(source);

class InspectionApiController {
  // Singleton instance
  static InspectionApiController? _instance;

  // Optional app-level logout redirect handler. The app can register a
  // callback (e.g., that uses Navigator) so the controller can trigger
  // navigation to the login page when it needs to force logout.
  static void Function()? _onLogoutRedirect;

  // Flutter Secure Storage instance
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // When true, send development-specific headers to match web VITE_IS_DEV behavior
  final bool isDev;

  // In-memory cached token to ensure availability across screens/instances
  String? _cachedToken;

  // Internal constructor
  InspectionApiController._internal({bool? isDev})
    : isDev =
          isDev ??
          bool.fromEnvironment('VITE_IS_DEV', defaultValue: false) ||
              kDebugMode;

  // Factory constructor returns singleton
  factory InspectionApiController({bool? isDev}) {
    _instance ??= InspectionApiController._internal(isDev: isDev);
    return _instance!;
  }

  static const _tokenKey = 'auth_token';
  static const _cookieKey = 'auth_cookie';
  static const _stationsKey = 'stored_stations';

  // -------------------- COOKIE HANDLING --------------------
  Future<void> _saveCookie(String cookie) async {
    try {
      await _secureStorage.write(key: _cookieKey, value: cookie);
      // ignore: avoid_print
      print('[InspectionApi] cookie saved (len=${cookie.length})');
    } catch (e) {
      // ignore: avoid_print
      print('[InspectionApi] failed to save cookie: $e');
    }
  }

  Future<String?> _readCookie() async {
    try {
      final c = await _secureStorage.read(key: _cookieKey);
      // ignore: avoid_print
      print('[InspectionApi] read cookie present=${c != null && c.isNotEmpty}');
      return c;
    } catch (e) {
      // ignore: avoid_print
      print('[InspectionApi] failed to read cookie: $e');
    }
    return null;
  }

  Future<void> _clearCookie() async {
    try {
      await _secureStorage.delete(key: _cookieKey);
      // ignore: avoid_print
      print('[InspectionApi] cookie cleared');
    } catch (e) {
      // ignore: avoid_print
      print('[InspectionApi] failed to clear cookie: $e');
    }
  }

  // -------------------- TOKEN HANDLING --------------------
  Future<void> _saveToken(String token) async {
    await _secureStorage.write(key: _tokenKey, value: token);
    _cachedToken = token;
    // ignore: avoid_print
    print('[InspectionApi] token saved (len=${token.length})');
  }

  // Capture Set-Cookie header if present on responses (stores refresh cookie)
  Future<void> _captureSetCookieFromResponse(http.Response resp) async {
    try {
      final setCookie = resp.headers['set-cookie'];
      if (setCookie != null && setCookie.isNotEmpty) {
        // Normalize the Set-Cookie header to keep only the name=value part
        // (drop attributes like Path, HttpOnly, Expires). The client needs
        // to send "Cookie: name=value" on subsequent requests so keep that.
        final normalized = setCookie.split(';').first.trim();
        await _saveCookie(normalized);
      }
    } catch (e) {
      // ignore: avoid_print
      print('[InspectionApi] failed to capture Set-Cookie: $e');
    }
  }

  Future<String?> _readToken() async {
    if (_cachedToken != null && _cachedToken!.isNotEmpty) {
      // ignore: avoid_print
      print('[InspectionApi] read token from cache=true');
      return _cachedToken;
    }
    final t = await _secureStorage.read(key: _tokenKey);
    if (t != null && t.isNotEmpty) _cachedToken = t;
    // ignore: avoid_print
    print('[InspectionApi] read token present=${t != null && t.isNotEmpty}');
    return t;
  }

  Future<void> _clearToken() async {
    await _secureStorage.delete(key: _tokenKey);
    _cachedToken = null;
    // ignore: avoid_print
    print('[InspectionApi] token cleared');
    // Print stack to help identify who triggered clear
    // ignore: avoid_print
    print('[InspectionApi] token cleared stack:${StackTrace.current}');
    // Also clear stored cookie containing refresh token
    await _clearCookie();
  }

  Future<String?> getToken() async => await _readToken();

  Future<Map<String, String>> _authHeaders() async {
    final token = await _readToken();
    final headers = {'Content-Type': 'application/json'};
    if (isDev) headers['dev-che'] = 'true';
    // attach stored cookie (if any) so server sees the refresh token cookie
    try {
      final cookie = await _readCookie();
      if (cookie != null && cookie.isNotEmpty) headers['Cookie'] = cookie;
    } catch (_) {}
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
      // also send common alternative header names some APIs expect
      headers['x-access-token'] = token;
      headers['access-token'] = token;
      headers['x-token'] = token;
      headers['token'] = token;
      // ignore: avoid_print
      print(
        '[InspectionApi] auth header attached (Authorization + x-access-token)',
      );
    }
    return headers;
  }

  // -------------------- STATION STORAGE --------------------
  Future<void> saveStations(List<Map<String, dynamic>> stations) async {
    try {
      final jsonString = json.encode(stations);
      await _secureStorage.write(key: _stationsKey, value: jsonString);
      // ignore: avoid_print
      print('[InspectionApi] saved ${stations.length} stations');
    } catch (e) {
      // ignore: avoid_print
      print('[InspectionApi] failed to save stations: $e');
    }
  }

  Future<List<Map<String, dynamic>>> readStations() async {
    final jsonString = await _secureStorage.read(key: _stationsKey);
    if (jsonString != null && jsonString.isNotEmpty) {
      final decoded = await compute(_parseJson, jsonString);
      print('station $decoded');
      if (decoded is List) {
        return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    }
    return [];
  }

  Future<void> clearStations() async {
    await _secureStorage.delete(key: _stationsKey);
  }

  // -------------------- LOGIN / LOGOUT --------------------
  Future<ApiResponse<bool>> login({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('$_baseUrl/auth/login');
    try {
      final headers = {'Content-Type': 'application/json'};
      if (isDev) headers['dev-che'] = 'true';
      final resp = await http.post(
        uri,
        headers: headers,
        body: json.encode({'email': email, 'password': password}),
      );

      // capture any Set-Cookie (refresh token) from login response
      await _captureSetCookieFromResponse(resp);

      // Debug: dump raw response for login to help map token location
      // ignore: avoid_print
      print(
        '[InspectionApi] login raw status=${resp.statusCode} headers=${resp.headers} body=${resp.body}',
      );

      // Treat any 2xx as success (some APIs return 201)
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        dynamic parsed;
        try {
          parsed = resp.body.isNotEmpty
              ? await compute(_parseJson, resp.body)
              : null;
        } catch (_) {
          parsed = null;
        }

        // Try several strategies to find token
        String? token;
        if (parsed is Map) {
          token = _extractTokenFromBody(parsed);
        }

        token ??= _extractJwt(resp.body);
        token ??= _extractTokenFromHeaders(resp.headers);

        // Debug trace - remove or gate behind a logger in production
        // ignore: avoid_print
        print(
          '[InspectionApi] login status=${resp.statusCode} tokenFound=${token != null}',
        );

        if (token != null && token.isNotEmpty) {
          await _saveToken(token);
          // ensure any cookie from the response is stored (already attempted above)
          return ApiResponse.success(
            data: true,
            message: 'Login successful',
            statusCode: resp.statusCode,
          );
        }

        return ApiResponse.error(
          message: 'Login succeeded but token missing',
          statusCode: resp.statusCode,
        );
      }

      return ApiResponse.error(
        message: 'Invalid credentials',
        statusCode: resp.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: 'Login error: $e');
    }
  }

  Future<ApiResponse<bool>> logout() async {
    final uri = Uri.parse('$_baseUrl/auth/logout');
    try {
      final headers = await _authHeaders();
      await http.post(uri, headers: headers);
      // ignore: avoid_print
      print('[InspectionApi] logout called - clearing token');
      await _clearToken();
      await clearStations();
      return ApiResponse.success(
        data: true,
        message: 'Logged out successfully',
        statusCode: 200,
      );
    } catch (e) {
      // ignore: avoid_print
      print('[InspectionApi] logout caught error - clearing token');
      await _clearToken();
      await clearStations();
      return ApiResponse.error(message: 'Logout error: $e');
    }
  }

  // -------------------- GENERIC GET --------------------
  Future<http.Response> _get(String path) async {
    final headers = await _authHeaders();
    final uri = Uri.parse('$_baseUrl/$path');
    final resp = await http.get(uri, headers: headers);

    // Debug: if not OK, dump response to help debug authorization issues
    if (resp.statusCode != 200) {
      // ignore: avoid_print
      print(
        '[InspectionApi] GET $path status=${resp.statusCode} headers=${resp.headers} body=${resp.body}',
      );
    }

    if (resp.statusCode == 401) {
      final refreshed = await _attemptRefresh();
      if (refreshed) {
        // Retry once
        final headers2 = await _authHeaders();
        final resp2 = await http.get(uri, headers: headers2);
        // Debug dump
        if (resp2.statusCode != 200) {
          // ignore: avoid_print
          print(
            '[InspectionApi] RETRY GET $path status=${resp2.statusCode} headers=${resp2.headers} body=${resp2.body}',
          );
        }
        return resp2;
      }
    }

    return resp;
  }

  Future<bool> _attemptRefresh() async {
    try {
      final uri = Uri.parse('$_baseUrl/auth/refresh');
      final headers = await _authHeaders();
      headers.putIfAbsent('Content-Type', () => 'application/json');

      // If there’s no cookie (refresh token), no point in calling the server
      final cookie = await _readCookie();
      if (cookie == null || cookie.isEmpty) {
        // ignore: avoid_print
        print('[InspectionApi] No refresh cookie found — forcing logout');
        await handleUnauthorized();
        return false;
      }

      final resp = await http.get(uri, headers: headers);
      // Debug dump
      // ignore: avoid_print
      print(
        '[InspectionApi] refresh status=${resp.statusCode} body=${resp.body}',
      );
      await _captureSetCookieFromResponse(resp);

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        dynamic parsed;
        try {
          parsed = resp.body.isNotEmpty
              ? await compute(_parseJson, resp.body)
              : null;
        } catch (_) {
          parsed = null;
        }

        String? token;
        if (parsed is Map) token = _extractTokenFromBody(parsed);
        token ??= _extractJwt(resp.body);
        token ??= _extractTokenFromHeaders(resp.headers);

        if (token != null && token.isNotEmpty) {
          await _saveToken(token);
          return true;
        } else {
          // ignore: avoid_print
          print('[InspectionApi] Refresh succeeded but no token found.');
        }
      } else if (resp.statusCode == 401) {
        // ignore: avoid_print
        print('[InspectionApi] Refresh 401 — refresh token invalid or expired');
      } else {
        // ignore: avoid_print
        print('[InspectionApi] Unexpected refresh code: ${resp.statusCode}');
      }
    } catch (e) {
      // ignore: avoid_print
      print('[InspectionApi] refresh error: $e');
    }

    // If we reach here, refresh failed. Force logout.
    await handleUnauthorized();
    return false;
  }

  /// Helper that consumers can call when they decide to invalidate auth.
  Future<void> handleUnauthorized({bool clearStationsToo = true}) async {
    // ignore: avoid_print
    print('[InspectionApi] handleUnauthorized called - clearing token');
    // Print stack to identify source
    // ignore: avoid_print
    print('[InspectionApi] handleUnauthorized stack:${StackTrace.current}');
    await _clearToken();
    if (clearStationsToo) await clearStations();
    // If an app-level redirect handler is registered, call it so the UI can
    // navigate to the login screen. Otherwise, just log and rely on callers.
    try {
      if (_onLogoutRedirect != null) _onLogoutRedirect!();
    } catch (e) {
      // ignore: avoid_print
      print('[InspectionApi] onLogoutRedirect threw: $e');
    }
  }

  /// Register an app-level logout redirect handler. Pass a callback that
  /// navigates to your login screen (e.g., using a global navigator key).
  static void registerLogoutRedirectHandler(void Function() handler) {
    _onLogoutRedirect = handler;
  }

  // -------------------- API METHODS --------------------
  Future<ApiResponse<List<Map<String, dynamic>>>> getStations() async {
    try {
      final resp = await _get('service/listStations');
      if (resp.statusCode == 200) {
        final body = resp.body.isNotEmpty
            ? await compute(_parseJson, resp.body)
            : {};
        final list = _normalizeList(
          body,
          keys: ['stations', 'data', 'items', 'result'],
        );

        // 🔥 Save the stations to local storage for offline use
        await saveStations(List<Map<String, dynamic>>.from(list));

        return ApiResponse.success(data: list, message: 'Stations loaded');
      }
      return ApiResponse.error(
        message: 'Failed to load stations',
        statusCode: resp.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: 'Error: $e');
    }
  }

  Future<ApiResponse<List<Map<String, dynamic>>>>
  getInspectionQuestions() async {
    try {
      final resp = await _get('service/getInspectionQuestions');
      if (resp.statusCode == 200) {
        final body = resp.body.isNotEmpty
            ? await compute(_parseJson, resp.body)
            : {};
        // Access "questionObject" directly
        final List<dynamic> questionList = body['questionObject'] ?? [];
        final questions = questionList
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();

        return ApiResponse.success(
          data: questions,
          message: 'Inspection questions loaded',
        );
      }

      return ApiResponse.error(
        message: 'Failed to load inspection questions',
        statusCode: resp.statusCode,
      );
    } catch (e) {
      print('[DEBUG] Error in getInspectionQuestions: $e');
      return ApiResponse.error(message: 'Error: $e');
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> getUserProfile() async {
    try {
      final resp = await _get('service/getUserProfile');
      if (resp.statusCode == 200) {
        final body = resp.body.isNotEmpty
            ? await compute(_parseJson, resp.body)
            : {};
        return ApiResponse.success(
          data: Map<String, dynamic>.from(body),
          message: 'Profile loaded',
        );
      }
      return ApiResponse.error(
        message: 'Failed to load profile',
        statusCode: resp.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: 'Error: $e');
    }
  }

  Future<ApiResponse<List<InspectionModel>>> getAllInspections() async {
    try {
      final resp = await _get('service/listInspections');

      if (resp.statusCode != 200) {
        return ApiResponse.error(
          message: 'Failed to fetch inspections (code: ${resp.statusCode})',
          statusCode: resp.statusCode,
        );
      }

      if (resp.body.isEmpty) {
        return ApiResponse.success(
          data: [],
          message: 'No inspection data found',
        );
      }

      final body = await compute(_parseJson, resp.body);

      final rawList = _normalizeList(body, keys: ['data', 'inspections']);

      if (rawList.isEmpty) {
        return ApiResponse.success(
          data: [],
          message: 'No valid inspection records found',
        );
      }

      final inspections = rawList
          .map((e) => InspectionModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      return ApiResponse.success(
        data: inspections,
        message: 'Inspections loaded successfully',
      );
    } catch (e, stack) {
      debugPrint('getAllInspections() failed: $e\n$stack');
      return ApiResponse.error(message: 'Unexpected error: $e');
    }
  }

  // Fetch a single inspection by id
  Future<ApiResponse<InspectionModel>> getInspectionData(
    String inspectionId,
  ) async {
    try {
      final resp = await _get(
        'service/getInspectionData?inspectionID=$inspectionId',
      );
      if (resp.statusCode == 200) {
        final body = resp.body.isNotEmpty
            ? await compute(_parseJson, resp.body)
            : {};
        if (body is Map) {
          final data = Map<String, dynamic>.from(body);
          return ApiResponse.success(
            data: InspectionModel.fromJson(data),
            message: 'Inspection loaded',
          );
        }
        return ApiResponse.error(message: 'Unexpected inspection payload');
      }
      return ApiResponse.error(
        message: 'Failed to load inspection',
        statusCode: resp.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: 'Error: $e');
    }
  }

  // Update inspection (server expects full inspection object)
  Future<ApiResponse<bool>> updateInspectionData(
    Map<String, dynamic> payload,
  ) async {
    final uri = Uri.parse('$_baseUrl/service/updateInspectionData');
    try {
      final headers = await _authHeaders();
      final resp = await http.post(
        uri,
        headers: headers,
        body: json.encode(payload),
      );
      // capture cookie rotation
      await _captureSetCookieFromResponse(resp);
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        return ApiResponse.success(data: true, message: 'Update successful');
      }
      return ApiResponse.error(
        message: 'Update failed',
        statusCode: resp.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: 'Update error: $e');
    }
  }

  Future<ApiResponse<String>> createInspection(
    InspectionModel inspection,
  ) async {
    final uri = Uri.parse('$_baseUrl/service/addInspection');
    try {
      final headers = await _authHeaders();
      final resp = await http.post(
        uri,
        headers: headers,
        body: json.encode(inspection.toJson()),
      );
      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final body = resp.body.isNotEmpty
            ? await compute(_parseJson, resp.body)
            : {};
        final id =
            body['id'] ?? body['inspectionId'] ?? body['data']?['id'] ?? '';
        return ApiResponse.success(
          data: id.toString(),
          message: 'Inspection created',
        );
      }
      return ApiResponse.error(
        message: 'Failed to create inspection',
        statusCode: resp.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: 'Error: $e');
    }
  }

  // -------------------- UTILS --------------------
  List<Map<String, dynamic>> _normalizeList(
    dynamic body, {
    required List<String> keys,
  }) {
    if (body is List)
      return body.map((e) => Map<String, dynamic>.from(e)).toList();
    if (body is Map) {
      for (final key in keys) {
        if (body[key] is List)
          return (body[key] as List)
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
      }
    }
    return [];
  }

  String? _extractJwt(String body) {
    final match = RegExp(
      r'[A-Za-z0-9-_]+\.[A-Za-z0-9-_]+\.[A-Za-z0-9-_]+',
    ).firstMatch(body);
    return match?.group(0);
  }

  String? _extractTokenFromBody(Map body) {
    final possibleKeys = [
      'accessToken',
      'access_token',
      'token',
      'authToken',
      'auth_token',
      'x-access-token',
      'data',
      'result',
    ];

    for (final key in possibleKeys) {
      if (body.containsKey(key)) {
        final v = body[key];
        if (v is String && v.isNotEmpty) return v;
        if (v is Map) {
          // nested
          final nested = _extractTokenFromBody(Map<String, dynamic>.from(v));
          if (nested != null && nested.isNotEmpty) return nested;
        }
      }
    }

    // Check common nested locations
    if (body['data'] is Map) {
      final nested = _extractTokenFromBody(
        Map<String, dynamic>.from(body['data']),
      );
      if (nested != null && nested.isNotEmpty) return nested;
    }

    return null;
  }

  String? _extractTokenFromHeaders(Map<String, String> headers) {
    for (final key in [
      'authorization',
      'x-access-token',
      'access-token',
      'x-token',
    ]) {
      if (headers[key] != null) {
        final v = headers[key]!;
        return v.startsWith('Bearer ') ? v.split(' ').last : v;
      }
    }
    return null;
  }
}

// -------------------- GENERIC API RESPONSE --------------------
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String message;
  final int? statusCode;

  ApiResponse({
    required this.success,
    this.data,
    required this.message,
    this.statusCode,
  });

  factory ApiResponse.success({
    required T data,
    required String message,
    int? statusCode,
  }) => ApiResponse(
    success: true,
    data: data,
    message: message,
    statusCode: statusCode,
  );

  factory ApiResponse.error({required String message, int? statusCode}) =>
      ApiResponse(
        success: false,
        data: null,
        message: message,
        statusCode: statusCode,
      );
}
