// lib/widgets/alert_dialog.dart

import 'package:flutter/material.dart';

class AppAlertDialog {
  // Hàm static để gọi dialog từ bất cứ đâu mà không cần tạo instance
  // Trả về Future<bool?>: true nếu nhấn OK, false nếu nhấn Cancel, null nếu bấm ra ngoài
  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String content,
    bool isSuccess = false, // Dùng để hiển thị icon success hoặc error
    bool showCancelButton = false,
    String confirmText = 'OK',
    String cancelText = 'Hủy',
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true, // Cho phép bấm ra ngoài để đóng
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
          title: Row(
            children: [
              // Hiển thị Icon dựa trên isSuccess
              Icon(
                isSuccess ? Icons.check_circle : Icons.error_outline,
                color: isSuccess ? Colors.green : Colors.red,
              ),
              SizedBox(width: 10),
              Expanded(child: Text(title)),
            ],
          ),
          content: Text(content),
          actions: <Widget>[
            // Nút Hủy (nếu có)
            if (showCancelButton)
              TextButton(
                child: Text(cancelText),
                onPressed: () {
                  Navigator.of(context).pop(false); // Trả về false
                },
              ),
            // Nút OK
            TextButton(
              child: Text(confirmText),
              onPressed: () {
                Navigator.of(context).pop(true); // Trả về true
              },
            ),
          ],
        );
      },
    );
  }
}