import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_colors.dart';
import '../../core/utils/ui_utils.dart';
import '../../providers/auth_provider.dart';
import '../../providers/audio_provider.dart';
import '../../providers/settings_provider.dart';
import '../../core/logger.dart';
import 'package:intl/intl.dart';

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
        child: OrientationBuilder(
          builder: (context, orientation) {
            final isLandscape = orientation == Orientation.landscape;

            if (isLandscape) {
              return SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cột trái
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle('CHỨC NĂNG HỆ THỐNG'),
                            _SettingsTile(
                              icon: Icons.bolt_rounded,
                              iconColor: AppColors.primary,
                              title: 'Tạo Giọng Nói AI',
                              subtitle: 'Soạn lời chào cá nhân hóa cho xe',
                              onTap: () => context.push('/gen-audio'),
                            ),
                            _buildSectionTitle('CHẾ ĐỘ KẾT NỐI XE'),
                            _buildConnectionModeCard(context, settings),
                            _buildSectionTitle('CẤU HÌNH TỰ ĐỘNG PHÁT'),
                            _SettingsSwitchTile(
                              icon: Icons.power_rounded,
                              iconColor: AppColors.success,
                              title: 'Tự động phát lời chào',
                              subtitle: 'Phát âm thanh tự động',
                              value: settings.autoPlayEnabled,
                              onChanged: (val) => settings.setAutoPlay(val),
                            ),
                          ],
                        ),
                      ),
                      // Cột phải
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle('HỖ TRỢ & TÀI KHOẢN'),
                            _SettingsTile(
                              icon: Icons.bug_report_rounded,
                              iconColor: AppColors.warning,
                              title: 'Báo cáo lỗi (Gửi Bug)',
                              subtitle: 'Gửi logs lỗi hệ thống',
                              onTap: () => _showBugReportDialog(context),
                            ),
                            _SettingsTile(
                              icon: Icons.logout_rounded,
                              iconColor: AppColors.textHint,
                              title: 'Đăng xuất tài khoản',
                              subtitle: 'Thoát hệ thống',
                              onTap: () => _showLogoutConfirm(context, auth),
                            ),
                            _buildSectionTitle('CÀI ĐẶT NÂNG CAO'),
                            _SettingsTile(
                              icon: Icons.security_rounded,
                              iconColor: AppColors.info,
                              title: 'Quyền Hệ Thống',
                              subtitle: 'Cấp lại quyền ứng dụng',
                              onTap: () => context
                                  .push('/permission-config?fromSettings=true'),
                            ),
                            _SettingsSwitchTile(
                              icon: Icons.bug_report_rounded,
                              iconColor: Colors.amber,
                              title: 'Chế độ Demo (Beta)',
                              subtitle: 'Thử nghiệm giọng mặc định',
                              value: settings.isBetaMode,
                              onChanged: (v) {
                                settings.setBetaMode(v);
                                context.read<AudioProvider>().setBetaMode(v);
                              },
                            ),
                            SizedBox(height: 32.h),
                            Center(
                              child: Text(
                                'Giọng Thương Gia v1.0.0',
                                style: TextStyle(
                                  color: AppColors.textHint,
                                  fontSize: 9.sp,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Dạng dọc mặc định
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 16.h),
                  _buildSectionTitle('CHỨC NĂNG HỆ THỐNG'),
                  _SettingsTile(
                    icon: Icons.bolt_rounded,
                    iconColor: AppColors.primary,
                    title: 'Tạo Giọng Nói AI',
                    subtitle: 'Soạn lời chào cá nhân hóa cho xe',
                    onTap: () => context.push('/gen-audio'),
                  ),
                  _buildSectionTitle('CHẾ ĐỘ KẾT NỐI XE'),
                  _buildConnectionModeCard(context, settings),
                  _buildSectionTitle('CẤU HÌNH TỰ ĐỘNG PHÁT'),
                  _SettingsSwitchTile(
                    icon: Icons.power_rounded,
                    iconColor: AppColors.success,
                    title: 'Tự động phát lời chào',
                    subtitle:
                        'Kích hoạt phát âm thanh tự động theo chế độ kết nối',
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
                  _SettingsSwitchTile(
                    icon: Icons.bug_report_rounded,
                    iconColor: Colors.amber,
                    title: 'Chế độ Demo (Beta)',
                    subtitle: 'Sử dụng thử nghiệm giọng mặc định',
                    value: settings.isBetaMode,
                    onChanged: (v) {
                      settings.setBetaMode(v);
                      context.read<AudioProvider>().setBetaMode(v);
                    },
                  ),
                  SizedBox(height: 20.h),
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
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(left: 16.w, top: 18.h, bottom: 6.h),
      child: Text(
        title,
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 10.sp,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildConnectionModeCard(
      BuildContext context, SettingsProvider settings) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColors.primary.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
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
                size: 18.sp,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chế độ hiện tại',
                    style: TextStyle(color: AppColors.textHint, fontSize: 9.sp),
                  ),
                  Text(
                    settings.connectionMode == 'phone_bluetooth'
                        ? 'Điện thoại + Bluetooth'
                        : (settings.connectionMode == 'android_screen_mode'
                            ? 'Màn hình Android'
                            : (settings.connectionMode == 'android_box_mode'
                                ? 'Android Box'
                                : 'Android Auto')),
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ActionChip(
              label: const Text('ĐỔI'),
              onPressed: () =>
                  context.push('/connection-mode?fromSettings=true'),
              backgroundColor: AppColors.primary,
              side: BorderSide.none,
              labelStyle: TextStyle(
                color: Colors.white,
                fontSize: 9.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Chỉ những type này mới được coi là "lỗi thật" để gửi báo cáo.
  static const _errorTypes = {
    'native_error',
    'sync_error',
    'playback_error',
    'native_playback_error',
    'network_error',
    'native_warning',
  };

  void _showBugReportDialog(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    showDialog(
      context: context,
      builder: (context) => ListenableBuilder(
        listenable: AppLogger.instance,
        builder: (context, _) {
          // Lọc: chỉ hiển thị log lỗi thật — bỏ các hành động bình thường
          final logs = AppLogger.instance.logs
              .where((l) => _errorTypes.contains(l.type ?? ''))
              .toList();

          return AlertDialog(
            backgroundColor: AppColors.cardElevated,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r)),
            insetPadding: EdgeInsets.symmetric(
                horizontal: isLandscape ? 140.w : 24.w, vertical: 20.h),
            contentPadding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
            titlePadding: EdgeInsets.fromLTRB(16.w, 16.h, 8.w, 0),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    'Lịch sử lỗi hệ thống',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                if (logs.isNotEmpty)
                  TextButton(
                    onPressed: () => AppLogger.instance.clear(),
                    child: Text('Xóa hết',
                        style:
                            TextStyle(color: AppColors.error, fontSize: 10.sp)),
                  ),
              ],
            ),
            content: Container(
              width: isLandscape ? 0.45.sw : double.maxFinite,
              constraints: BoxConstraints(maxHeight: 300.h),
              child: logs.isEmpty
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_outline_rounded,
                            color: AppColors.success, size: 48.sp),
                        SizedBox(height: 16.h),
                        Text(
                          'Hiện tại chưa ghi nhận lỗi nào.',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 13.sp),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: logs.length,
                      separatorBuilder: (_, __) =>
                          Divider(color: AppColors.border, height: 8.h),
                      itemBuilder: (context, index) {
                        final log = logs[index];
                        final timeStr =
                            DateFormat('HH:mm:ss').format(log.timestamp);

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 6.w, vertical: 2.h),
                                  decoration: BoxDecoration(
                                    color:
                                        _getLogColor(log.type).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4.r),
                                  ),
                                  child: Text(
                                    log.type?.toUpperCase() ?? 'INFO',
                                    style: TextStyle(
                                      color: _getLogColor(log.type),
                                      fontSize: 9.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  timeStr,
                                  style: TextStyle(
                                      color: AppColors.textHint,
                                      fontSize: 10.sp),
                                ),
                              ],
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              log.message,
                              style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 12.sp),
                            ),
                            SizedBox(height: 8.h),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton.icon(
                                onPressed: () => _sendLog(context, log),
                                icon: Icon(Icons.send_rounded, size: 12.sp),
                                label: Text('Gửi báo cáo',
                                    style: TextStyle(fontSize: 11.sp)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 12.w, vertical: 0),
                                  minimumSize: Size(0, 28.h),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8.r)),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Đóng',
                    style: TextStyle(color: AppColors.textHint)),
              ),
            ],
          );
        },
      ),
    );
  }

  Color _getLogColor(String? type) {
    switch (type) {
      case 'native_error':
      case 'network_error':
      case 'native_playback_error':
        return AppColors.error;
      case 'sync_error':
      case 'native_warning':
        return AppColors.warning;
      case 'playback_error':
        return Colors.orange;
      default:
        return AppColors.info;
    }
  }

  Future<void> _sendLog(BuildContext context, AppLog log) async {
    EasyLoading.show(status: 'Đang gửi...');
    try {
      await AppLogger.instance.sendReport(log);
      EasyLoading.dismiss();
      if (context.mounted) {
        UiUtils.showSuccess(context, 'Đã gửi báo cáo lỗi thành công!');
      }
    } catch (e) {
      EasyLoading.dismiss();
      if (context.mounted) {
        UiUtils.showError(context, 'Lỗi khi gửi: $e');
      }
    }
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
          activeColor: Colors.white,
          activeTrackColor: AppColors.primary,
          inactiveThumbColor: AppColors.textHint,
          inactiveTrackColor: AppColors.cardElevated,
        ),
      ),
    );
  }
}
