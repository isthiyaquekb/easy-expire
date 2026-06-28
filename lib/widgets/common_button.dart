import 'package:easyexpire/core/constant/app_colors.dart';
import 'package:flutter/material.dart';

class CommonButton extends StatelessWidget {
  final String title;
  final VoidCallback tap;
  const CommonButton({super.key,
    required this.title,
    required this.tap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0,horizontal: 16.0),
      child: Align(
          alignment: Alignment.center,
          child: InkWell(
          onTap: tap,
          child: Container(height: 40,width: MediaQuery.sizeOf(context).width*0.8,decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(6)
      ),child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Center(
          child: Text(title,style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onPrimaryContainer),),
        ),
      ),),
      )),
    );
  }
}
