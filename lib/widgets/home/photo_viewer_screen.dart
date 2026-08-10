import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Premium full-screen photo viewer — a VIEWER, not an editor. Opened when
/// the user taps their (already-real) profile photo; changing the photo
/// stays the pencil/camera button's job (see `ProfileAvatarEditor`).
///
/// Shows [imageBytes] (a just-picked local image, not yet uploaded) when
/// present, otherwise [imageUrl] (the persisted photo). Supports
/// pinch-to-zoom via [InteractiveViewer] and closes on tap of the backdrop
/// or the close button.
class PhotoViewerScreen extends StatelessWidget {
  const PhotoViewerScreen({super.key, this.imageBytes, this.imageUrl});

  final Uint8List? imageBytes;
  final String? imageUrl;

  static Future<void> show(
    BuildContext context, {
    Uint8List? imageBytes,
    String? imageUrl,
  }) {
    return Navigator.of(context).push(PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black.withValues(alpha: .94),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, animation, __) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween(begin: .94, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
          child: PhotoViewerScreen(imageBytes: imageBytes, imageUrl: imageUrl),
        ),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final hasBytes = imageBytes != null;
    final hasUrl = imageUrl != null && imageUrl!.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            Positioned.fill(
              child: Center(
                child: InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: GestureDetector(
                    // Absorb taps on the image itself so viewing/zooming
                    // doesn't immediately close the viewer.
                    onTap: () {},
                    child: hasBytes
                        ? Image.memory(imageBytes!, fit: BoxFit.contain)
                        : hasUrl
                            ? Image.network(
                                imageUrl!,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) =>
                                    const _BrokenImage(),
                              )
                            : const _BrokenImage(),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: SafeArea(
                child: IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: Colors.white, size: 28),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrokenImage extends StatelessWidget {
  const _BrokenImage();

  @override
  Widget build(BuildContext context) => const Icon(
        Icons.broken_image_rounded,
        color: Colors.white54,
        size: 64,
      );
}
