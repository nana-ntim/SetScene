// File: lib/components/custom_bottom_nav_bar.dart

import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Define nav items (removed map item)
    final List<NavItem> items = [
      NavItem(
        icon: Icons.explore_outlined,
        activeIcon: Icons.explore,
        label: 'Explore',
      ),
      NavItem(
        icon: Icons.bookmark_border,
        activeIcon: Icons.bookmark,
        label: 'Saved',
      ),
      NavItem(
        icon: Icons.add_circle_outline,
        activeIcon: Icons.add_circle,
        label: '', // Empty label for center button
      ),
      NavItem(
        icon: Icons.person_outline,
        activeIcon: Icons.person,
        label: 'Profile',
      ),
    ];

    return Container(
      height: 80,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(
            items.length,
            (index) => _buildNavItem(context, items[index], index),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, NavItem item, int index) {
    final isSelected = currentIndex == index;
    final isCreateButton = index == 2; // Center button

    if (isCreateButton) {
      return GestureDetector(
        onTap: () => onTap(index),
        child: Container(
          width: 56,
          height: 56,
          margin: const EdgeInsets.only(bottom: 8, top: 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Colors.grey[300]!],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(Icons.add, color: Colors.black, size: 28),
        ),
      );
    }

    return InkWell(
      onTap: () => onTap(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? Colors.blue.withOpacity(0.1)
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isSelected ? item.activeIcon : item.icon,
                color: isSelected ? Colors.white : Colors.grey[600],
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  NavItem({required this.icon, required this.activeIcon, required this.label});
}
