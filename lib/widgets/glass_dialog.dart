import 'dart:ui';
import 'package:flutter/material.dart';

/// 全 App 输入类子窗口的统一风格：毛玻璃圆角卡片 + 铜色主按钮。
/// 与账号弹窗（登录/注册/编辑资料）同款视觉语言：深色毛玻璃底、
/// 28 圆角、标题 + 内容 + 底部按钮行。
class GlassDialog extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget content;
  final List<Widget> actions;
  const GlassDialog({
    super.key,
    required this.title,
    this.subtitle,
    required this.content,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              decoration: BoxDecoration(
                color: dark
                    ? Colors.black.withValues(alpha: 0.72)
                    : Colors.white.withValues(alpha: 0.92),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(title,
                              style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: dark
                                      ? Colors.white
                                      : const Color(0xFF2E2A24))),
                        ),
                        InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => Navigator.of(context).pop(),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(Icons.close,
                                size: 20,
                                color: dark
                                    ? Colors.white70
                                    : Colors.black54),
                          ),
                        ),
                      ],
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(subtitle!,
                          style: TextStyle(
                              color: dark
                                  ? Colors.white70
                                  : Colors.black54,
                              fontSize: 12)),
                    ],
                    const SizedBox(height: 16),
                    content,
                    if (actions.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: actions,
                      ),
                    ],
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

/// 毛玻璃弹窗里的标准按钮：次按钮文字、主按钮铜色实心。
Widget glassCancelButton(BuildContext context, String label) {
  return TextButton(
    onPressed: () => Navigator.of(context).pop(false),
    child: Text(label),
  );
}

Widget glassPrimaryButton(BuildContext context, String label,
    {VoidCallback? onPressed, bool popTrue = false}) {
  return FilledButton(
    style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFFE86A1C)),
    onPressed: onPressed ??
        (popTrue ? () => Navigator.of(context).pop(true) : null),
    child: Text(label, style: const TextStyle(color: Colors.white)),
  );
}
