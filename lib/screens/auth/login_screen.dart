import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_colors.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));
    _fadeController.forward();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.login(
      phone: _phoneController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;
    if (success) {
      context.go('/home');
    } else {
      _showError(auth.errorMessage ?? 'Đăng nhập thất bại');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 28.w),
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 60.h),

                    // Header
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 80.w,
                            height: 80.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryGlow,
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/images/logo_thuongia.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          SizedBox(height: 20.h),
                          Text(
                            'GIỌNG THƯƠNG GIA',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2.5,
                            ),
                          ),
                          SizedBox(height: 6.h),
                          Text(
                            'Đăng nhập tài khoản',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13.sp,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 48.h),

                    // Phone field
                    _buildLabel('Số điện thoại'),
                    SizedBox(height: 8.h),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15.sp,
                      ),
                      decoration: InputDecoration(
                        hintText: '0901 234 567',
                        prefixIcon: Icon(
                          Icons.phone_android_rounded,
                          size: 20.sp,
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Vui lòng nhập số điện thoại';
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 20.h),

                    // Password field
                    _buildLabel('Mật khẩu'),
                    SizedBox(height: 8.h),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15.sp,
                      ),
                      decoration: InputDecoration(
                        hintText: '••••••••',
                        prefixIcon: Icon(
                          Icons.lock_outline_rounded,
                          size: 20.sp,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            size: 20.sp,
                          ),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Vui lòng nhập mật khẩu';
                        }
                        if (v.length < 6) return 'Mật khẩu ít nhất 6 ký tự';
                        return null;
                      },
                    ),

                    SizedBox(height: 36.h),

                    // Login button
                    Consumer<AuthProvider>(
                      builder: (context, auth, _) {
                        return _GlowButton(
                          id: 'btn_login',
                          label: 'ĐĂNG NHẬP',
                          isLoading: auth.isLoading,
                          onTap: _login,
                        );
                      },
                    ),

                    SizedBox(height: 24.h),

                    // Signup link
                    Center(
                      child: TextButton(
                        onPressed: () => context.push('/signup'),
                        child: RichText(
                          text: TextSpan(
                            text: 'Chưa có tài khoản? ',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14.sp,
                            ),
                            children: [
                              TextSpan(
                                text: 'Đăng ký ngay',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 40.h),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        color: AppColors.textSecondary,
        fontSize: 12.sp,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
      ),
    );
  }
}

// ===== Glow Button =====

class _GlowButton extends StatelessWidget {
  final String id;
  final String label;
  final bool isLoading;
  final VoidCallback onTap;

  const _GlowButton({
    required this.id,
    required this.label,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        key: ValueKey(id),
        width: double.infinity,
        height: 56.h,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(14.r),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryGlowStrong,
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: isLoading
              ? SizedBox(
                  width: 22.w,
                  height: 22.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation(
                      AppColors.background,
                    ),
                  ),
                )
              : Text(
                  label,
                  style: TextStyle(
                    color: AppColors.background,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.0,
                  ),
                ),
        ),
      ),
    );
  }
}
