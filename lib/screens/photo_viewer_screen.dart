import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/person.dart';
import '../models/photo.dart';

/// Full-screen photo viewer with a plain rectangle drawn on each identifiable face.
class PhotoViewerScreen extends StatefulWidget {
  const PhotoViewerScreen({
    super.key,
    required this.photo,
    required this.people,
  });

  final Photo photo;
  final List<Person> people;

  @override
  State<PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<PhotoViewerScreen> {
  int? _imageWidth;
  int? _imageHeight;
  ImageStream? _imageStream;
  late ImageStreamListener _imageListener;

  @override
  void initState() {
    super.initState();
    _imageListener = ImageStreamListener((ImageInfo info, bool sync) {
      if (!mounted) return;
      final w = info.image.width;
      final h = info.image.height;
      info.image.dispose();
      setState(() {
        _imageWidth = w;
        _imageHeight = h;
      });
    });
    _imageStream = NetworkImage(widget.photo.imageUrl).resolve(
      const ImageConfiguration(),
    );
    _imageStream!.addListener(_imageListener);
  }

  @override
  void dispose() {
    _imageStream?.removeListener(_imageListener);
    _imageStream = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Photo'),
            if (widget.photo.takenAt != null)
              Text(
                DateFormat('MMM d, y · HH:mm').format(widget.photo.takenAt!),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                  color: Colors.white70,
                ),
              ),
          ],
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          InteractiveViewer(
            minScale: 0.5,
            maxScale: 4,
            child: Center(
              child: Image.network(
                widget.photo.imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(
                    Icons.broken_image,
                    color: Colors.white54,
                    size: 48,
                  ),
                ),
              ),
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final imageRect = _imageDisplayRect(
                constraints.maxWidth,
                constraints.maxHeight,
              );
              return Stack(
                fit: StackFit.expand,
                children: [
                  ...widget.photo.faceRegions.map((region) {
                    final (left, top, width, height) = region.relativeRect;
                    return Positioned(
                      left: imageRect.left + imageRect.width * left,
                      top: imageRect.top + imageRect.height * top,
                      width: imageRect.width * width,
                      height: imageRect.height * height,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => Navigator.of(context).pop(region.personId),
                        child: const _FaceOverlay(),
                      ),
                    );
                  }),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Rect _imageDisplayRect(double screenW, double screenH) {
    final iw = _imageWidth?.toDouble() ?? 1;
    final ih = _imageHeight?.toDouble() ?? 1;
    if (iw <= 0 || ih <= 0) return Rect.zero;

    final scale = (screenW / iw).clamp(0.0, double.infinity);
    final scaleH = screenH / ih;
    final scaleUsed = scale <= scaleH ? scale : scaleH;
    final displayW = iw * scaleUsed;
    final displayH = ih * scaleUsed;
    final left = (screenW - displayW) / 2;
    final top = (screenH - displayH) / 2;
    return Rect.fromLTWH(left, top, displayW, displayH);
  }
}

class _FaceOverlay extends StatelessWidget {
  const _FaceOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white, width: 2),
      ),
    );
  }
}
