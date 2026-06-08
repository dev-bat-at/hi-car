import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_colors.dart';
import '../../providers/permission_provider.dart';
import '../../providers/settings_provider.dart';

class PermissionConfigScreen extends StatefulWidget {
  final bool isFromSettings;

  const PermissionConfigScreen({
    super.key,
    this.isFromSettings = false,
  });

  @override
  State<PermissionConfigScreen> createState() => _PermissionConfigScreenState();
}

class _PermissionConfigScreenState extends State<PermissionConfigScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PermissionProvider>().checkAllPermissions();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<PermissionProvider>().checkAllPermissions();
    }
  }

  @override
  Widget build(BuildContext context) {
    final permissionProvider = context.watch<PermissionProvider>();
    final settingsProvider = context.watch<SettingsProvider>();
    final status = permissionProvider.status;
    final activeMode = settingsProvider.pendingConnectionMode ??
        settingsProvider.connectionMode;
    final isBoxMode = activeMode == 'android_screen_box';
    final isXiaomi = permissionProvider.isXiaomi;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Cấu Hình Quyền Hệ Thống',
          style: TextStyle(fontSize: 16.sp),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Để ứng dụng hoạt động ổn định và tự động, vui lòng cấp các quyền cần thiết bên dưới.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14.sp,
                      ),
                    ),
                    SizedBox(height: 24.h),
                    _buildPermissionTile(
                      title: 'Bluetooth',
                      subtitle:
                          'Cần thiết để nhận diện khi điện thoại kết nối với xe.',
                      icon: Icons.bluetooth_rounded,
                      value: status.bluetoothConnect,
                      onChanged: (val) {
                        if (val) {
                          permissionProvider.requestBluetoothPermissions();
                        } else {
                          _showDisableInfo(context);
                        }
                      },
                    ),
                    _buildPermissionTile(
                      title: 'Thông báo',
                      subtitle:
                          'Hiển thị trạng thái kết nối và điều khiển nhanh.',
                      icon: Icons.notifications_active_rounded,
                      value: status.notification,
                      onChanged: (val) {
                        if (val) {
                          permissionProvider.requestNotificationPermission();
                        } else {
                          _showDisableInfo(context);
                        }
                      },
                    ),
                    _buildPermissionTile(
                      title: 'Hiển thị trên ứng dụng khác',
                      subtitle:
                          'Hiển thị bong bóng điều khiển khi bạn đang dùng bản đồ.',
                      icon: Icons.layers_rounded,
                      value: status.overlay,
                      onChanged: (val) {
                        if (val) {
                          permissionProvider.requestOverlayPermission();
                        } else {
                          _showDisableInfo(context);
                        }
                      },
                    ),
                    _buildPermissionTile(
                      title: 'Bỏ qua tối ưu pin',
                      subtitle:
                          'Giúp ứng dụng không bị hệ thống tự động tắt khi chạy ngầm.',
                      icon: Icons.battery_charging_full_rounded,
                      value: status.batteryOptimization,
                      onChanged: (val) {
                        if (val) {
                          permissionProvider
                              .requestBatteryOptimizationPermission();
                        } else {
                          _showDisableInfo(context);
                        }
                      },
                    ),
                    if (isBoxMode)
                      _buildPermissionTile(
                        title: 'Tự khởi động (Autostart)',
                        subtitle:
                            'Cho phép app tự chào và hiện lên khi vừa bật màn hình xe.',
                        icon: Icons.auto_mode_rounded,
                        value: false, // System setting dependent
                        onChanged: (val) {
                          permissionProvider.openSettings();
                        },
                        trailingText: 'CÀI ĐẶT',
                      ),
                    if (isXiaomi)
                      _buildPermissionTile(
                        title: 'Hiển thị Pop-up nền (MIUI)',
                        subtitle:
                            'Bắt buộc để bong bóng có thể mở được App trên Xiaomi.',
                        icon: Icons.app_registration_rounded,
                        value: false, // System setting dependent
                        onChanged: (val) {
                          permissionProvider.openSettings();
                        },
                        trailingText: 'CÀI ĐẶT',
                      ),
                    _buildPermissionTile(
                      title: 'Chạy ngầm hệ thống',
                      subtitle:
                          'Giữ cho trợ lý luôn sẵn sàng khi bạn nổ máy xe.',
                      icon: Icons.bolt_rounded,
                      value: status.bootComplete,
                      onChanged: (val) {
                        if (val) {
                          _showKeepAliveInfo(context);
                        } else {
                          _showDisableInfo(context);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16.w),
              child: _GlowButton(
                label: widget.isFromSettings
                    ? 'HOÀN TẤT & KHỞI ĐỘNG LẠI'
                    : 'TIẾP TỤC',
                onTap: () {
                  if (widget.isFromSettings) {
                    _handleRestart(context);
                  } else {
                    context.push('/login');
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showKeepAliveInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardElevated,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text(
          'Duy trì hoạt động',
          style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15.sp,
              fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Hệ thống đã được thiết lập để tự khởi động cùng xe. Để đạt hiệu quả tốt nhất, bạn nên cấp thêm quyền "Bỏ qua tối ưu pin".',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ĐÃ HIỂU',
                style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  void _showDisableInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardElevated,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text(
          'Thông báo',
          style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15.sp,
              fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Để tắt quyền này, vui lòng vào Cài đặt của hệ thống Android để thực hiện.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ĐÃ HIỂU',
                style: TextStyle(color: AppColors.textHint)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<PermissionProvider>().openSettings();
            },
            child: const Text('VÀO CÀI ĐẶT',
                style: TextStyle(
                    color: AppColors.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _handleRestart(BuildContext context) async {
    // Commit the settings (especially pending connection mode)
    await context.read<SettingsProvider>().commitSettings();

    if (!mounted) return;

    // Show a loading or success message before "restarting"
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardElevated,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 20.h),
            Text(
              'Đang chuẩn hóa hệ thống...',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 14.sp),
            ),
            SizedBox(height: 8.h),
            Text(
              'Ứng dụng sẽ khởi động lại để áp dụng cài đặt mới.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12.sp),
            ),
          ],
        ),
      ),
    );

    // Simulate restart by going back to splash and clearing stack
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        context.go('/');
      }
    });
  }

  Widget _buildPermissionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
    String? trailingText,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.border, width: 1.w),
      ),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(10.w),
          decoration: BoxDecoration(
            color: value ? AppColors.primary : AppColors.brandBackground,
            shape: BoxShape.circle,
            border:
                Border.all(color: value ? AppColors.primary : AppColors.border),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 18.sp,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11.sp,
          ),
        ),
        trailing: trailingText != null
            ? TextButton(
                onPressed: () => onChanged(true),
                child: Text(
                  trailingText,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : Switch(
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

class _GlowButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _GlowButton({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: isLandscape ? 44.h : 56.h, // 🟢 Giảm khi xoay ngang
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: isLandscape ? 13.sp : 15.sp, // 🟢 Giảm font size nhẹ
              fontWeight: FontWeight.bold,
              letterSpacing: 2.0,
            ),
          ),
        ),
      ),
    );
  }
}
