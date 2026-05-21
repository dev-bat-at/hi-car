import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hi_car/providers/permission_provider.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/audio_provider.dart';
import '../../providers/overlay_provider.dart';
import 'widgets/audio_list_widget.dart';
import 'widgets/bluetooth_panel_widget.dart';
import 'widgets/permission_status_widget.dart';
import 'widgets/playback_controller_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Check overlay state and other permissions on screen startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAll();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final overlayProvider = context.read<OverlayProvider>();
    if (state == AppLifecycleState.resumed) {
      _checkAll();
      // Hide bubble when user opens the app
      overlayProvider.hideOverlay();
    } else if (state == AppLifecycleState.paused) {
      // Show bubble when user goes home or backs out
      overlayProvider.showOverlay();
    }
  }

  void _checkAll() {
    if (mounted) {
      context.read<PermissionProvider>().checkAllPermissions();
      context.read<OverlayProvider>().checkPermission();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final audioProvider = context.watch<AudioProvider>();
    final overlayProvider = context.watch<OverlayProvider>();

    final user = authProvider.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32.w,
              height: 32.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 1.5),
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/logo_thuongia.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(width: 10.w),
            Text(
              'Giọng Thương Gia',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        actions: [
          // Dynamic Sync Button
          _SyncButton(audioProvider: audioProvider),
          IconButton(
            icon: Icon(Icons.settings_rounded,
                color: AppColors.primary, size: 22.sp),
            onPressed: () => context.push('/settings'),
          ),
          SizedBox(width: 8.w),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => audioProvider.syncFromServer(),
          color: AppColors.primary,
          backgroundColor: AppColors.card,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 16.h),

                // User profile card
                if (user != null) _UserProfileCard(user: user),

                SizedBox(height: 16.h),

                // Floating bubble status toggle
                _FloatingBubbleToggleCard(overlayProvider: overlayProvider),

                SizedBox(height: 16.h),

                // Permission status panel
                const PermissionStatusWidget(),

                SizedBox(height: 16.h),

                // Bluetooth auto-play trigger config panel
                const BluetoothPanelWidget(),

                SizedBox(height: 16.h),

                // Audio controller buttons
                const PlaybackControllerWidget(),

                SizedBox(height: 24.h),

                // Audio list
                const AudioListWidget(),

                SizedBox(height: 40.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SyncButton extends StatelessWidget {
  final AudioProvider audioProvider;

  const _SyncButton({required this.audioProvider});

  @override
  Widget build(BuildContext context) {
    if (audioProvider.isSyncing) {
      return Container(
        margin: EdgeInsets.only(right: 8.w),
        width: 32.w,
        height: 32.w,
        padding: EdgeInsets.all(6.w),
        child: const CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation(AppColors.primary),
        ),
      );
    }

    return IconButton(
      icon: Icon(Icons.sync_rounded, color: AppColors.primary, size: 22.sp),
      onPressed: () => audioProvider.syncFromServer(),
      tooltip: 'Đồng bộ dữ liệu từ server',
    );
  }
}

class _UserProfileCard extends StatelessWidget {
  final dynamic user;

  const _UserProfileCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48.w,
            height: 48.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withOpacity(0.1),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Icon(
              Icons.person_rounded,
              color: AppColors.primary,
              size: 24.sp,
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'Biển số: ${user.licensePlate}',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Row(
              children: [
                Icon(Icons.bolt_rounded, color: AppColors.primary, size: 14.sp),
                SizedBox(width: 4.w),
                Text(
                  '${user.generateCredits} lượt',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingBubbleToggleCard extends StatelessWidget {
  final OverlayProvider overlayProvider;

  const _FloatingBubbleToggleCard({required this.overlayProvider});

  @override
  Widget build(BuildContext context) {
    final isEnabled = overlayProvider.isBubbleEnabled;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: isEnabled
                  ? AppColors.primary.withOpacity(0.15)
                  : AppColors.textHint.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              Icons.widgets_rounded,
              color: isEnabled ? AppColors.primary : AppColors.textHint,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bong bóng trợ lý xe (Overlay)',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  isEnabled
                      ? 'Đang bật (tự động hiện khi thoát app)'
                      : 'Đang tắt hoàn toàn',
                  style: TextStyle(
                    color: isEnabled ? AppColors.primary : AppColors.textHint,
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isEnabled,
            onChanged: (value) async {
              await overlayProvider.setBubbleEnabled(value);
            },
          ),
        ],
      ),
    );
  }
}
