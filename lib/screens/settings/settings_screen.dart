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
                child: Column(
                  children: [
                    _buildModeCard(
                      context,
                      mode: 'phone_bluetooth',
                      title: 'Điện thoại + Bluetooth',
                      description: 'Tự động phát lời chào khi điện thoại kết nối Bluetooth với xe.',
                      icon: Icons.bluetooth_rounded,
                      activeMode: settings.connectionMode,
                      onTap: () => settings.setConnectionMode('phone_bluetooth'),
                    ),
                    SizedBox(height: 10.h),
                    _buildModeCard(
                      context,
                      mode: 'phone_android_auto',
                      title: 'Điện thoại + Android Auto',
                      description: 'Chỉ tự động phát khi xe kích hoạt màn hình Android Auto.',
                      icon: Icons.directions_car_filled_rounded,
                      activeMode: settings.connectionMode,
                      onTap: () => settings.setConnectionMode('phone_android_auto'),
                    ),
                    SizedBox(height: 10.h),
                    _buildModeCard(
                      context,
                      mode: 'android_screen_box',
                      title: 'Màn Android độ / Android Box',
                      description: 'Chạy trực tiếp trên màn hình xe hoặc tự động chạy ngầm trên Box khi nổ máy.',
                      icon: Icons.developer_board_rounded,
                      activeMode: settings.connectionMode,
                      onTap: () => settings.setConnectionMode('android_screen_box'),
                    ),
                  ],
                ),
              ),

              _buildSectionTitle('CẤU HÌNH TỰ ĐỘNG PHÁT'),

              _SettingsSwitchTile(
                icon: Icons.power_rounded,
                iconColor: const Color(0xFF00E676),
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
      padding: EdgeInsets.only(left: 20.w, top: 20.h, bottom: 8.h),
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

  Widget _buildModeCard(
    BuildContext context, {
    required String mode,
    required String title,
    required String description,
    required IconData icon,
    required String activeMode,
    required VoidCallback onTap,
  }) {
    final isSelected = mode == activeMode;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.05) : AppColors.card,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: 1.5.w,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.15),
                    blurRadius: 10.r,
                    spreadRadius: 1.w,
                  )
                ]
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary.withOpacity(0.15) : AppColors.background.withOpacity(0.4),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                size: 22.sp,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    description,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10.5.sp,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: AppColors.primary,
                size: 18.sp,
              ),
          ],
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text(
          'Báo cáo lỗi',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 15.sp, fontWeight: FontWeight.bold),
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
                hintText: 'Ví dụ: Khi Android Auto cắm dây, audio bị ngắt sau 2 giây...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: AppColors.textHint)),
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
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.background),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text('Đăng xuất?', style: TextStyle(color: AppColors.textPrimary, fontSize: 15.sp, fontWeight: FontWeight.bold)),
        content: Text('Bạn có chắc chắn muốn đăng xuất khỏi ứng dụng không?', style: TextStyle(color: AppColors.textSecondary, fontSize: 13.sp)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Không', style: TextStyle(color: AppColors.textHint)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await auth.logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
            child: const Text('Đăng xuất', style: TextStyle(color: AppColors.error)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text('XÓA TÀI KHOẢN?', style: TextStyle(color: AppColors.error, fontSize: 15.sp, fontWeight: FontWeight.bold)),
        content: Text('Hành động này không thể hoàn tác. Toàn bộ audio đã lưu và tài khoản sẽ bị xoá vĩnh viễn khỏi server.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13.sp)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Không', style: TextStyle(color: AppColors.textHint)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await auth.deleteAccount();
              if (context.mounted) {
                context.go('/login');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: AppColors.textPrimary),
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
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 38.w,
        height: 38.w,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Icon(icon, color: iconColor, size: 20.sp),
      ),
      title: Text(
        title,
        style: TextStyle(color: AppColors.textPrimary, fontSize: 13.sp, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: AppColors.textHint, fontSize: 11.sp),
      ),
      trailing: Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textHint, size: 14.sp),
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
    return ListTile(
      leading: Container(
        width: 38.w,
        height: 38.w,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Icon(icon, color: iconColor, size: 20.sp),
      ),
      title: Text(
        title,
        style: TextStyle(color: AppColors.textPrimary, fontSize: 13.sp, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: AppColors.textHint, fontSize: 11.sp),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}
