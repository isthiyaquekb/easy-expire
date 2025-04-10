import 'package:easyexpire/core/constant/app_assets.dart';
import 'package:easyexpire/core/constant/app_routes.dart';
import 'package:easyexpire/feature/login/viewmodel/auth_viewmodel.dart';
import 'package:easyexpire/widgets/common_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authViewmodel = Provider.of<AuthViewModel>(context, listen: false);
    return Scaffold(
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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: authViewmodel.emailController,
                      style: const TextStyle(color: Colors.black,fontSize: 14,fontWeight: FontWeight.w400),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8,vertical: 0),
                        hintText: 'Enter email',
                        hintStyle: const TextStyle(color: Colors.black54,fontSize: 14,fontWeight: FontWeight.w400),
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
                    const Spacer(flex: 1,),
                    TextFormField(
                      controller: authViewmodel.passwordController,
                      style: const TextStyle(color: Colors.black,fontSize: 14,fontWeight: FontWeight.w400),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8,vertical: 0),
                        hintText: 'Enter password',
                        hintStyle: const TextStyle(color: Colors.black54,fontSize: 14,fontWeight: FontWeight.w400),
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
                    const Spacer(flex: 1,),
                    Align(
                        alignment: Alignment.centerRight,
                        child: InkWell(
                            onTap: (){
                              Navigator.pushNamed(context, AppRoutes.forgotPassword);
                            },
                            child:const Text("Forgot password"))),
                    const Spacer(flex: 3,),
                    CommonButton(
                      title: 'Login',
                      tap: () async{

                        bool success = await authViewmodel.login(
                            authViewmodel.emailController.text, authViewmodel.passwordController.text);
                        // authViewmodel.setIsLoading(false);

                        if (success) {
                          authViewmodel.emailController.clear();
                          authViewmodel.passwordController.clear();
                          Navigator.pushReplacementNamed(context, AppRoutes.dashboard);

                        } else {
                          // failureSnackBar(context,"Login failed, please check your credential");
                        }
                      },),
                    const Spacer(flex: 3,),
                    InkWell(
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.signUp);
                      },
                      child: RichText(
                        text: const TextSpan(children: [
                          TextSpan(
                              text: 'Don\'t have an account? ',
                              style: TextStyle(
                                  fontWeight: FontWeight.normal, color: Colors.black)),
                          TextSpan(
                              text: 'Signup ',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, color: Colors.black)),
                          TextSpan(
                              text: 'now.',
                              style: TextStyle(
                                  fontWeight: FontWeight.normal, color: Colors.black))
                        ]),),
                    ),
                    const Spacer(flex: 16,),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
