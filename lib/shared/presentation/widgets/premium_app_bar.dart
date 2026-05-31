import 'package:flutter/material.dart';
import 'package:assignum/shared/presentation/theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:assignum/iam/infrastructure/user_service.dart';
import 'package:assignum/iam/domain/user_profile.dart';
import 'package:assignum/iam/presentation/profile_page.dart';

class PremiumAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? titleWidget;
  final String? titleText;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final double height;
  final bool showProfileAvatar;

  const PremiumAppBar({
    super.key,
    this.titleWidget,
    this.titleText,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.height = 64.0,
    this.showProfileAvatar = false,
  });

  @override
  Widget build(BuildContext context) {
    final auth = FirebaseAuth.instance;
    final userService = UserService();
    final user = auth.currentUser;

    return AppBar(
      title: titleWidget ?? (titleText != null
          ? Text(
              titleText!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            )
          : null),
      centerTitle: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
      automaticallyImplyLeading: automaticallyImplyLeading,
      leading: leading,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(24),
        ),
      ),
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.upcBlack, Color(0xFF2C2C2C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(24),
          ),
        ),
      ),
      actions: [
        if (actions != null) ...actions!,
        if (showProfileAvatar && user != null)
          StreamBuilder<UserProfile?>(
            stream: userService.getProfileStream(user.uid),
            builder: (context, snapshot) {
              final name = snapshot.data?.fullName ?? user.displayName ?? 'Usuario';
              final initials = name.trim().split(' ').map((e) => e[0].toUpperCase()).take(2).join();
              return Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage()));
                  },
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: CircleAvatar(
                      backgroundColor: AppColors.upcRed,
                      radius: 18,
                      child: Text(
                        initials.isNotEmpty ? initials : 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(height);
}
