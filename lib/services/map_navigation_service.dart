import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Lightweight "open directions in Google Maps" helper.
///
/// Uses the official Google Maps URL scheme (no API key required):
/// https://developers.google.com/maps/documentation/urls/get-started
///
/// This deliberately stays URL-based rather than embedding the Maps SDK —
/// it opens the Google Maps app when installed and falls back to the
/// browser otherwise, which is enough for "get directions to this job"
/// without the cost of an in-app map screen.
abstract final class MapNavigationService {
  /// Opens Google Maps (app or browser) with driving directions to
  /// [latitude]/[longitude]. [destinationName] is only used for the
  /// on-screen error message, never sent anywhere.
  ///
  /// Shows a small snackbar via [context] if Maps/browser can't be opened.
  /// Never throws — failures are handled gracefully.
  static Future<void> openDirections({
    required BuildContext context,
    required double? latitude,
    required double? longitude,
    String? destinationName,
  }) async {
    if (latitude == null ||
        longitude == null ||
        latitude.isNaN ||
        longitude.isNaN ||
        (latitude == 0 && longitude == 0)) {
      _showMessage(context, 'Location unavailable');
      return;
    }

    final uri = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': '$latitude,$longitude',
      'travelmode': 'driving',
    });

    try {
      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!opened) {
        _showMessage(
            context, 'Unable to open Maps. Please check your Maps app or browser.');
      }
    } catch (_) {
      _showMessage(
          context, 'Unable to open Maps. Please check your Maps app or browser.');
    }
  }

  static void _showMessage(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}
