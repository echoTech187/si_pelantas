import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/police_dio_client.dart';
import '../../../../core/services/police_notification_service.dart';
import '../domain/entities/police_officer.dart';
import '../data/dtos/police_officer_dto.dart';

class AuthState {
  final bool isLoading;
  final PoliceOfficer? officer;
  final String? errorMessage;

  const AuthState({
    this.isLoading = false,
    this.officer,
    this.errorMessage,
  });

  bool get isAuthenticated => officer != null;

  AuthState copyWith({
    bool? isLoading,
    PoliceOfficer? officer,
    String? errorMessage,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      officer: officer ?? this.officer,
      errorMessage: errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref ref;

  AuthNotifier(this.ref) : super(const AuthState()) {
    checkCurrentSession();
  }

  Future<void> checkCurrentSession() async {
    final storage = ref.read(policeSecureStorageProvider);
    final token = await storage.read(key: 'polri_jwt_access_token');
    final userJson = await storage.read(key: 'polri_user_data');

    if (token != null && userJson != null) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(userJson);
        final officer = PoliceOfficerDto.fromJson(decoded).toEntity();
        state = AuthState(officer: officer);
      } catch (_) {
        await logout();
      }
    }
  }

  Future<bool> login(String identifier, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final fcmToken = await PoliceNotificationService.instance.getFcmToken();
      final dio = ref.read(policeDioClientProvider);
      final response = await dio.post('/auth/login', data: {
        'identifier': identifier.trim(),
        'password': password,
        if (fcmToken != null) 'fcmToken': fcmToken,
      });

      final data = response.data['data'] as Map<String, dynamic>;
      final String token = data['accessToken'] as String;
      final Map<String, dynamic> officerJson = data['officer'] as Map<String, dynamic>;

      final storage = ref.read(policeSecureStorageProvider);
      await storage.write(key: 'polri_jwt_access_token', value: token);
      await storage.write(key: 'polri_user_data', value: jsonEncode(officerJson));

      final officer = PoliceOfficerDto.fromJson(officerJson).toEntity();
      state = AuthState(officer: officer);
      return true;
    } on DioException catch (e) {
      String msg;
      if (e.response == null) {
        final currentUrl = ref.read(policeServerBaseUrlProvider);
        msg = 'Tidak dapat terhubung ke server ($currentUrl).\nPastikan HP dan laptop terhubung ke Wi-Fi yang sama.';
      } else {
        msg = e.response?.data?['message'] ?? 'Gagal login. Periksa NRP/Username dan password.';
      }
      state = state.copyWith(isLoading: false, errorMessage: msg);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Koneksi error: $e');
      return false;
    }
  }

  Future<String?> updateProfile({
    required String fullName,
    required String phoneWa,
    String? photoUrl,
  }) async {
    try {
      final dio = ref.read(policeDioClientProvider);
      final response = await dio.patch('/police/profile', data: {
        'full_name': fullName.trim(),
        'phone_wa': phoneWa.trim(),
        'photo_url': photoUrl?.trim(),
      });

      if (response.statusCode == 200 && state.officer != null) {
        final updated = state.officer!.copyWith(
          fullName: fullName.trim(),
          phoneWa: phoneWa.trim(),
          photoUrl: photoUrl?.trim(),
        );
        state = state.copyWith(officer: updated);

        // Update local storage
        final storage = ref.read(policeSecureStorageProvider);
        final dto = PoliceOfficerDto(
          id: updated.id,
          nrp: updated.nrp,
          username: updated.username,
          fullName: updated.fullName,
          rankTitle: updated.rankTitle,
          roleRaw: updated.role == PoliceRole.polantas ? 'polantas' : 'unit_kamsel',
          division: updated.division,
          sectorArea: updated.sectorArea,
          phoneWa: updated.phoneWa,
          photoUrl: updated.photoUrl,
        );
        await storage.write(key: 'polri_user_data', value: jsonEncode(dto.toJson()));
        return null; // success
      }
      return 'Gagal memperbarui profil';
    } on DioException catch (e) {
      return e.response?.data?['message'] ?? 'Gagal memperbarui profil.';
    } catch (e) {
      return 'Terjadi kesalahan: $e';
    }
  }

  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final dio = ref.read(policeDioClientProvider);
      final response = await dio.post('/police/change-password', data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      });

      if (response.statusCode == 200) {
        return null; // success
      }
      return 'Gagal mengganti kata sandi';
    } on DioException catch (e) {
      return e.response?.data?['message'] ?? 'Gagal mengganti kata sandi.';
    } catch (e) {
      return 'Terjadi kesalahan: $e';
    }
  }

  Future<void> logout() async {
    try {
      final dio = ref.read(policeDioClientProvider);
      await dio.post('/police/auth/logout');
    } catch (_) {}
    final storage = ref.read(policeSecureStorageProvider);
    await storage.delete(key: 'polri_jwt_access_token');
    await storage.delete(key: 'polri_user_data');
    state = const AuthState();
  }
}

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});
