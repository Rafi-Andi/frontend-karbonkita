import 'package:flutter/material.dart';

/// Penampil foto fullscreen: geser antar foto + cubit untuk zoom.
///
/// Dipakai dari foto dokumen admin (ketuk thumbnail untuk lihat jelas).
class FullscreenImageViewer extends StatefulWidget {
  const FullscreenImageViewer({
    super.key,
    required this.urls,
    this.initialIndex = 0,
    this.title = 'Foto Dokumen',
  }) : assert(urls.length > 0, 'urls tidak boleh kosong');

  final List<String> urls;
  final int initialIndex;
  final String title;

  /// Buka viewer via push route (dipanggil dari onTap thumbnail).
  static Future<void> open(
    BuildContext context, {
    required List<String> urls,
    int initialIndex = 0,
    String title = 'Foto Dokumen',
  }) {
    if (urls.isEmpty) return Future.value();
    final safeIndex = initialIndex.clamp(0, urls.length - 1);
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullscreenImageViewer(
          urls: urls,
          initialIndex: safeIndex,
          title: title,
        ),
      ),
    );
  }

  @override
  State<FullscreenImageViewer> createState() => _FullscreenImageViewerState();
}

class _FullscreenImageViewerState extends State<FullscreenImageViewer> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Tutup',
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.urls.length > 1
              ? '${widget.title} (${_index + 1}/${widget.urls.length})'
              : widget.title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.urls.length,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (context, i) {
          return InteractiveViewer(
            minScale: 1,
            maxScale: 4,
            child: Center(
              child: Image.network(
                widget.urls[i],
                fit: BoxFit.contain,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  final total = progress.expectedTotalBytes;
                  final loaded = progress.cumulativeBytesLoaded;
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: Colors.white),
                        const SizedBox(height: 12),
                        Text(
                          total != null
                              ? '${(loaded / 1024).toStringAsFixed(0)} / ${(total / 1024).toStringAsFixed(0)} KB'
                              : '${(loaded / 1024).toStringAsFixed(0)} KB',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  );
                },
                errorBuilder: (_, _, _) => const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.broken_image, color: Colors.white54, size: 48),
                    SizedBox(height: 8),
                    Text(
                      'Foto gagal dimuat.',
                      style: TextStyle(fontSize: 13, color: Colors.white54),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: widget.urls.length > 1
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.swipe, color: Colors.white54, size: 14),
                    const SizedBox(width: 6),
                    const Text(
                      'Geser untuk foto lain • cubit untuk zoom',
                      style: TextStyle(fontSize: 11, color: Colors.white54),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}
