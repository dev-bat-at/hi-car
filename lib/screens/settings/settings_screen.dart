import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Cấu Hình Hệ Thống',
          style: TextStyle(fontSize: 16.sp),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 16.h),

              // Title Section
              _buildSectionTitle('CHỨC NĂNG HỆ THỐNG'),

              _SettingsTile(
                icon: Icons.bolt_rounded,
                iconColor: AppColors.primary,
                title: 'Tạo Giọng Nói AI',
                subtitle: 'Soạn lời chào cá nhân hóa cho xe',
                onTap: () => context.push('/gen-audio'),
              ),

              _buildSectionTitle('CHẾ ĐỘ KẾT NỐI XE'),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: AppColors.primary),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(10.w),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          settings.connectionMode == 'phone_bluetooth'
                              ? Icons.bluetooth_rounded
                              : (settings.connectionMode == 'phone_android_auto'
                                  ? Icons.directions_car_filled_rounded
                                  : Icons.developer_board_rounded),
                          color: Colors.white,
                          size: 20.sp,
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Đang sử dụng',
                              style: TextStyle(
                                  color: AppColors.textHint, fontSize: 10.sp),
                            ),
                            Text(
                              settings.connectionMode == 'phone_bluetooth'
                                  ? 'Điện thoại + Bluetooth'
                                  : (settings.connectionMode ==
                                          'phone_android_auto'
                                      ? 'Điện thoại + Android Auto'
                                      : 'Màn Android / Android Box'),
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 15.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ActionChip(
                        label: const Text('THAY ĐỔI'),
                        onPressed: () =>
                            context.push('/connection-mode?fromSettings=true'),
                        backgroundColor: AppColors.primary,
                        side: BorderSide.none,
                        labelStyle: TextStyle(
                          color: Colors.white,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              _buildSectionTitle('CẤU HÌNH TỰ ĐỘNG PHÁT'),

              _SettingsSwitchTile(
                icon: Icons.power_rounded,
                iconColor: AppColors.success,
                title: 'Tự động phát lời chào',
                subtitle: 'Kích hoạt phát âm thanh tự động theo chế độ kết nối',
                value: settings.autoPlayEnabled,
                onChanged: (val) => settings.setAutoPlay(val),
              ),

              _buildSectionTitle('HỖ TRỢ & TÀI KHOẢN'),

              _SettingsTile(
                icon: Icons.bug_report_rounded,
                iconColor: AppColors.warning,
                title: 'Báo cáo lỗi (Gửi Bug)',
                subtitle: 'Gửi logs và thông tin lỗi hệ thống xe',
                onTap: () => _showBugReportDialog(context),
              ),

              _SettingsTile(
                icon: Icons.logout_rounded,
                iconColor: AppColors.textHint,
                title: 'Đăng xuất tài khoản',
                subtitle: 'Thoát hệ thống trên thiết bị này',
                onTap: () => _showLogoutConfirm(context, auth),
              ),

              _buildSectionTitle('CÀI ĐẶT NÂNG CAO'),

              _SettingsTile(
                icon: Icons.security_rounded,
                iconColor: AppColors.info,
                title: 'Cấu Hình Quyền Hệ Thống',
                subtitle: 'Kiểm tra và cấp lại các quyền ứng dụng',
                onTap: () =>
                    context.push('/permission-config?fromSettings=true'),
              ),

              _SettingsTile(
                icon: Icons.no_accounts_rounded,
                iconColor: AppColors.error,
                title: 'Xóa tài khoản',
                subtitle: 'Xóa vĩnh viễn toàn bộ dữ liệu & audio',
                onTap: () => _showDeleteConfirm(context, auth),
              ),

              SizedBox(height: 40.h),
              Center(
                child: Text(
                  'Giọng Thương Gia v1.0.0 (Limited Edition)',
                  style: TextStyle(
                    color: AppColors.textHint,
                    fontSize: 11.sp,
                  ),
                ),
              ),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(left: 16.w, top: 20.h, bottom: 8.h),
      child: Text(
        title,
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 11.sp,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  void _showBugReportDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardElevated,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text(
          'Báo cáo lỗi',
          style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15.sp,
              fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Nhập chi tiết lỗi hoặc hiện tượng ngắt âm thanh trên xe của bạn để chúng tôi sửa lỗi:',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12.sp),
            ),
            SizedBox(height: 12.h),
            TextField(
              controller: controller,
              maxLines: 4,
              style: TextStyle(color: AppColors.textPrimary, fontSize: 13.sp),
              decoration: const InputDecoration(
                hintText:
                    'Ví dụ: Khi Android Auto cắm dây, audio bị ngắt sau 2 giây...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Hủy', style: TextStyle(color: AppColors.textHint)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã gửi báo cáo lỗi thành công! Cảm ơn bạn.'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white),
            child: const Text('Gửi báo cáo'),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirm(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardElevated,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text('Đăng xuất?',
            style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15.sp,
                fontWeight: FontWeight.bold)),
        content: Text('Bạn có chắc chắn muốn đăng xuất khỏi ứng dụng không?',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13.sp)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Không',
                style: TextStyle(color: AppColors.textHint)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await auth.logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
            child: const Text('Đăng xuất',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardElevated,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text('XÓA TÀI KHOẢN?',
            style: TextStyle(
                color: AppColors.error,
                fontSize: 15.sp,
                fontWeight: FontWeight.bold)),
        content: Text(
            'Hành động này không thể hoàn tác. Toàn bộ audio đã lưu và tài khoản sẽ bị xoá vĩnh viễn khỏi server.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13.sp)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Không',
                style: TextStyle(color: AppColors.textHint)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await auth.deleteAccount();
              if (context.mounted) {
                context.go('/login');
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: AppColors.textPrimary),
            child: const Text('Xác nhận xóa'),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 38.w,
          height: 38.w,
          decoration: BoxDecoration(
            color: AppColors.brandBackground,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: AppColors.primary, width: 1),
          ),
          child: Icon(icon, color: Colors.white, size: 18.sp),
        ),
        title: Text(
          title,
          style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13.sp,
              fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: AppColors.textHint, fontSize: 11.sp),
        ),
        trailing: Icon(Icons.arrow_forward_ios_rounded,
            color: AppColors.textHint, size: 14.sp),
      ),
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsSwitchTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: ListTile(
        leading: Container(
          width: 38.w,
          height: 38.w,
          decoration: BoxDecoration(
            color: AppColors.brandBackground,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: AppColors.primary, width: 1),
          ),
          child: Icon(icon, color: Colors.white, size: 18.sp),
        ),
        title: Text(
          title,
          style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13.sp,
              fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: AppColors.textHint, fontSize: 11.sp),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
