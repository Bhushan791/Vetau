import 'package:flutter/material.dart';

class PostImage extends StatelessWidget {
  final List images;
  final int rewardAmount;

  const PostImage({
    super.key,
    required this.images,
    required this.rewardAmount,
  });

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) return const SizedBox.shrink();

    return Stack(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: images.length == 1 ? 1 : 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: images.length == 1 ? 16/9 : 1,
          ),
          itemCount: images.length,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () => _showFullScreenImage(context, images, index),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  images[index],
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey[300],
                    child: const Center(child: Icon(Icons.broken_image, size: 40)),
                  ),
                ),
              ),
            );
          },
        ),
        if (images.isNotEmpty && rewardAmount > 0)
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "Rs. $rewardAmount",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
      ],
    );
  }

  void _showFullScreenImage(BuildContext context, List images, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullScreenImageViewer(
          images: images,
          initialIndex: initialIndex,
        ),
      ),
    );
  }
}

class FullScreenImageViewer extends StatefulWidget {
  final List images;
  final int initialIndex;

  const FullScreenImageViewer({
    super.key,
    required this.images,
    required this.initialIndex,
  });

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          '${_currentIndex + 1} / ${widget.images.length}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        itemCount: widget.images.length,
        itemBuilder: (context, index) {
          return InteractiveViewer(
            child: Center(
              child: Image.network(
                widget.images[index],
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.broken_image,
                  color: Colors.white,
                  size: 100,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}