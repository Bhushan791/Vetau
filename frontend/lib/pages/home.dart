import 'package:flutter/material.dart';
import '../components/header.dart';
import '../components/nav.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: const VetauHeader(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: VetauFAB(onPressed: () {}),
      bottomNavigationBar: VetauNav(
        currentIndex: 0,
        onTap: (_) {},
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          _FiltersBar(),
          const SizedBox(height: 8),
          _PostCard(
            title:
                'Dog Lost near Khasibazar, Kirtipur. Please help me find it.',
            reward: '₹5,000',
            comments: 15,
            imageUrl:
                'https://images.unsplash.com/photo-1543466835-00a7907e9de1?q=80&w=1200&auto=format&fit=crop',
          ),
          _PostCard(
            title: 'Wallet lost near Baneshwor',
            reward: '₹1,000',
            comments: 15,
            imageUrl:
                'https://images.unsplash.com/photo-1543466835-00a7907e9de1?q=80&w=1200&auto=format&fit=crop',
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _FiltersBar extends StatelessWidget {
  final chips = const [
    _FilterChip(label: 'Near You'),
    _FilterChip(label: 'All', selected: true),
    _FilterChip(label: 'Lost'),
    _FilterChip(label: 'Found'),
    _FilterChip(label: 'High Reward', icon: Icons.wallet_giftcard),
    _FilterChip(label: 'Pets'),
    _FilterChip(label: 'Electronics'),
    _FilterChip(label: 'Show less'),
  ];

  const _FiltersBar({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemBuilder: (_, i) => chips[i],
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: chips.length,
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final IconData? icon;
  const _FilterChip({super.key, required this.label, this.selected = false, this.icon});

  @override
  Widget build(BuildContext context) {
    final bg = selected ? const Color(0xFF4E6AF3) : Colors.white;
    final fg = selected ? Colors.white : Colors.black87;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE6E9F2)),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: fg),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(color: fg, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final String title;
  final String reward;
  final int comments;
  final String imageUrl;

  const _PostCard({
    required this.title,
    required this.reward,
    required this.comments,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            _imageWithBadges(context),
            const SizedBox(height: 10),
            Row(
              children: [
                _chipIcon(
                  icon: Icons.mode_comment_outlined,
                  label: comments.toString(),
                ),
                const SizedBox(width: 12),
                _actionButton(label: 'share', icon: Icons.ios_share),
                const SizedBox(width: 8),
                _actionButton(label: 'save', icon: Icons.bookmark_border),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _imageWithBadges(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 10,
          left: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFF7D66),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Lost',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        Positioned(
          top: 10,
          right: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFA94D),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.wallet_giftcard, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Text(
                  reward,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _chipIcon({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6FA),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[700]),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: Colors.grey[800])),
        ],
      ),
    );
  }

  Widget _actionButton({required String label, required IconData icon}) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        side: const BorderSide(color: Color(0xFFE6E9F2)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      onPressed: () {},
      icon: Icon(icon, size: 16, color: Colors.grey[800]),
      label: Text(
        label,
        style: const TextStyle(color: Colors.black87),
      ),
    );
  }
}
