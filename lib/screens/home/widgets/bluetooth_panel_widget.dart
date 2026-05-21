import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../core/app_colors.dart';
import '../../../providers/bluetooth_provider.dart';
import '../../../data/models/bluetooth_device_model.dart';
import '../../../core/constants.dart';

class BluetoothPanelWidget extends StatefulWidget {
  const BluetoothPanelWidget({super.key});

  @override
  State<BluetoothPanelWidget> createState() => _BluetoothPanelWidgetState();
}

class _BluetoothPanelWidgetState extends State<BluetoothPanelWidget> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<BluetoothProvider>(
      builder: (context, btProvider, _) {
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 20.w),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: btProvider.hasTargetDevice
                  ? AppColors.primary.withOpacity(0.4)
                  : AppColors.border,
            ),
            boxShadow: btProvider.hasTargetDevice
                ? [
                    BoxShadow(
                      color: AppColors.primaryGlow,
                      blurRadius: 12,
                      spreadRadius: 1,
                    )
                  ]
                : null,
          ),
          child: Column(
            children: [
              // Header
              InkWell(
                onTap: () => setState(() => _expanded = !_expanded),
                borderRadius: BorderRadius.circular(16.r),
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Row(
                    children: [
                      Container(
                        width: 40.w,
                        height: 40.w,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Icon(
                          Icons.bluetooth_rounded,
                          color: AppColors.primary,
                          size: 20.sp,
                        ),
                      ),
                      SizedBox(width: 14.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Thiết bị Bluetooth',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              btProvider.hasTargetDevice
                                  ? '${btProvider.targetDevice!.name} · ${btProvider.delaySeconds}s delay'
                                  : 'Chưa chọn thiết bị',
                              style: TextStyle(
                                color: btProvider.hasTargetDevice
                                    ? AppColors.primary
                                    : AppColors.textHint,
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        _expanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textSecondary,
                        size: 20.sp,
                      ),
                    ],
                  ),
                ),
              ),

              // Expanded content
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                child: _expanded
                    ? _BluetoothExpandedContent(provider: btProvider)
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BluetoothExpandedContent extends StatelessWidget {
  final BluetoothProvider provider;

  const _BluetoothExpandedContent({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(color: AppColors.divider, height: 1),
        SizedBox(height: 12.h),

        // Delay selector
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Độ trễ phát (giây)',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: 10.h),
              Row(
                children: AppConstants.delayOptions.map((delay) {
                  final selected = provider.delaySeconds == delay;
                  return Padding(
                    padding: EdgeInsets.only(right: 8.w),
                    child: GestureDetector(
                      onTap: () => provider.setDelaySeconds(delay),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: EdgeInsets.symmetric(
                            horizontal: 14.w, vertical: 8.h),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primary.withOpacity(0.15)
                              : AppColors.cardElevated,
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(
                            color: selected
                                ? AppColors.primary
                                : AppColors.border,
                          ),
                        ),
                        child: Text(
                          '${delay}s',
                          style: TextStyle(
                            color: selected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            fontSize: 13.sp,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),

        SizedBox(height: 16.h),

        // Refresh and device list
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Thiết bị đã ghép đôi',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              InkWell(
                onTap: () => provider.loadPairedDevices(),
                borderRadius: BorderRadius.circular(8.r),
                child: Padding(
                  padding: EdgeInsets.all(4.w),
                  child: provider.isLoading
                      ? SizedBox(
                          width: 14.w,
                          height: 14.w,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(AppColors.primary),
                          ),
                        )
                      : Icon(
                          Icons.refresh_rounded,
                          color: AppColors.primary,
                          size: 18.sp,
                        ),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 8.h),

        if (provider.pairedDevices.isEmpty && !provider.isLoading)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: GestureDetector(
              onTap: () => provider.loadPairedDevices(),
              child: Text(
                'Nhấn làm mới để tải danh sách',
                style: TextStyle(
                  color: AppColors.textHint,
                  fontSize: 12.sp,
                ),
              ),
            ),
          )
        else
          ...provider.pairedDevices.map((device) => _DeviceItem(
                device: device,
                onTap: () => provider.setTargetDevice(device),
                onClear: provider.hasTargetDevice &&
                        provider.targetDevice?.address == device.address
                    ? () => provider.clearTargetDevice()
                    : null,
              )),

        SizedBox(height: 12.h),
      ],
    );
  }
}

class _DeviceItem extends StatelessWidget {
  final BluetoothDeviceModel device;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _DeviceItem({
    required this.device,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        child: Row(
          children: [
            Icon(
              Icons.bluetooth_connected_rounded,
              color: device.isSelected ? AppColors.primary : AppColors.textHint,
              size: 18.sp,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device.name,
                    style: TextStyle(
                      color: device.isSelected
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontSize: 13.sp,
                      fontWeight: device.isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                  Text(
                    device.address,
                    style: TextStyle(
                      color: AppColors.textHint,
                      fontSize: 10.sp,
                    ),
                  ),
                ],
              ),
            ),
            if (device.isSelected) ...[
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: AppColors.primary.withOpacity(0.4)),
                ),
                child: Text(
                  'Đã chọn',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              GestureDetector(
                onTap: onClear,
                child: Icon(Icons.close_rounded,
                    color: AppColors.error, size: 16.sp),
              ),
            ],
          ],
        ),
      ),
    );
  }
}


