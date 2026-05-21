import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../core/app_colors.dart';
import '../../../providers/permission_provider.dart';
import '../../../providers/overlay_provider.dart';

class PermissionStatusWidget extends StatelessWidget {
  const PermissionStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<PermissionProvider, OverlayProvider>(
      builder: (context, permissionProvider, overlayProvider, _) {
        final btGranted = permissionProvider.status.bluetoothConnect;
        final notifGranted = permissionProvider.status.notification;
        final overlayGranted = overlayProvider.hasPermission;

        final allGranted = btGranted && notifGranted && overlayGranted;

        return Container(
          margin: EdgeInsets.symmetric(horizontal: 20.w),
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: allGranted
                  ? AppColors.success.withOpacity(0.3)
                  : AppColors.error.withOpacity(0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    allGranted ? Icons.check_circle_rounded : Icons.warning_rounded,
                    color: allGranted ? AppColors.success : AppColors.error,
                    size: 20.sp,
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    allGranted ? 'Hệ thống đã sẵn sàng' : 'Cần cấp quyền hoạt động',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              _PermissionRow(
                label: 'Quyền Bluetooth Connect (Tự nhận diện xe)',
                isGranted: btGranted,
                onTap: () => permissionProvider.requestBluetoothPermissions(),
              ),
              Divider(color: AppColors.divider, height: 16.h),
              _PermissionRow(
                label: 'Quyền Thông báo (Chạy nền không bị kill)',
                isGranted: notifGranted,
                onTap: () => permissionProvider.requestNotificationPermission(),
              ),
              Divider(color: AppColors.divider, height: 16.h),
              _PermissionRow(
                label: 'Quyền hiển thị trên ứng dụng khác (Overlay)',
                isGranted: overlayGranted,
                onTap: () => overlayProvider.requestPermission(),
              ),
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
                  color: AppColors.success.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  'Đã cấp',
                  style: TextStyle(
                    color: AppColors.success,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            : GestureDetector(
                onTap: onTap,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6.r),
                    border: Border.all(color: AppColors.primary.withOpacity(0.5)),
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
