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
    return  Scaffold(
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: MediaQuery.sizeOf(context).height*0.12,),
            Hero(
              tag: AppAssets.appLogo,
              child: Image(
                height: MediaQuery.sizeOf(context).height*0.35,
                width: MediaQuery.sizeOf(context).width
                ,image: const AssetImage(AppAssets.appLogo),),
            ),
            Container(
              height: MediaQuery.sizeOf(context).height*0.50,
              width: MediaQuery.sizeOf(context).width,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10)
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: authViewmodel.signupFormKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: authViewmodel.signupStoreNameController,
                        style: const TextStyle(color: Colors.black,fontSize: 14,fontWeight: FontWeight.w400),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8,vertical: 0),
                          hintText: 'Enter your store name',
                          hintStyle: const TextStyle(color: Colors.black54,fontSize: 14,fontWeight: FontWeight.w400),
                          labelText: 'Store Name',
                          labelStyle: const TextStyle(color: Colors.black54,fontSize: 14,fontWeight: FontWeight.w400),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Colors.green),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Colors.red),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Colors.red),
                          ),
                        ),
                        validator: (value) => authViewmodel.storeNameValidator(value.toString().trim()),
                      ),
                      const Spacer(flex: 3,),
                      TextFormField(
                        controller: authViewmodel.signupStoreAddressController,
                        style: const TextStyle(color: Colors.black,fontSize: 14,fontWeight: FontWeight.w400),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8,vertical: 0),
                          hintText: 'Enter your store address',
                          hintStyle: const TextStyle(color: Colors.black54,fontSize: 14,fontWeight: FontWeight.w400),
                          labelText: 'Store Address',
                          labelStyle: const TextStyle(color: Colors.black54,fontSize: 14,fontWeight: FontWeight.w400),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Colors.green),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Colors.red),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Colors.red),
                          ),
                        ),
                        validator: (value) => authViewmodel.storeAddressValidator(value.toString().trim()),
                      ),
                      const Spacer(flex: 3,),
                      TextFormField(
                        controller: authViewmodel.signupEmailController,
                        style: const TextStyle(color: Colors.black,fontSize: 14,fontWeight: FontWeight.w400),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8,vertical: 0),
                          hintText: 'Enter email',
                          hintStyle: const TextStyle(color: Colors.black54,fontSize: 14,fontWeight: FontWeight.w400),
                          labelText: 'Email',
                          labelStyle: const TextStyle(color: Colors.black54,fontSize: 14,fontWeight: FontWeight.w400),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Colors.green),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Colors.red),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Colors.red),
                          ),
                        ),
                        validator: (value) => authViewmodel.emailValidator(value.toString().trim()),
                      ),
                      const Spacer(flex: 3,),
                      TextFormField(
                        controller: authViewmodel.signupPasswordController,
                        style: const TextStyle(color: Colors.black,fontSize: 14,fontWeight: FontWeight.w400),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8,vertical: 0),
                          hintText: 'Enter password',
                          hintStyle: const TextStyle(color: Colors.black54,fontSize: 14,fontWeight: FontWeight.w400),
                          labelText: 'Password',
                          labelStyle: const TextStyle(color: Colors.black54,fontSize: 14,fontWeight: FontWeight.w400),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Colors.green),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Colors.red),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Colors.red),
                          ),
                        ),
                        validator: (value) => authViewmodel.passwordValidator(value.toString().trim()),
                      ),
                      const Spacer(flex: 3,),
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
                      const Spacer(flex: 3,),
                      InkWell(
                        onTap: () {
                          Navigator.pushNamed(context, AppRoutes.login);
                        },
                        child: RichText(
                          text: const TextSpan(children: [
                            TextSpan(
                                text: 'Already signup? ',
                                style: TextStyle(
                                    fontWeight: FontWeight.normal, color: Colors.black)),
                            TextSpan(
                                text: 'Login ',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, color: Colors.black)),
                            TextSpan(
                                text: 'here.',
                                style: TextStyle(
                                    fontWeight: FontWeight.normal, color: Colors.black))
                          ]),),
                      ),
                      const Spacer(flex: 16,),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
