import 'package:flutter/material.dart';
import 'package:second_brain/core/theme/app_colors.dart';
import 'package:second_brain/core/theme/app_radius.dart';
import 'package:second_brain/core/theme/app_spacing.dart';
import 'package:second_brain/core/theme/app_text_styles.dart';
import 'package:second_brain/core/auth/auth_service.dart';
import 'package:second_brain/features/auth/login_screen.dart';

class SignUpScreen extends StatefulWidget {
  final VoidCallback? onSwitchToLogin;
  const SignUpScreen({super.key, this.onSwitchToLogin});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _incomeController = TextEditingController(text: '75000');

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _incomeController.dispose();
    super.dispose();
  }

  void _navigateToLogin() {
    if (widget.onSwitchToLogin != null) {
      widget.onSwitchToLogin!();
    } else if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final income = double.tryParse(_incomeController.text.replaceAll(',', '')) ?? 75000.0;

    final success = await AuthService.instance.signup(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      password: _passwordController.text,
      monthlyIncome: income,
    );

    if (!mounted) return;

    if (success) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(true);
      }
      // If rendered within AuthGate, ListenableBuilder automatically transitions
      // to AppShell on AuthService.instance.isAuthenticated
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = AuthService.instance.errorMessage ?? 'Registration failed.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space24, vertical: AppSpacing.space24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo / Header
                  Center(
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.darkBlue,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.person_add_alt_1_rounded,
                        color: AppColors.white,
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space16),
                  const Text(
                    'Create Your Account',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkBlue,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space4),
                  Text(
                    'Set up your profile and financial foundation',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.secondary.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: AppSpacing.space24),

                  // Error banner
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.space12),
                      decoration: BoxDecoration(
                        color: AppColors.lightRed,
                        borderRadius: AppRadius.mediumBorderRadius,
                        border: Border.all(color: AppColors.negativeRed.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.error_outline, color: AppColors.negativeRed, size: 20),
                              const SizedBox(width: AppSpacing.space8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(color: AppColors.negativeRed, fontSize: 13, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                          if (_errorMessage!.toLowerCase().contains('already exists')) ...[
                            const SizedBox(height: AppSpacing.space8),
                            InkWell(
                              onTap: _navigateToLogin,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppColors.negativeRed.withValues(alpha: 0.4)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Already registered? Sign In now',
                                      style: TextStyle(
                                        color: AppColors.primaryBrightBlue,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.primaryBrightBlue),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space16),
                  ],

                  // Full Name
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      hintText: 'e.g. Rahul Verma',
                      prefixIcon: const Icon(Icons.person_outline, color: AppColors.darkBlue),
                      border: OutlineInputBorder(borderRadius: AppRadius.mediumBorderRadius),
                      filled: true,
                      fillColor: AppColors.surface,
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Please enter your full name';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.space16),

                  // Email Address
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      hintText: 'name@example.com',
                      prefixIcon: const Icon(Icons.email_outlined, color: AppColors.darkBlue),
                      border: OutlineInputBorder(borderRadius: AppRadius.mediumBorderRadius),
                      filled: true,
                      fillColor: AppColors.surface,
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Please enter your email';
                      if (!val.contains('@') || !val.contains('.')) return 'Please enter a valid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.space16),

                  // Phone Number
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      hintText: '+919876543210',
                      prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.darkBlue),
                      border: OutlineInputBorder(borderRadius: AppRadius.mediumBorderRadius),
                      filled: true,
                      fillColor: AppColors.surface,
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Please enter your phone number';
                      if (val.trim().length < 7) return 'Please enter a valid phone number';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.space16),

                  // Monthly Income Segment (Required by user request)
                  TextFormField(
                    controller: _incomeController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Monthly Income (₹)',
                      hintText: '75000',
                      helperText: 'Used to calculate your real savings capacity & goals feasibility',
                      prefixIcon: const Icon(Icons.currency_rupee, color: AppColors.darkBlue),
                      border: OutlineInputBorder(borderRadius: AppRadius.mediumBorderRadius),
                      filled: true,
                      fillColor: AppColors.surface,
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Please enter your monthly income';
                      final num = double.tryParse(val.replaceAll(',', ''));
                      if (num == null || num <= 0) return 'Please enter a positive amount';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.space16),

                  // Password
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline, color: AppColors.darkBlue),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: AppColors.secondaryText,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      border: OutlineInputBorder(borderRadius: AppRadius.mediumBorderRadius),
                      filled: true,
                      fillColor: AppColors.surface,
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Please enter a password';
                      if (val.length < 4) return 'Password must be at least 4 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.space24),

                  // Sign Up Button
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.darkBlue,
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(borderRadius: AppRadius.mediumBorderRadius),
                        elevation: 0,
                      ),
                      onPressed: _isLoading ? null : _handleSignUp,
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2.5),
                            )
                          : const Text(
                              'Create Account',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space20),

                  // Switch to Login
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Already have an account? ', style: AppTextStyles.secondary),
                      GestureDetector(
                        onTap: _navigateToLogin,
                        child: const Text(
                          'Sign In',
                          style: TextStyle(
                            color: AppColors.primaryBrightBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
