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

        final isXiaomi = permissionProvider.isXiaomi;

        final permissionList = <Widget>[];

        // 1. Bluetooth (for connectivity)
        if (mode == 'phone_bluetooth') {
          permissionList.add(
            _PermissionRow(
              label: 'Quyền Bluetooth Connect',
              description: 'Để tự động nhận diện xe và phát tiếng chào.',
              isGranted: btGranted,
              onTap: () => permissionProvider.requestBluetoothPermissions(),
            ),
          );
          permissionList.add(Divider(color: AppColors.divider, height: 16.h));
        }

        // 2. Notification (CRITICAL for Service)
        permissionList.add(
          _PermissionRow(
            label: 'Quyền Thông báo',
            description: 'Bắt buộc để duy trì hệ thống chạy ngầm ổn định.',
            isGranted: notifGranted,
            onTap: () => permissionProvider.requestNotificationPermission(),
          ),
        );
        permissionList.add(Divider(color: AppColors.divider, height: 16.h));

        // 3. Battery Optimization (CRITICAL for background Isolate)
        permissionList.add(
          _PermissionRow(
            label: 'Bỏ tối ưu hóa Pin',
            description: 'Để hệ thống không bị đóng khi bạn thoát ứng dụng.',
            isGranted: batteryGranted,
            onTap: () =>
                permissionProvider.requestBatteryOptimizationPermission(),
          ),
        );
        permissionList.add(Divider(color: AppColors.divider, height: 16.h));

        // 4. Overlay
        permissionList.add(
          _PermissionRow(
            label: 'Quyền cửa sổ nổi (Overlay)',
            description: 'Để hiển thị bong bóng trợ lý trên các app khác.',
            isGranted: overlayGranted,
            onTap: () => overlayProvider.requestPermission(),
          ),
        );

        // 5. Android Box Specific: Launch on Boot / Autostart
        if (mode == 'android_screen_box') {
          permissionList.add(Divider(color: AppColors.divider, height: 16.h));
          permissionList.add(
            _PermissionRow(
              label: 'Quyền Tự khởi động (Autostart)',
              description: 'Để hệ thống tự chào ngay khi màn hình vừa bật.',
              isGranted: false, // Hard to detect, show as guidance
              onTap: () => permissionProvider.openSettings(),
              actionLabel: 'Cấp quyền',
            ),
          );
        }

        // 6. Xiaomi Specific
        if (isXiaomi) {
          permissionList.add(Divider(color: AppColors.divider, height: 16.h));
          permissionList.add(
            _PermissionRow(
              label: 'Cửa sổ Pop-up khi chạy nền (MIUI)',
              description:
                  'Xiaomi cần quyền này để bong bóng có thể mở được App.',
              isGranted: false, // We can't detect this easily, show as action
              onTap: () => permissionProvider.openSettings(),
              actionLabel: 'Đi tới cài đặt',
            ),
          );
        }

        return Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: AppColors.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.security,
                          color: AppColors.primary, size: 20.sp),
                      SizedBox(width: 8.w),
                      Text(
                        'Cấp quyền hoạt động',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  _HelpButton(),
                ],
              ),
              SizedBox(height: 16.h),
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
  final String? description;
  final bool isGranted;
  final VoidCallback onTap;
  final String? actionLabel;

  const _PermissionRow({
    required this.label,
    this.description,
    required this.isGranted,
    required this.onTap,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (description != null) ...[
                    SizedBox(height: 2.h),
                    Text(
                      description!,
                      style: TextStyle(
                        color: AppColors.textHint,
                        fontSize: 10.sp,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(width: 8.w),
            isGranted
                ? Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_rounded,
                            color: AppColors.success, size: 12.sp),
                        SizedBox(width: 4.w),
                        Text(
                          'Đã cấp',
                          style: TextStyle(
                            color: AppColors.success,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )
                : GestureDetector(
                    onTap: onTap,
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8.r),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        actionLabel ?? 'Cấp quyền',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
          ],
        ),
      ],
    );
  }
}

class _HelpButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.help_outline_rounded,
          color: AppColors.textHint, size: 20.sp),
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.card,
            title: const Text('Hướng dẫn cấp quyền'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHelpItem(
                    title: '1. Quyền Thông báo',
                    desc:
                        'Android cần quyền này để giữ cho dịch vụ trợ lý không bị hệ thống tự động tắt khi bạn thoát app.',
                  ),
                  _buildHelpItem(
                    title: '2. Tắt tối ưu hóa pin',
                    desc:
                        'Giúp ứng dụng có thể xử lý các lệnh từ bong bóng nổi ngay cả khi màn hình đang tắt hoặc app đang ở chế độ chờ.',
                  ),
                  _buildHelpItem(
                    title: '3. Quyền Nút nổi (Overlay)',
                    desc:
                        'Để biểu tượng trợ lý có thể hiển thị đè lên các ứng dụng khác như Bản đồ, Youtube...',
                  ),
                  _buildHelpItem(
                    title: '4. Quyền Tự khởi động (Autostart)',
                    desc:
                        'Dành cho màn hình xe / Android Box: Cho phép ứng dụng tự động chạy và phát tiếng chào ngay khi thiết bị vừa khởi động.',
                  ),
                  _buildHelpItem(
                    title: '5. Lưu ý cho máy Xiaomi/Redmi',
                    desc:
                        'Bạn cần vào: Cài đặt ứng dụng -> Quyền khác -> Bật "Hiển thị cửa sổ pop-up khi chạy nền" để các nút bấm hoạt động được.',
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Đã hiểu'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHelpItem({required String title, required String desc}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: AppColors.primary)),
          SizedBox(height: 4.h),
          Text(desc,
              style:
                  TextStyle(fontSize: 12.sp, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
