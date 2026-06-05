import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hi_car/providers/permission_provider.dart';
import 'package:hi_car/providers/settings_provider.dart';
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
    if (state == AppLifecycleState.resumed) {
      _checkAll();

      final settings = context.read<SettingsProvider>();
      final audioProvider = context.read<AudioProvider>();
      // For Android Screen/Box mode, auto-play greeting on screen/app resume
      if (settings.connectionMode == 'android_screen_box' &&
          settings.autoPlayEnabled) {
        audioProvider.playGreetingViaNative();
      }
    }
  }

  void _checkAll() {
    if (mounted) {
      context.read<PermissionProvider>().checkAllPermissions();
      final overlayProvider = context.read<OverlayProvider>();
      overlayProvider.checkPermission();
      overlayProvider.syncOverlayState();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final audioProvider = context.watch<AudioProvider>();
    final overlayProvider = context.watch<OverlayProvider>();
    final settingsProvider = context.watch<SettingsProvider>();

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

                const _OverlayDebugCard(),

                SizedBox(height: 16.h),

                // Permission status panel
                const PermissionStatusWidget(),

                // Bluetooth auto-play trigger config panel
                if (settingsProvider.connectionMode !=
                    'android_screen_box') ...[
                  const BluetoothPanelWidget(),
                  SizedBox(height: 16.h),
                ],

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
    final hasPermission = overlayProvider.hasPermission;
    final isShowing = overlayProvider.isOverlayShowing;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
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
                          ? (!hasPermission
                              ? 'Đã bật nhưng còn thiếu quyền hiển thị nổi'
                              : (isShowing
                                  ? 'Đang hiển thị trên màn hình'
                                  : 'Đã bật, có thể hiện lại ngay trong app'))
                          : 'Đang tắt hoàn toàn',
                      style: TextStyle(
                        color: isEnabled && hasPermission
                            ? AppColors.primary
                            : AppColors.textHint,
                        fontSize: 11.sp,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: isEnabled,
                onChanged: (value) async {
                  final enabled = await overlayProvider.setBubbleEnabled(value);
                  if (!context.mounted) return;
                  if (value && !enabled) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Cần cấp quyền hiển thị nổi để bật bong bóng trợ lý.'),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
          if (isEnabled) ...[
            SizedBox(height: 12.h),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  if (!hasPermission) {
                    final granted = await overlayProvider.requestPermission();
                    if (!context.mounted) return;
                    if (!granted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Bạn cần cấp quyền hiển thị nổi để dùng bong bóng trợ lý.'),
                        ),
                      );
                    }
                    return;
                  }

                  if (isShowing) {
                    await overlayProvider.hideOverlay();
                  } else {
                    await overlayProvider.showOverlay();
                  }

                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isShowing
                            ? 'Đã ẩn bong bóng trợ lý.'
                            : 'Đã hiện lại bong bóng trợ lý.',
                      ),
                    ),
                  );
                },
                icon: Icon(
                  isShowing
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  size: 18.sp,
                ),
                label: Text(
                  !hasPermission
                      ? 'Cấp quyền bong bóng nổi'
                      : (isShowing
                          ? 'Ẩn bong bóng ngay'
                          : 'Hiện lại bong bóng'),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OverlayDebugCard extends StatelessWidget {
  const _OverlayDebugCard();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: OverlayDebugStore.notifier,
      builder: (context, message, _) {
        if (message == null || message.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: EdgeInsets.symmetric(horizontal: 20.w),
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: AppColors.error.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: AppColors.error.withOpacity(0.35),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.bug_report_rounded,
                    color: AppColors.error,
                    size: 18.sp,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'Lỗi bong bóng nổi',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => OverlayDebugStore.clear(),
                    child: const Text('Ẩn'),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Text(
                message,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11.sp,
                  height: 1.45,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
