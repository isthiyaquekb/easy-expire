import 'dart:ui';

import 'package:easyexpire/core/constant/app_assets.dart';
import 'package:easyexpire/core/constant/app_colors.dart';
import 'package:easyexpire/core/constant/app_routes.dart';
import 'package:easyexpire/feature/login/viewmodel/auth_viewmodel.dart';
import 'package:easyexpire/widgets/app_rich_text.dart';
import 'package:easyexpire/widgets/app_text_field.dart';
import 'package:easyexpire/widgets/common_app_text.dart';
import 'package:easyexpire/widgets/common_button.dart';
import 'package:easyexpire/widgets/loader_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authViewmodel = Provider.of<AuthViewModel>(context, listen: false);
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: MediaQuery.sizeOf(context).height*0.05,),
                  Hero(
                      tag: AppAssets.appLogo,
                    child: Image(
                      height: MediaQuery.sizeOf(context).height*0.14,
                      width: MediaQuery.sizeOf(context).width
                      ,image: const AssetImage(AppAssets.appLogo),),
                  ),
                  SizedBox(height: 10,),
                  CommonAppText('Easy Expire', variant: AppTextVariant.headlineLg, textAlign: TextAlign.center),
                  SizedBox(height: 10,),
                  CommonAppText('Premium Inventory Precision', variant: AppTextVariant.bodySm, textAlign: TextAlign.center),
                  SizedBox(height: MediaQuery.sizeOf(context).height*0.08,),
                  Container(
                    width: MediaQuery.sizeOf(context).width,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface, // surface-container-lowest ≈ surface in your theme
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.borderColor, width: 1),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 1)),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Form(
                        key: authViewmodel.loginFormKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            AppTextField(
                              label: 'Email Address',
                              hint: 'manager@store.com',
                              controller: authViewmodel.emailController,
                              prefixIcon: AppAssets.emailIcon,
                              validator: (v) => authViewmodel.emailValidator(v.toString().trim()),
                            ),
                            SizedBox(height: MediaQuery.sizeOf(context).height*0.01,),
                            Consumer<AuthViewModel>(builder: (context, authViewmodel, child) => AppTextField(
                              label: 'Password',
                              hint: '**********',
                              controller: authViewmodel.passwordController,
                              prefixIcon: AppAssets.lockIcon,
                              suffixIcon: authViewmodel.isPasswordVisible?AppAssets.eyeClosedIcon:AppAssets.eyeOpenIcon,
                              isPassword: authViewmodel.isPasswordVisible?false:true,
                              toggleChange: () => authViewmodel.togglePasswordVisibility(),
                              validator: (v) => authViewmodel.passwordValidator(v.toString().trim()),
                            ),),
                            SizedBox(height: MediaQuery.sizeOf(context).height*0.02,),
                            Align(
                                alignment: Alignment.centerRight,
                                child: InkWell(
                                    onTap: (){
                                      Navigator.pushNamed(context, AppRoutes.forgotPassword);
                                    },
                                    child:const Text("Forgot password"))),
                            SizedBox(height: MediaQuery.sizeOf(context).height*0.02,),
                            CommonButton(
                              title: 'Login',
                              tap: () async{
                                if(authViewmodel.loginFormKey.currentState!.validate()){
                                  authViewmodel.setIsLoading(true);
                                  bool success = await authViewmodel.login(
                                      authViewmodel.emailController.text, authViewmodel.passwordController.text);
                                  authViewmodel.setIsLoading(false);
                                  if (success) {
                                    authViewmodel.emailController.clear();
                                    authViewmodel.passwordController.clear();
                                    Navigator.pushReplacementNamed(context, AppRoutes.dashboard);

                                  } else {
                                  //   // failureSnackBar(context,"Login failed, please check your credential");
                                  // }
                                }
                              }},),
                            SizedBox(height: MediaQuery.sizeOf(context).height*0.03,),
                            InkWell(
                              onTap: () {
                                Navigator.pushNamed(context, AppRoutes.signUp);
                              },
                              child: AppRichText(
                                spans: [
                                  AppSpan("Don't have an account? "),
                                  AppSpan('Signup ', bold: true),
                                  AppSpan('now.'),
                                ],
                              ),
                            ),
                            SizedBox(height: MediaQuery.sizeOf(context).height*0.03,),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // ── Full-screen loader overlay ───────────────────────────────────
       Consumer<AuthViewModel>(builder: (context, authViewmodel, child) =>  (authViewmodel.isLoading)? const LoaderOverlay(isSignedIn: true,):SizedBox.shrink(),)
      ],
    );
  }
}