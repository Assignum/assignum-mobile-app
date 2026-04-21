import 'package:assignum/activities/domain/auth_facade.dart';
import 'package:assignum/auth/infrastructure/auth.dart';
import 'package:assignum/auth/infrastructure/user_service.dart';

class CoreAuthFacade implements IAuthFacade {
  @override
  String? get currentUserId => Auth().currentUser?.uid;

  @override
  String? get currentUserEmail => Auth().currentUser?.email;

  @override
  String? get currentUserDisplayName => Auth().currentUser?.displayName;

  @override
  Future<String?> getUserName(String uid) async {
    final profile = await UserService().getProfile(uid);
    return profile?.fullName;
  }
}
