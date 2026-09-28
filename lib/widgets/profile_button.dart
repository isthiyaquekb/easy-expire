import 'package:flutter/material.dart';

class ProfileButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? trailing;
  final VoidCallback onTap;
  final bool isLogout;

  const ProfileButton({
    super.key,
    required this.icon,
    required this.title,
    this.trailing,
    required this.onTap,
    this.isLogout = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      onTap: onTap,
      leading: Icon(
        icon,
        color:
            isLogout
                ? Colors.red
                : (isDark ? Colors.grey[300] : Colors.grey[700]),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color:
              isLogout ? Colors.red : Theme.of(context).colorScheme.onSurface,
        ),
      ),
      trailing:
          trailing != null
              ? Text(
                trailing!,
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              )
              : Icon(
                Icons.chevron_right,
                size: 20,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
    );
  }
}
