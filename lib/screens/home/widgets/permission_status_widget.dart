import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../core/app_colors.dart';
import '../../../providers/permission_provider.dart';
import '../../../providers/overlay_provider.dart';
import '../../../providers/settings_provider.dart';

class PermissionStatusWidget extends StatelessWidget {
  const PermissionStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final mode = settings.connectionMode;

    return Consumer2<PermissionProvider, OverlayProvider>(
      builder: (context, permissionProvider, overlayProvider, _) {
        final btGranted = permissionProvider.status.bluetoothConnect;
        final notifGranted = permissionProvider.status.notification;
        final overlayGranted = overlayProvider.hasPermission;
        final batteryGranted = permissionProvider.status.batteryOptimization;

        final allGranted = permissionProvider.status.isGrantedForMode(mode);

        final permissionList = <Widget>[];

        if (mode == 'phone_bluetooth') {
          permissionList.add(
            _PermissionRow(
              label: 'Quyền Bluetooth Connect (Tự nhận diện xe)',
              isGranted: btGranted,
              onTap: () => permissionProvider.requestBluetoothPermissions(),
            ),
          );
        }

        if (mode == 'phone_bluetooth' ||
            mode == 'phone_android_auto' ||
            mode == 'android_screen_box') {
          if (permissionList.isNotEmpty) {
            permissionList.add(Divider(color: AppColors.divider, height: 16.h));
          }
          permissionList.add(
            _PermissionRow(
              label: 'Quyền Thông báo (Chạy nền không bị kill)',
              isGranted: notifGranted,
              onTap: () => permissionProvider.requestNotificationPermission(),
            ),
          );
        }

        if (mode == 'phone_bluetooth' ||
            mode == 'phone_android_auto' ||
            mode == 'android_screen_box') {
          if (permissionList.isNotEmpty) {
            permissionList.add(Divider(color: AppColors.divider, height: 16.h));
          }
          permissionList.add(
            _PermissionRow(
              label:
                  'Quyền hiển thị trên ứng dụng khác (Overlay, dùng cho bong bóng nổi)',
              isGranted: overlayGranted,
              onTap: () => overlayProvider.requestPermission(),
            ),
          );
        }

        if (mode == 'android_screen_box') {
          if (permissionList.isNotEmpty) {
            permissionList.add(Divider(color: AppColors.divider, height: 16.h));
          }
          permissionList.add(
            _PermissionRow(
              label: 'Quyền chạy ẩn không tối ưu pin (Ignore Battery)',
              isGranted: batteryGranted,
              onTap: () =>
                  permissionProvider.requestBatteryOptimizationPermission(),
            ),
          );
        }

        return Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: allGranted ? AppColors.success : AppColors.primary,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(6.w),
                    decoration: BoxDecoration(
                      color: allGranted ? AppColors.success : AppColors.warning,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      allGranted ? Icons.check : Icons.priority_high_rounded,
                      color: Colors.white,
                      size: 14.sp,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    allGranted
                        ? 'Hệ thống đã sẵn sàng'
                        : 'Cần cấp quyền hoạt động chính',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Text(
                'Overlay là quyền phụ, chỉ cần nếu muốn dùng bong bóng nổi.',
                style: TextStyle(
                  color: AppColors.textHint,
                  fontSize: 11.sp,
                ),
              ),
              SizedBox(height: 12.h),
              ...permissionList,
            ],
          ),
        );
      },
    );
  }
}

class _PermissionRow extends StatelessWidget {
  final String label;
  final bool isGranted;
  final VoidCallback onTap;

  const _PermissionRow({
    required this.label,
    required this.isGranted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12.sp,
            ),
          ),
        ),
        SizedBox(width: 8.w),
        isGranted
            ? Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.success,
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  'Đã cấp',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : GestureDetector(
                onTap: onTap,
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: AppColors.brandBackground,
                    borderRadius: BorderRadius.circular(6.r),
                    border: Border.all(color: AppColors.primary),
                  ),
                  child: Text(
                    'Cấp quyền',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
      ],
    );
  }
}
