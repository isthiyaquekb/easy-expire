import 'package:easyexpire/core/constant/app_assets.dart';
import 'package:easyexpire/core/constant/app_colors.dart';
import 'package:easyexpire/feature/login/viewmodel/auth_viewmodel.dart';
import 'package:easyexpire/widgets/app_text_field.dart';
import 'package:easyexpire/widgets/common_app_bar.dart';
import 'package:easyexpire/widgets/common_app_text.dart';
import 'package:easyexpire/widgets/common_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleReset(AuthViewModel authVm) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final email = _emailController.text.trim();
    final result = await authVm.sendPasswordResetEmail(email);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Password reset link sent to $email. Please check your inbox and spam folder.',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.errorMessage ??
                'Failed to send reset link. Please check the email and try again.',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authVm = Provider.of<AuthViewModel>(context, listen: false);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const CommonAppBar(
        title: 'Reset Password',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              const CommonAppText(
                'Forgot Your Password?',
                variant: AppTextVariant.headlineLg,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              CommonAppText(
                'Enter the email associated with your account and we will send you a password reset link.',
                variant: AppTextVariant.bodySm,
                color: isDark ? Colors.grey[400] : AppColors.labelTextColor,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.white12 : AppColors.borderColor,
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      AppTextField(
                        label: 'Email Address',
                        hint: 'manager@store.com',
                        controller: _emailController,
                        prefixIcon: AppAssets.emailIcon,
                        validator: (v) => authVm.emailValidator(v?.trim() ?? ''),
                      ),
                      const SizedBox(height: 24),
                      CommonButton(
                        title: _isSubmitting ? 'Sending...' : 'Send Reset Link',
                        tap: _isSubmitting ? () {} : () => _handleReset(authVm),
                      ),
                      const SizedBox(height: 16),
                      CommonAppText(
                        'If you do not see the email within a few minutes, please check your Spam or Junk folder.',
                        variant: AppTextVariant.bodySm,
                        color: isDark ? Colors.grey[400] : AppColors.labelTextColor,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
