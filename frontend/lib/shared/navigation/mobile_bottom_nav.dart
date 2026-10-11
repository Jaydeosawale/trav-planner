import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class MobileBottomNav extends StatelessWidget {
  const MobileBottomNav({super.key, this.currentIndex = 0, this.onTap});
  final int currentIndex;
  final ValueChanged<int>? onTap;
  static const items = [
    (Icons.home_outlined, 'Home'),
    (Icons.explore_outlined, 'Explore'),
    (Icons.auto_awesome_outlined, 'AI Planner'),
    (Icons.luggage_outlined, 'My Trips'),
    (Icons.person_outline, 'Profile'),
  ];
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      color: AppColors.surface,
      border: Border(top: BorderSide(color: AppColors.border)),
    ),
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: List.generate(items.length, (index) {
            final selected = index == currentIndex;
            return Expanded(
              child: Semantics(
                selected: selected,
                button: true,
                label: items[index].$2,
                child: InkWell(
                  onTap: () => onTap?.call(index),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.surfaceVariant
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            items[index].$1,
                            color: selected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          items[index].$2,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 10,
                            color: selected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    ),
  );
}
