import 'dart:developer';

import 'package:easyexpire/core/constant/app_assets.dart';
import 'package:easyexpire/core/constant/app_colors.dart';
import 'package:easyexpire/core/constant/app_routes.dart';
import 'package:easyexpire/feature/home/viewmodel/home_viewmodel.dart';
import 'package:easyexpire/feature/profile/viewmodel/profile_viewmodel.dart';
import 'package:easyexpire/widgets/common_app_bar.dart';
import 'package:easyexpire/widgets/profile_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profileProvider = Provider.of<ProfileViewmodel>(context, listen: false);
      profileProvider.initialize();
    });

    return  Scaffold(
      backgroundColor: AppColors.scaffoldColor,
      appBar: CommonAppBar(title: "Profile",isBack: false,),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Consumer<ProfileViewmodel>(builder: (context, profileViewmodel, child) =>  Container(height: MediaQuery.sizeOf(context).height*0.3,width: MediaQuery.sizeOf(context).width,
            decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  AppColors.scaffoldColor,
                  AppColors.primaryColor,
                ],begin: Alignment.topCenter,end: Alignment.bottomCenter),
                boxShadow: [
                  BoxShadow(color: Colors.black26,blurRadius: 4.0,spreadRadius: 6.0,offset: Offset(0.4, 0.4))
                ],
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(20),bottomRight: Radius.circular(12))
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Align(
                  //   alignment: Alignment.topRight,
                  //   child: Padding(
                  //     padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  //     child: SvgPicture.asset(AppAssets.editIcon,height: 24,width: 24,),
                  //   ),
                  // ),
                  ProfileTextWidget(icons:AppAssets.storeIcon,title: 'Store name',value: profileViewmodel.userModel.storeName,),
                  ProfileTextWidget(icons:AppAssets.addressIcon,title: 'Store address',value: profileViewmodel.userModel.storeAddress,),
                  ProfileTextWidget(icons:AppAssets.emailIcon,title: 'Email',value: profileViewmodel.userModel.email,),
                  ProfileTextWidget(icons:AppAssets.phoneIcon,title: 'Phone',value: profileViewmodel.userModel.phone,),
                ],
              ),
            ),),),
          Spacer(),
          ProfileButton(
            title: 'Edit Profile',
            tap: () {
              Navigator.pushNamed(context, AppRoutes.editProfile);
            },
          ),
          ProfileButton(
            title: 'Privacy',
            tap: () {

            },
          ),
          ProfileButton(
            title: 'Settings',
            tap: () {
              Navigator.pushNamed(context, AppRoutes.settings);
            },
          ),
    Consumer<HomeViewModel>(builder: (context, provider, child) =>ProfileButton(
            title: 'Logout',
            tap: () async{
              await provider.signOut();
              log("LOGOUT OUT HOME SCREEN");
              Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => route.isFirst,);
            },
          ),),
          Spacer(),
        ],
      ),
    );
  }
}

class ProfileTextWidget extends StatelessWidget {
  String icons;
  String title;
  String value;
  ProfileTextWidget({
    required this.icons,
    required this.title,
    required this.value,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: SvgPicture.asset(icons,height: 24,width: 24,colorFilter: ColorFilter.mode(AppColors.textColor, BlendMode.srcIn),),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
               /* Text(title,style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textColor),),*/
                Text(value,
                  maxLines: 2,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textColor),)
              ],
            ),
          )
        ],
      ),
    );
  }
}
