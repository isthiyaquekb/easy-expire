import 'package:easyexpire/core/constant/app_assets.dart';
import 'package:easyexpire/core/constant/app_colors.dart';
import 'package:easyexpire/core/constant/app_string.dart';
import 'package:easyexpire/feature/splash/view_model/splash_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});


  @override
  Widget build(BuildContext context) {

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final splashProvider = Provider.of<SplashProvider>(context, listen: false);
      splashProvider.startTimer(context);
    });


    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(
            child: Container(
              height: MediaQuery.sizeOf(context).height*0.45,
              width: MediaQuery.sizeOf(context).width*0.45,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Hero(
                  tag: AppAssets.appLogo,
                    child: const Image(image: AssetImage(AppAssets.appLogo),fit: BoxFit.contain,))
              ),
            ),
          ),
          const Text(AppString.appName,style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.textColor
          ),)
        ],
      ),
    );
  }
}
