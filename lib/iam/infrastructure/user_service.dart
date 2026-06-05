import 'package:assignum/core/infrastructure/api_client.dart';
import 'package:assignum/iam/domain/user_profile.dart';

class UserService {
  Future<bool> profileExists() async {
    try {
      await ApiClient.get('/api/users/me');
      return true;
    } on ApiException catch (e) {
      if (e.statusCode == 404) return false;
      rethrow;
    }
  }

  Future<UserProfile?> getProfile() async {
    try {
      final data = await ApiClient.get('/api/users/me') as Map<String, dynamic>;
      return UserProfile.fromMap(data);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  Stream<UserProfile?> getProfileStream() {
    return Stream.fromFuture(getProfile());
  }

  // Onboarding: crear perfil por primera vez (POST)
  Future<void> createProfile(UserProfile p) async {
    await ApiClient.post('/api/users/me/profile', p.toApiMap());
  }

  // Edición: actualizar campos del perfil (PUT)
  Future<void> updateProfile(UserProfile p) async {
    await ApiClient.put('/api/users/me/profile', p.toApiMap());
  }

  // Compatibilidad: intenta POST, si ya existe usa PUT
  Future<void> createOrUpdateProfile(UserProfile p) async {
    try {
      await ApiClient.post('/api/users/me/profile', p.toApiMap());
    } on ApiException catch (e) {
      if (e.statusCode == 409 || e.statusCode == 400 || e.statusCode == 500) {
        await ApiClient.put('/api/users/me/profile', p.toApiMap());
      } else {
        rethrow;
      }
    }
  }
}
