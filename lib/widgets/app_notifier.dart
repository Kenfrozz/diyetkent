import 'package:flutter/material.dart';

class AppNotifier {
  static void showInfo(BuildContext context, String message) {
    _showBanner(
      context,
      message,
      backgroundColor: Colors.teal.shade600,
      foregroundColor: Colors.white,
    );
  }

  static void showError(BuildContext context, String message) {
    _showBanner(
      context,
      message,
      backgroundColor: Colors.red.shade600,
      foregroundColor: Colors.white,
    );
  }

  static void _showBanner(
    BuildContext context,
    String message, {
    required Color backgroundColor,
    required Color foregroundColor,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    // Eski banner/snackbar varsa kaldır
    messenger.clearMaterialBanners();
    messenger.hideCurrentSnackBar();

    final banner = MaterialBanner(
      backgroundColor: backgroundColor,
      contentTextStyle: TextStyle(color: foregroundColor),
      content: Text(message),
      leading: Icon(Icons.info_outline, color: foregroundColor),
      actions: [
        TextButton(
          onPressed: () => messenger.hideCurrentMaterialBanner(),
          child: Text('Kapat', style: TextStyle(color: foregroundColor)),
        ),
      ],
    );

    messenger.showMaterialBanner(banner);

    // Otomatik gizle
    Future.delayed(const Duration(seconds: 2), () {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
    });
  }
}
