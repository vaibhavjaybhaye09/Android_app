import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../widgets/auth_shell.dart';
import '../widgets/auth_widgets.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verify(String email) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final message = await context.read<AuthProvider>().verifyOtp(
            email: email,
            otp: _otpController.text.trim(),
          );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final email =
        (ModalRoute.of(context)?.settings.arguments as String?) ?? '';

    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return AuthShell(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                const Icon(
                  Icons.mark_email_read_outlined,
                  size: 56,
                  color: Color(0xFF262626),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Enter confirmation code',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF262626),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  email.isEmpty
                      ? 'Enter the OTP sent to your email.'
                      : 'Enter the OTP sent to $email',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF8E8E8E),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
                AuthTextField(
                  controller: _otpController,
                  hintText: '6-digit OTP',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'OTP is required';
                    }
                    if (value.trim().length < 4) {
                      return 'Enter a valid OTP';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),
                AuthPrimaryButton(
                  label: 'Verify',
                  isLoading: authProvider.isLoading,
                  onPressed: email.isEmpty ? null : () => _verify(email),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pushReplacementNamed(
                    context,
                    '/register',
                  ),
                  child: const Text(
                    'Use a different email',
                    style: TextStyle(
                      color: Color(0xFF00376B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
