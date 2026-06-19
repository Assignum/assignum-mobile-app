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
    final profile = await UserService().getProfileByUid(uid);
    return profile?.fullName;
  }
}
