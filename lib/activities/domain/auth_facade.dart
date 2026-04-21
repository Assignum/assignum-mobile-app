abstract class IAuthFacade {
  static late IAuthFacade instance;
  
  String? get currentUserId;
  String? get currentUserEmail;
  String? get currentUserDisplayName;
  Future<String?> getUserName(String uid);
}
