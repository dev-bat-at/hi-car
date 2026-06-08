import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_colors.dart';
import '../../providers/settings_provider.dart';

class ConnectionModeScreen extends StatefulWidget {
  final bool isFromSettings;

  const ConnectionModeScreen({
    super.key,
    this.isFromSettings = false,
  });

  @override
  State<ConnectionModeScreen> createState() => _ConnectionModeScreenState();
}

class _ConnectionModeScreenState extends State<ConnectionModeScreen> {
  String? _selectedMode;

  @override
  void initState() {
    super.initState();
    // Initialize with current mode
    _selectedMode = context.read<SettingsProvider>().pendingConnectionMode ??
        context.read<SettingsProvider>().connectionMode;
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final activeMode = _selectedMode ?? settings.connectionMode;

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          context.read<SettingsProvider>().cancelPendingSettings();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          leading: widget.isFromSettings
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_ios_rounded),
                  onPressed: () => context.pop(),
                )
              : null,
          title: Text(
            'Chọn Chế Độ Kết Nối',
            style: TextStyle(fontSize: 16.sp),
          ),
          centerTitle: true,
          automaticallyImplyLeading: widget.isFromSettings,
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
                        'Hệ thống cần biết cách bạn kết nối với xe để tối ưu hóa việc phát lời chào. (Thay đổi sẽ được áp dụng sau khi bạn hoàn tất cấu hình).',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14.sp,
                        ),
                      ),
                      SizedBox(height: 24.h),
                      _buildModeCard(
                        context,
                        mode: 'phone_bluetooth',
                        title: 'Điện thoại + Bluetooth',
                        description:
                            'Tự động phát lời chào khi điện thoại kết nối Bluetooth với xe.',
                        icon: Icons.bluetooth_rounded,
                        activeMode: activeMode,
                        onTap: () =>
                            setState(() => _selectedMode = 'phone_bluetooth'),
                      ),
                      SizedBox(height: 16.h),
                      _buildModeCard(
                        context,
                        mode: 'phone_android_auto',
                        title: 'Điện thoại + Android Auto',
                        description:
                            'Chỉ tự động phát khi xe kích hoạt màn hình Android Auto.',
                        icon: Icons.directions_car_filled_rounded,
                        activeMode: activeMode,
                        onTap: () => setState(
                            () => _selectedMode = 'phone_android_auto'),
                      ),
                      SizedBox(height: 16.h),
                      _buildModeCard(
                        context,
                        mode: 'android_screen_mode',
                        title: 'Màn hình Android độ',
                        description:
                            'Cài trên màn hình xe. Tự mở app khi nổ máy và tự ẩn sau khi phát nhạc xong.',
                        icon: Icons.developer_board_rounded,
                        activeMode: activeMode,
                        onTap: () => setState(
                            () => _selectedMode = 'android_screen_mode'),
                      ),
                      SizedBox(height: 16.h),
                      _buildModeCard(
                        context,
                        mode: 'android_box_mode',
                        title: 'Android Box',
                        description:
                            'Cài trên cục Box. Tự phát nhạc ngầm ngay khi Box khởi động.',
                        icon: Icons.settings_input_hdmi_rounded,
                        activeMode: activeMode,
                        onTap: () =>
                            setState(() => _selectedMode = 'android_box_mode'),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(16.w),
                child: _GlowButton(
                  label: 'TIẾP TỤC',
                  onTap: () async {
                    if (_selectedMode != null) {
                      final settings = context.read<SettingsProvider>();
                      await settings.setConnectionMode(_selectedMode!);
                      // 🟢 Lưu ngay lập tức thay vì đợi đến cuối
                      await settings.commitSettings();
                    }

                    if (!mounted) return;
                    if (widget.isFromSettings) {
                      context.push('/permission-config?fromSettings=true');
                    } else {
                      context.push('/permission-config');
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeCard(
    BuildContext context, {
    required String mode,
    required String title,
    required String description,
    required IconData icon,
    required String activeMode,
    required VoidCallback onTap,
  }) {
    final isSelected = mode == activeMode;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brandBackground : AppColors.card,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: 2.w,
          ),
          boxShadow: null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color:
                    isSelected ? AppColors.primary : AppColors.brandBackground,
                shape: BoxShape.circle,
                border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 20.sp,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    description,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12.sp,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: AppColors.primary,
                size: 20.sp,
              ),
          ],
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
        height: isLandscape ? 44.h : 56.h, // 🟢 Giảm chiều cao khi xoay ngang
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
