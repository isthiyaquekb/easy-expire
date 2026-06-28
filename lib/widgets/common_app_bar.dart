import 'package:easyexpire/core/constant/app_colors.dart';
import 'package:flutter/material.dart';

class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Widget? leading; // Allows custom leading widget (e.g., menu icon, back button, logo)
  final List<Widget>? actions; // Allows custom action widgets (e.g., search icon, notifications)
  final bool isBack; // If true, automatically adds a BackButton if 'leading' is null

  const CommonAppBar({
    super.key,
    required this.title,
    this.leading,
    this.actions,
    this.isBack = false, // Default to false, allowing specific app bars like FreshManager
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, // White background from new palette
      elevation: 0.5, // Subtle shadow for distinction, as often seen in material design
      // Decide leading widget: custom one, a back arrow, or null
      leading: leading ?? (isBack ? BackButton(color: Theme.of(context).colorScheme.onSurface) : null),
      automaticallyImplyLeading: false, // Explicitly control leading to avoid conflicts
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurface, // Dark text from new palette
          fontWeight: FontWeight.bold, // Bold title as per FreshManager design
          fontSize: 20, // Appropriate size for app bar title
        ),
      ),
      centerTitle: true, // Center the title as seen in the FreshManager app bar
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}