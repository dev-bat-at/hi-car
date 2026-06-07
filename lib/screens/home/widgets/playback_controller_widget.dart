import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
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
                      subLabel: hasGreeting
                          ? audioProvider.activeGreeting!.title
                          : 'Chưa cài đặt',
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
                      subLabel: hasGoodbye
                          ? audioProvider.activeGoodbye!.title
                          : 'Chưa cài đặt',
                      icon: Icons.directions_car_rounded,
                      color: AppColors.success,
                      isEnabled: hasGoodbye,
                      onTap: () => audioProvider.playGoodbyeViaNative(),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              _ScaleButton(
                onTap: () => audioProvider.stopNativeAudio(),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.r),
                  child: Material(
                    color: AppColors.cardElevated.withBlue(80),
                    child: InkWell(
                      onTap: () => audioProvider.stopNativeAudio(),
                      splashColor: AppColors.primary.withOpacity(0.3),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        decoration: BoxDecoration(
                          border:
                              Border.all(color: AppColors.primary, width: 1.5),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: EdgeInsets.all(4.w),
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.power_settings_new_rounded,
                                  color: Colors.white, size: 16.sp),
                            ),
                            SizedBox(width: 10.w),
                            Text(
                              'DỪNG PHÁT NGAY LẬP TỨC',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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
    return _ScaleButton(
      onTap: isEnabled ? onTap : null,
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.4,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12.r),
          child: Material(
            color: AppColors.cardElevated,
            child: InkWell(
              onTap: isEnabled ? onTap : null,
              splashColor: color.withOpacity(0.3),
              highlightColor: color.withOpacity(0.1),
              child: Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: EdgeInsets.all(8.w),
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, color: Colors.white, size: 20.sp),
                        ),
                        Icon(
                          Icons.play_circle_filled_rounded,
                          color: color,
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
                        fontWeight: FontWeight.w700,
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
          ),
        ),
      ),
    );
  }
}

class _ScaleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _ScaleButton({required this.child, this.onTap});

  @override
  State<_ScaleButton> createState() => _ScaleButtonState();
}

class _ScaleButtonState extends State<_ScaleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (widget.onTap != null) {
          _controller.forward().then((_) => _controller.reverse());
          HapticFeedback.lightImpact();
          widget.onTap!();
        }
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              foregroundDecoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05 * _controller.value),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: child,
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}
