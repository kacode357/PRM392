import 'package:flutter/material.dart';
import 'package:user/constants/app_colors.dart'; // Nhớ sửa 'user'

class AlertModal extends StatelessWidget {
  final bool visible;
  final String title;
  final String message;
  final bool? isSuccess; // Optional, để tùy chỉnh màu/icon
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel; // Thêm onCancel cho nút "Hủy" nếu có

  const AlertModal({
    super.key,
    required this.visible,
    required this.title,
    required this.message,
    this.isSuccess,
    this.onConfirm,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    if (!visible) {
      return const SizedBox.shrink(); // Không hiển thị gì nếu visible là false
    }

    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: <Widget>[
        if (onCancel != null)
          TextButton(
            onPressed: onCancel,
            child: const Text('Hủy'),
          ),
        TextButton(
          onPressed: onConfirm,
          child: const Text('OK'),
        ),
      ],
    );
  }
}