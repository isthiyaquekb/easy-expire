import 'package:easyexpire/core/constant/app_colors.dart';
import 'package:flutter/material.dart';

class ProfileButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? trailing;
  final VoidCallback onTap;
  final bool isLogout;

  const ProfileButton({super.key,
    required this.icon,
    required this.title,
    this.trailing,
    required this.onTap,
    this.isLogout = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: isLogout ? Colors.red : Colors.grey[700]),
      title: Text(title, style: TextStyle(
          fontWeight: FontWeight.w500,
          color: isLogout ? Colors.red : null
      )),
      trailing: trailing != null
          ? Text(trailing!, style: const TextStyle(color: Colors.grey))
          : const Icon(Icons.chevron_right, size: 20),
    );
  }
}
