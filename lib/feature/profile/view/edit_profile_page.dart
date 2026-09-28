import 'package:easyexpire/feature/profile/viewmodel/profile_viewmodel.dart';
import 'package:easyexpire/widgets/common_app_bar.dart';
import 'package:easyexpire/widgets/common_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EditProfilePage extends StatelessWidget {
  const EditProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CommonAppBar(title: 'Edit Profile', isBack: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Consumer<ProfileViewmodel>(
          builder:
              (context, provider, child) => Form(
                key: provider.formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: provider.storeController,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        labelText: 'Store name',
                        hintText: 'Enter your store name',
                        hintStyle: TextStyle(
                          color: isDark ? Colors.grey[500] : Colors.black54,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: isDark ? Colors.grey[700]! : Colors.grey,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: theme.colorScheme.primary,
                          ),
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
                      validator:
                          (value) => provider.storeNameValidator(
                            value.toString().trim(),
                          ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: provider.addressController,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        labelText: 'Store address',
                        hintText: 'Enter your store address',
                        hintStyle: TextStyle(
                          color: isDark ? Colors.grey[500] : Colors.black54,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: isDark ? Colors.grey[700]! : Colors.grey,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: theme.colorScheme.primary,
                          ),
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
                      validator:
                          (value) => provider.storeAddressValidator(
                            value.toString().trim(),
                          ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: provider.phoneController,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        labelText: 'Phone',
                        hintText: 'Enter your phone',
                        hintStyle: TextStyle(
                          color: isDark ? Colors.grey[500] : Colors.black54,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: isDark ? Colors.grey[700]! : Colors.grey,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: theme.colorScheme.primary,
                          ),
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
                      validator:
                          (value) =>
                              provider.phoneValidator(value.toString().trim()),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: provider.emailController,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        enabled: false,
                        hintText: 'Enter email',
                        labelText: 'email',
                        hintStyle: TextStyle(
                          color: isDark ? Colors.grey[500] : Colors.black54,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                        disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color:
                                isDark
                                    ? Colors.grey[800]!
                                    : Colors.grey.shade300,
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    CommonButton(
                      title: 'Update',
                      tap: () {
                        provider.sessionProfile(context);
                      },
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
        ),
      ),
    );
  }
}
