
import 'package:easyexpire/core/constant/app_colors.dart';
import 'package:flutter/material.dart';

class CommonAppBar extends StatelessWidget implements PreferredSizeWidget{
  final String title;
  final bool isBack;
  const CommonAppBar({
    required this.title,
    required this.isBack,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.scaffoldColor,
      automaticallyImplyLeading: isBack,
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.textColor),
      ),
    );
  }
  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}