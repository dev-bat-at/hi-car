import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_colors.dart';
import '../../core/utils/ui_utils.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/premium_loading.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _codeController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isCodeLogin = true; // Default to Code login
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
    _codeController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final auth = context.read<AuthProvider>();

    EasyLoading.show(status: 'Đang xác thực...');

    final success = _isCodeLogin
        ? await auth.login(code: _codeController.text.trim())
        : await auth.login(
            phone: _phoneController.text.trim(),
            password: _passwordController.text,
          );

    EasyLoading.dismiss();

    if (!mounted) return;
    if (success) {
      UiUtils.showSuccess(context, 'Đăng nhập thành công');
      context.go('/home');
    } else {
      UiUtils.showError(context, auth.errorMessage ?? 'Đăng nhập thất bại');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 48.h),

                      // Header
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 72.w,
                              height: 72.w,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
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
                          ],
                        ),
                      ),

                      SizedBox(height: 40.h),

                      // Login Type Toggle
                      Container(
                        padding: EdgeInsets.all(4.w),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _ToggleTab(
                                label: 'Bằng Mã',
                                isActive: _isCodeLogin,
                                onTap: () =>
                                    setState(() => _isCodeLogin = true),
                              ),
                            ),
                            Expanded(
                              child: _ToggleTab(
                                label: 'Bằng Số ĐT',
                                isActive: !_isCodeLogin,
                                onTap: () =>
                                    setState(() => _isCodeLogin = false),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 32.h),

                      if (_isCodeLogin) ...[
                        // Code Login Field
                        _buildLabel('Mã kích hoạt'),
                        SizedBox(height: 8.h),
                        TextFormField(
                          controller: _codeController,
                          style: TextStyle(
                              color: AppColors.textPrimary, fontSize: 15.sp),
                          decoration: InputDecoration(
                            hintText: 'VD: HC8888',
                            prefixIcon:
                                Icon(Icons.qr_code_rounded, size: 20.sp),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Vui lòng nhập mã kích hoạt'
                              : null,
                        ),
                      ] else ...[
                        // Phone field
                        _buildLabel('Số điện thoại'),
                        SizedBox(height: 8.h),
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(11),
                          ],
                          style: TextStyle(
                              color: AppColors.textPrimary, fontSize: 15.sp),
                          decoration: InputDecoration(
                            hintText: '0901 234 567',
                            prefixIcon:
                                Icon(Icons.phone_android_rounded, size: 20.sp),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty)
                              return 'Vui lòng nhập số điện thoại';
                            if (v.length < 10)
                              return 'Số điện thoại không hợp lệ';
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
                              color: AppColors.textPrimary, fontSize: 15.sp),
                          decoration: InputDecoration(
                            hintText: '••••••••',
                            prefixIcon:
                                Icon(Icons.lock_outline_rounded, size: 20.sp),
                            suffixIcon: IconButton(
                              icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                  size: 20.sp),
                              onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          validator: (v) => (v == null || v.isEmpty)
                              ? 'Vui lòng nhập mật khẩu'
                              : null,
                        ),
                      ],

                      SizedBox(height: 48.h),

                      // Login button
                      Consumer<AuthProvider>(
                        builder: (context, auth, _) {
                          return _GlowButton(
                            id: 'btn_login',
                            label: 'ĐĂNG NHẬP NGAY',
                            isLoading: auth.isLoading,
                            onTap: _login,
                          );
                        },
                      ),

                      SizedBox(height: 40.h),
                    ],
                  ),
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
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(14.r),
          boxShadow: null,
        ),
        child: Center(
          child: isLoading
              ? PremiumLoading(
                  size: 20,
                  color: Colors.white,
                )
              : Text(
                  label,
                  style: TextStyle(
                    color: Colors.white,
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

class _ToggleTab extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _ToggleTab({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40.h,
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : AppColors.textSecondary,
              fontSize: 13.sp,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
