import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_colors.dart';
import '../../core/utils/ui_utils.dart';
import '../../providers/auth_provider.dart';
import '../../providers/audio_provider.dart';
import '../../data/repositories/audio_repository.dart';
import '../../data/models/audio_model.dart';

class GenAudioScreen extends StatefulWidget {
  const GenAudioScreen({super.key});

  @override
  State<GenAudioScreen> createState() => _GenAudioScreenState();
}

class _GenAudioScreenState extends State<GenAudioScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _licensePlateController = TextEditingController();
  final _carBrandController = TextEditingController();
  String _selectedType = 'greeting'; // 'greeting' or 'goodbye'

  bool _isGenerating = false;
  AudioModel? _generatedAudio;

  @override
  void dispose() {
    _nameController.dispose();
    _licensePlateController.dispose();
    _carBrandController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final auth = context.read<AuthProvider>();
    if ((auth.user?.generateCredits ?? 0) <= 0) {
      _showLimitDialog();
      return;
    }

    setState(() {
      _isGenerating = true;
      _generatedAudio = null;
    });

    try {
      final audio = await AudioRepository.instance.generateAudio(
        ownerName: _nameController.text.trim(),
        licensePlate: _licensePlateController.text.trim(),
        carBrand: _carBrandController.text.trim(),
        type: _selectedType,
      );

      setState(() {
        _generatedAudio = audio;
      });
      UiUtils.showSuccess(context, 'Tạo audio thành công!');
    } catch (e) {
      UiUtils.showError(context, 'Tạo audio thất bại: ${e.toString()}');
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  void _showLimitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardElevated,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text(
          'Hết lượt tạo',
          style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16.sp,
              fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Tài khoản của bạn đã hết lượt tạo audio miễn phí. Vui lòng liên hệ quản trị viên để mua thêm lượt.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Đóng', style: TextStyle(color: AppColors.textHint)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.background,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            ),
            child: const Text('Mua lượt'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final credits = auth.user?.generateCredits ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Tạo Giọng Nói AI',
          style: TextStyle(fontSize: 16.sp),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info Box
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: AppColors.brandBackground,
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(color: AppColors.primary),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.bolt_rounded,
                          color: AppColors.primary, size: 24.sp),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Số lượt tạo còn lại: $credits lượt',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              'Nhập thông tin xe của bạn để AI tự động soạn thảo và phát lời chào tương ứng.',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 24.h),

                // Form fields
                _buildField(
                  label: 'Tên chủ xe',
                  controller: _nameController,
                  hint: 'Nguyễn Văn A',
                  icon: Icons.person_outline_rounded,
                ),
                SizedBox(height: 16.h),
                _buildField(
                  label: 'Biển số xe',
                  controller: _licensePlateController,
                  hint: '51A-12345',
                  icon: Icons.directions_car_rounded,
                ),
                SizedBox(height: 16.h),
                _buildField(
                  label: 'Hãng xe',
                  controller: _carBrandController,
                  hint: 'VinFast VF8',
                  icon: Icons.airport_shuttle_rounded,
                ),

                SizedBox(height: 20.h),

                // Type Select
                Text(
                  'Loại lời thoại',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 10.h),
                Row(
                  children: [
                    Expanded(
                      child: _TypeSelectCard(
                        label: 'Lời Chào',
                        icon: Icons.waving_hand_rounded,
                        selected: _selectedType == 'greeting',
                        color: AppColors.primary,
                        onTap: () => setState(() => _selectedType = 'greeting'),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: _TypeSelectCard(
                        label: 'Lời Tạm Biệt',
                        icon: Icons.directions_car_rounded,
                        selected: _selectedType == 'goodbye',
                        color: AppColors.success,
                        onTap: () => setState(() => _selectedType = 'goodbye'),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 32.h),

                // Generate Button
                _isGenerating
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation(AppColors.primary),
                        ),
                      )
                    : ElevatedButton(
                        onPressed: _generate,
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(double.infinity, 54.h),
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.background,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: Text(
                          'GENERATE AI AUDIO',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),

                SizedBox(height: 32.h),

                // Result Preview if generated
                if (_generatedAudio != null) ...[
                  Text(
                    'Kết Quả Tạo Thử',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Consumer<AudioProvider>(
                    builder: (context, audioProvider, child) {
                      final isPlayingCurrent = audioProvider.isPlaying &&
                          audioProvider.currentlyPlaying?.id ==
                              _generatedAudio!.id;

                      return Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 16.w, vertical: 12.h),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(14.r),
                          border: Border.all(
                            color: AppColors.primary,
                            width: isPlayingCurrent ? 1.5 : 1,
                          ),
                          boxShadow: null,
                        ),
                        child: Row(
                          children: [
                            _ScaleButton(
                              onTap: () {
                                if (isPlayingCurrent) {
                                  audioProvider.stopAudio();
                                } else {
                                  audioProvider.playAudio(_generatedAudio!);
                                }
                              },
                              child: Container(
                                width: 36.w,
                                height: 36.w,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isPlayingCurrent
                                      ? AppColors.primary
                                      : AppColors.cardElevated,
                                ),
                                child: Icon(
                                  isPlayingCurrent
                                      ? Icons.stop_rounded
                                      : Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 20.sp,
                                ),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _generatedAudio!.title,
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 2.h),
                                  Text(
                                    _generatedAudio!.hasLocalFile
                                        ? (_generatedAudio!.description ??
                                            'Đã lưu offline ✓')
                                        : 'Âm thanh trực tuyến (Nghe thử)',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 11.sp,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              icon: Icon(
                                Icons.more_vert_rounded,
                                color: AppColors.textSecondary,
                                size: 22.sp,
                              ),
                              color: AppColors.cardElevated,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                                side: const BorderSide(color: AppColors.border),
                              ),
                              onSelected: (value) async {
                                if (value == 'play') {
                                  if (isPlayingCurrent) {
                                    await audioProvider.stopAudio();
                                  } else {
                                    await audioProvider
                                        .playAudio(_generatedAudio!);
                                  }
                                } else if (value == 'set_greeting') {
                                  AudioModel target = _generatedAudio!;
                                  if (!target.hasLocalFile) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Đang tải và lưu âm thanh...')),
                                    );
                                    target = await audioProvider
                                        .addAndDownloadGeneratedAudio(target);
                                    setState(() {
                                      _generatedAudio = target;
                                    });
                                  }
                                  await audioProvider.setAsGreeting(target.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Đã đặt làm Lời Chào hệ thống ✓'),
                                      backgroundColor: AppColors.success,
                                    ),
                                  );
                                } else if (value == 'set_goodbye') {
                                  AudioModel target = _generatedAudio!;
                                  if (!target.hasLocalFile) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Đang tải và lưu âm thanh...')),
                                    );
                                    target = await audioProvider
                                        .addAndDownloadGeneratedAudio(target);
                                    setState(() {
                                      _generatedAudio = target;
                                    });
                                  }
                                  await audioProvider.setAsGoodbye(target.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Đã đặt làm Lời Tạm Biệt hệ thống ✓'),
                                      backgroundColor: AppColors.success,
                                    ),
                                  );
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'play',
                                  child: Row(
                                    children: [
                                      Icon(
                                        isPlayingCurrent
                                            ? Icons.pause_rounded
                                            : Icons.play_arrow_rounded,
                                        color: AppColors.primary,
                                        size: 18.sp,
                                      ),
                                      SizedBox(width: 8.w),
                                      Text(
                                        isPlayingCurrent
                                            ? 'Dừng phát'
                                            : 'Nghe thử',
                                        style: TextStyle(
                                            color: AppColors.textPrimary,
                                            fontSize: 13.sp),
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'set_greeting',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.waving_hand_rounded,
                                        color: AppColors.primary,
                                        size: 18.sp,
                                      ),
                                      SizedBox(width: 8.w),
                                      Text(
                                        'Gửi hệ thống: Đặt Lời Chào',
                                        style: TextStyle(
                                            color: AppColors.textPrimary,
                                            fontSize: 13.sp),
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'set_goodbye',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.directions_car_rounded,
                                        color: AppColors.success,
                                        size: 18.sp,
                                      ),
                                      SizedBox(width: 8.w),
                                      Text(
                                        'Gửi hệ thống: Đặt Lời Tạm Biệt',
                                        style: TextStyle(
                                            color: AppColors.textPrimary,
                                            fontSize: 13.sp),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          style: TextStyle(color: AppColors.textPrimary, fontSize: 14.sp),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 20.sp),
          ),
          validator: (v) => (v?.trim().isEmpty ?? true)
              ? 'Vui lòng điền thông tin này'
              : null,
        ),
      ],
    );
  }
}

class _TypeSelectCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _TypeSelectCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(vertical: 16.h),
        decoration: BoxDecoration(
          color: selected ? AppColors.brandBackground : AppColors.card,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: selected ? color : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon,
                color: selected ? color : AppColors.textHint, size: 24.sp),
            SizedBox(height: 8.h),
            Text(
              label,
              style: TextStyle(
                color:
                    selected ? AppColors.textPrimary : AppColors.textSecondary,
                fontSize: 12.sp,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
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
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
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
      onTapDown: (_) => widget.onTap != null ? _controller.forward() : null,
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}
