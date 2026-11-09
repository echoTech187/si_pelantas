import 'package:flutter/material.dart';

class SipelantasBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<SipelantasNavItem> items;
  final Color backgroundColor;
  final Color activeColor;
  final Color inactiveColor;

  const SipelantasBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.backgroundColor = const Color(0xFF131E33),
    this.activeColor = const Color(0xFFFF8A3D),
    this.inactiveColor = const Color(0xFF64748B),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isSelected = currentIndex == index;

              return InkWell(
                onTap: () => onTap(index),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.icon,
                        color: isSelected ? activeColor : inactiveColor,
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? activeColor : inactiveColor,
                        ),
                      ),
                      const SizedBox(height: 3),
                      // Dot indicator matching the reference design
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: isSelected ? 4 : 0,
                        height: isSelected ? 4 : 0,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: activeColor,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class SipelantasNavItem {
  final IconData icon;
  final String label;

  const SipelantasNavItem({
    required this.icon,
    required this.label,
  });
}

