import 'package:flutter/material.dart';

class VetauHeader extends StatelessWidget implements PreferredSizeWidget {
  const VetauHeader({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      elevation: 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            _roundIcon(
              context,
              icon: Icons.notifications_none,
            ),
            const SizedBox(width: 10),
            const Text(
              'Vetau',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const Spacer(),
            _rewardPill(context),
            const SizedBox(width: 10),
            _roundIcon(
              context,
              icon: Icons.account_circle_outlined,
            ),
          ],
        ),
      ),
    );
  }

  Widget _roundIcon(BuildContext context, {required IconData icon}) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF4FF),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFD8E2FF)),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: const Color(0xFF4E6AF3)),
    );
  }

  Widget _rewardPill(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFA94D),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33FF9D3B),
            blurRadius: 8,
            offset: Offset(0, 2),
          )
        ],
      ),
      child: Row(
        children: const [
          Icon(Icons.workspace_premium_outlined, color: Colors.white),
          SizedBox(width: 6),
          Text(
            '120.76',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(width: 6),
          Text(
            'Reward Points',
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
