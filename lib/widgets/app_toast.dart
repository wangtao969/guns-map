import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';

/// 全局弹窗式提示：替代底部 SnackBar，弹在屏幕上方、自动消失。
/// 点一下可提前关闭；传 onTap 时点击会执行回调（如复制链接）。
OverlayEntry? _currentToast;
Timer? _toastTimer;

void showAppToast(
  BuildContext context,
  String message, {
  VoidCallback? onTap,
  String? actionLabel,
}) {
  _toastTimer?.cancel();
  _currentToast?.remove();
  _currentToast = null;
  final overlay = Overlay.of(context);
  late final OverlayEntry entry;
  void dismiss() {
    _toastTimer?.cancel();
    _currentToast?.remove();
    _currentToast = null;
  }

  entry = OverlayEntry(
    builder: (ctx) {
      final top = MediaQuery.of(ctx).padding.top + 72;
      return Positioned(
        top: top,
        left: 32,
        right: 32,
        child: Material(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: () {
              dismiss();
              onTap?.call();
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 13),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.78),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.18)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(message,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 14)),
                      ),
                      if (actionLabel != null) ...[
                        const SizedBox(width: 10),
                        Text(actionLabel,
                            style: const TextStyle(
                                color: Color(0xFFE8B45A),
                                fontWeight: FontWeight.bold,
                                fontSize: 14)),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
  _currentToast = entry;
  overlay.insert(entry);
  _toastTimer = Timer(const Duration(milliseconds: 2800), dismiss);
}
