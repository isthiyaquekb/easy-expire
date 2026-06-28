import 'package:easyexpire/core/constant/app_colors.dart';
import 'package:easyexpire/widgets/app_rich_text.dart';
import 'package:easyexpire/widgets/app_text_field.dart';
import 'package:easyexpire/widgets/common_app_text.dart';
import 'package:easyexpire/widgets/loader_overlay.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constant/app_assets.dart';
import '../../../core/constant/app_routes.dart';
import '../../../widgets/common_button.dart';
import '../viewmodel/auth_viewmodel.dart';

class SignupPage extends StatelessWidget {
  const SignupPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authViewmodel = Provider.of<AuthViewModel>(context, listen: false);
    return  Stack(
      children: [
        Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Expanded(
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
                          key: authViewmodel.signupFormKey,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              AppTextField(
                                label: 'Store Name',
                                hint: 'Enter your store name',
                                controller: authViewmodel.signupStoreNameController,
                                prefixIcon: AppAssets.storeIcon,
                                validator: (v) => authViewmodel.storeNameValidator(v.toString().trim()),
                              ),
                              SizedBox(height: MediaQuery.sizeOf(context).height*0.01,),
                              AppTextField(
                                label: 'Store Address',
                                hint: 'Enter your store address',
                                controller: authViewmodel.signupStoreAddressController,
                                prefixIcon: AppAssets.locationFilledIcon,
                                validator: (v) => authViewmodel.storeAddressValidator(v.toString().trim()),
                              ),
                              SizedBox(height: MediaQuery.sizeOf(context).height*0.01,),
                              AppTextField(
                                label: 'Email Address',
                                hint: 'manager@store.com',
                                controller: authViewmodel.signupEmailController,
                                prefixIcon: AppAssets.emailIcon,
                                validator: (v) => authViewmodel.emailValidator(v.toString().trim()),
                              ),
                              SizedBox(height: MediaQuery.sizeOf(context).height*0.01,),
                              Consumer<AuthViewModel>(builder: (context, authViewmodel, child) => AppTextField(
                                label: 'Password',
                                hint: '**********',
                                controller: authViewmodel.signupPasswordController,
                                prefixIcon: AppAssets.lockIcon,
                                suffixIcon: authViewmodel.isPasswordVisible?AppAssets.eyeClosedIcon:AppAssets.eyeOpenIcon,
                                isPassword: authViewmodel.isPasswordVisible?false:true,
                                toggleChange: () => authViewmodel.togglePasswordVisibility(),
                                validator: (v) => authViewmodel.passwordValidator(v.toString().trim()),
                              ),),
                              // TextFormField(
                              //   controller: authViewmodel.signupStoreAddressController,
                              //   style: const TextStyle(color: Colors.black,fontSize: 14,fontWeight: FontWeight.w400),
                              //   decoration: InputDecoration(
                              //     contentPadding: const EdgeInsets.symmetric(horizontal: 8,vertical: 0),
                              //     hintText: 'Enter your store address',
                              //     hintStyle: const TextStyle(color: Colors.black54,fontSize: 14,fontWeight: FontWeight.w400),
                              //     labelText: 'Store Address',
                              //     labelStyle: const TextStyle(color: Colors.black54,fontSize: 14,fontWeight: FontWeight.w400),
                              //     enabledBorder: OutlineInputBorder(
                              //       borderRadius: BorderRadius.circular(10),
                              //       borderSide: const BorderSide(color: Colors.grey),
                              //     ),
                              //     focusedBorder: OutlineInputBorder(
                              //       borderRadius: BorderRadius.circular(10),
                              //       borderSide: const BorderSide(color: Colors.green),
                              //     ),
                              //     errorBorder: OutlineInputBorder(
                              //       borderRadius: BorderRadius.circular(10),
                              //       borderSide: const BorderSide(color: Colors.red),
                              //     ),
                              //     focusedErrorBorder: OutlineInputBorder(
                              //       borderRadius: BorderRadius.circular(10),
                              //       borderSide: const BorderSide(color: Colors.red),
                              //     ),
                              //   ),
                              //   validator: (value) => authViewmodel.storeAddressValidator(value.toString().trim()),
                              // ),
                              // const Spacer(flex: 3,),
                              // TextFormField(
                              //   controller: authViewmodel.signupEmailController,
                              //   style: const TextStyle(color: Colors.black,fontSize: 14,fontWeight: FontWeight.w400),
                              //   decoration: InputDecoration(
                              //     contentPadding: const EdgeInsets.symmetric(horizontal: 8,vertical: 0),
                              //     hintText: 'Enter email',
                              //     hintStyle: const TextStyle(color: Colors.black54,fontSize: 14,fontWeight: FontWeight.w400),
                              //     labelText: 'Email',
                              //     labelStyle: const TextStyle(color: Colors.black54,fontSize: 14,fontWeight: FontWeight.w400),
                              //     enabledBorder: OutlineInputBorder(
                              //       borderRadius: BorderRadius.circular(10),
                              //       borderSide: const BorderSide(color: Colors.grey),
                              //     ),
                              //     focusedBorder: OutlineInputBorder(
                              //       borderRadius: BorderRadius.circular(10),
                              //       borderSide: const BorderSide(color: Colors.green),
                              //     ),
                              //     errorBorder: OutlineInputBorder(
                              //       borderRadius: BorderRadius.circular(10),
                              //       borderSide: const BorderSide(color: Colors.red),
                              //     ),
                              //     focusedErrorBorder: OutlineInputBorder(
                              //       borderRadius: BorderRadius.circular(10),
                              //       borderSide: const BorderSide(color: Colors.red),
                              //     ),
                              //   ),
                              //   validator: (value) => authViewmodel.emailValidator(value.toString().trim()),
                              // ),
                              // const Spacer(flex: 3,),
                              // TextFormField(
                              //   controller: authViewmodel.signupPasswordController,
                              //   style: const TextStyle(color: Colors.black,fontSize: 14,fontWeight: FontWeight.w400),
                              //   decoration: InputDecoration(
                              //     contentPadding: const EdgeInsets.symmetric(horizontal: 8,vertical: 0),
                              //     hintText: 'Enter password',
                              //     hintStyle: const TextStyle(color: Colors.black54,fontSize: 14,fontWeight: FontWeight.w400),
                              //     labelText: 'Password',
                              //     labelStyle: const TextStyle(color: Colors.black54,fontSize: 14,fontWeight: FontWeight.w400),
                              //     enabledBorder: OutlineInputBorder(
                              //       borderRadius: BorderRadius.circular(10),
                              //       borderSide: const BorderSide(color: Colors.grey),
                              //     ),
                              //     focusedBorder: OutlineInputBorder(
                              //       borderRadius: BorderRadius.circular(10),
                              //       borderSide: const BorderSide(color: Colors.green),
                              //     ),
                              //     errorBorder: OutlineInputBorder(
                              //       borderRadius: BorderRadius.circular(10),
                              //       borderSide: const BorderSide(color: Colors.red),
                              //     ),
                              //     focusedErrorBorder: OutlineInputBorder(
                              //       borderRadius: BorderRadius.circular(10),
                              //       borderSide: const BorderSide(color: Colors.red),
                              //     ),
                              //   ),
                              //   validator: (value) => authViewmodel.passwordValidator(value.toString().trim()),
                              // ),
                              // const Spacer(flex: 3,),
                              SizedBox(height: MediaQuery.sizeOf(context).height*0.05,),
                              CommonButton(
                                title: 'Sign up',
                                tap: () async{
                                  authViewmodel.signUpSession(context);
                                  /*
                                  bool success = await authViewModel.login(
                                      authViewModel.emailController.text, authViewModel.passwordController.text);
                                  authViewModel.setIsLoading(false);

                                  if (success) {
                                    successSnackBar(context,"Welcome, you are free to explore");
                                    Navigator.pushReplacementNamed(context, AppRoutes.dashboard);

                                  } else {
                                    failureSnackBar(context,"Login failed, please check your credential");
                                  }*/
                                },),
                              SizedBox(height: MediaQuery.sizeOf(context).height*0.03,),
                              InkWell(
                                onTap: () {
                                  Navigator.pushNamed(context, AppRoutes.login);
                                },
                                child: AppRichText(
                                  spans: [
                                    AppSpan("Already signup? "),
                                    AppSpan('Login ', bold: true),
                                    AppSpan('here.'),
                                  ],
                                ),
                              ),
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
        ),
        // ── Full-screen loader overlay ───────────────────────────────────
        Consumer<AuthViewModel>(builder: (context, authViewmodel, child) =>  (authViewmodel.isLoading)? const LoaderOverlay(isSignedIn: true,):SizedBox.shrink(),)
      ],
    );
  }
}
