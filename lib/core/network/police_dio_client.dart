import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');
const String _nodeEnv = String.fromEnvironment('NODE_ENV', defaultValue: '');

const String kProdPoliceApiBaseUrl =
    'https://si-pelantas-open-api.vercel.app/api/v1/police';
const String kDevPoliceApiBaseUrl =
    'http://192.168.1.52:4000/api/v1/police';

/// Cek apakah mode Production: via NODE_ENV='prod'/'production' atau release build (kReleaseMode)
final bool kIsProduction = _nodeEnv.toLowerCase() == 'prod' ||
    _nodeEnv.toLowerCase() == 'production' ||
    kReleaseMode;

final String kDefaultPoliceApiBaseUrl = _envBaseUrl.isNotEmpty
    ? _envBaseUrl
    : (kIsProduction ? kProdPoliceApiBaseUrl : kDevPoliceApiBaseUrl);

final policeSecureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

class PoliceServerUrlNotifier extends StateNotifier<String> {
  final FlutterSecureStorage _storage;

  PoliceServerUrlNotifier(this._storage)
      : super(_envBaseUrl.isNotEmpty ? _envBaseUrl : kDefaultPoliceApiBaseUrl) {
    _loadCustomUrl();
  }

  Future<void> _loadCustomUrl() async {
    try {
      final saved = await _storage.read(key: 'custom_police_api_url');
      if (saved != null && saved.trim().isNotEmpty) {
        state = saved.trim();
      }
    } catch (_) {}
  }

  Future<void> setBaseUrl(String newUrl) async {
    final clean = newUrl.trim();
    await _storage.write(key: 'custom_police_api_url', value: clean);
    state = clean;
  }
}

final policeServerBaseUrlProvider =
    StateNotifierProvider<PoliceServerUrlNotifier, String>((ref) {
  final storage = ref.watch(policeSecureStorageProvider);
  return PoliceServerUrlNotifier(storage);
});

final policeDioClientProvider = Provider<Dio>((ref) {
  final storage = ref.watch(policeSecureStorageProvider);
  final baseUrl = ref.watch(policeServerBaseUrlProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await storage.read(key: 'polri_jwt_access_token');
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ),
  );

  return dio;
});
