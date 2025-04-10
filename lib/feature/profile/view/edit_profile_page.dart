import 'package:easyexpire/core/constant/app_colors.dart';
import 'package:easyexpire/feature/profile/viewmodel/profile_viewmodel.dart';
import 'package:easyexpire/widgets/common_app_bar.dart';
import 'package:easyexpire/widgets/common_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EditProfilePage extends StatelessWidget {
  const EditProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldColor,
      appBar: CommonAppBar(title: 'Edit Profile',isBack: true,),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Consumer<ProfileViewmodel>(builder: (context, provider, child) => Form(
          key: provider.formKey,
          child: Column(
            children: [
              TextFormField(
                controller: provider.storeController,
                style: const TextStyle(color: Colors.black,fontSize: 14,fontWeight: FontWeight.w400),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8,vertical: 0),
                  labelText: 'Store name',
                  hintText: 'Enter your store name',
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
                validator: (value) => provider.storeNameValidator(value.toString().trim()),
              ),
              SizedBox(height: 8,),
              TextFormField(
                controller: provider.addressController,
                style: const TextStyle(color: Colors.black,fontSize: 14,fontWeight: FontWeight.w400),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8,vertical: 0),
                  labelText: 'Store address',
                  hintText: 'Enter your store address',
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
                validator: (value) => provider.storeAddressValidator(value.toString().trim()),
              ),
              SizedBox(height: 8,),
              TextFormField(
                controller: provider.phoneController,
                style: const TextStyle(color: Colors.black,fontSize: 14,fontWeight: FontWeight.w400),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8,vertical: 0),
                  labelText: 'Phone',
                  hintText: 'Enter your phone',
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
                validator: (value) => provider.phoneValidator(value.toString().trim()),
              ),
              SizedBox(height: 8,),
              TextFormField(
                controller: provider.emailController,
                style: const TextStyle(color: Colors.black,fontSize: 14,fontWeight: FontWeight.w400),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8,vertical: 0),
                  enabled: false,
                  hintText: 'Enter email',
                  labelText: 'email',
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
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                ),
              ),
              Spacer(),
              CommonButton(title:'Update', tap: () {
                provider.sessionProfile(context);
              },),
              SizedBox(height: 40,),
            ],
          ),
        ),),
      ),
    );
  }
}
