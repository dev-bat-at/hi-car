import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../core/app_colors.dart';
import '../../../providers/audio_provider.dart';

class PlaybackControllerWidget extends StatelessWidget {
  const PlaybackControllerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioProvider>(
      builder: (context, audioProvider, _) {
        final hasGreeting = audioProvider.activeGreeting != null;
        final hasGoodbye = audioProvider.activeGoodbye != null;

        return Container(
          margin: EdgeInsets.symmetric(horizontal: 20.w),
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.settings_remote_rounded,
                    color: AppColors.primary,
                    size: 18.sp,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'Bộ điều khiển hệ thống xe',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(
                    child: _ControllerButton(
                      label: 'Phát lời chào',
                      subLabel: hasGreeting ? audioProvider.activeGreeting!.title : 'Chưa cài đặt',
                      icon: Icons.waving_hand_rounded,
                      color: AppColors.primary,
                      isEnabled: hasGreeting,
                      onTap: () => audioProvider.playGreetingViaNative(),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _ControllerButton(
                      label: 'Phát tạm biệt',
                      subLabel: hasGoodbye ? audioProvider.activeGoodbye!.title : 'Chưa cài đặt',
                      icon: Icons.directions_car_rounded,
                      color: const Color(0xFF00E676),
                      isEnabled: hasGoodbye,
                      onTap: () => audioProvider.playGoodbyeViaNative(),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              GestureDetector(
                onTap: () => audioProvider.stopNativeAudio(),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: AppColors.error.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.stop_circle_rounded, color: AppColors.error, size: 18.sp),
                      SizedBox(width: 8.w),
                      Text(
                        'DỪNG PHÁT NGAY LẬP TỨC',
                        style: TextStyle(
                          color: AppColors.error,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ControllerButton extends StatelessWidget {
  final String label;
  final String subLabel;
  final IconData icon;
  final Color color;
  final bool isEnabled;
  final VoidCallback onTap;

  const _ControllerButton({
    required this.label,
    required this.subLabel,
    required this.icon,
    required this.color,
    required this.isEnabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.4,
        child: Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: AppColors.cardElevated,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: color, size: 24.sp),
                  Icon(
                    Icons.play_circle_outline_rounded,
                    color: color.withOpacity(0.8),
                    size: 18.sp,
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Text(
                label,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                subLabel,
                style: TextStyle(
                  color: AppColors.textHint,
                  fontSize: 10.sp,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
