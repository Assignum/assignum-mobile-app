import 'package:assignum/activities/domain/auth_facade.dart';
import 'package:assignum/core/infrastructure/auth_session.dart';
import 'package:assignum/iam/infrastructure/user_service.dart';

class CoreAuthFacade implements IAuthFacade {
  @override
  String? get currentUserId => AuthSession().uid;

  @override
  String? get currentUserEmail => AuthSession().email;

  @override
  String? get currentUserDisplayName => null;

  @override
  Future<String?> getUserName(String uid) async {
    if (uid == AuthSession().uid) {
      final profile = await UserService().getProfile();
      return profile?.fullName;
    }
    return null;
  }
}
