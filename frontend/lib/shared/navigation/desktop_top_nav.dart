import 'package:flutter/material.dart';
import '../../features/places/presentation/area_selector.dart';
import '../../core/theme/app_colors.dart';
import '../widgets/brand_logo.dart';

class DesktopTopNav extends StatelessWidget implements PreferredSizeWidget {
  const DesktopTopNav({
    super.key,
    this.selectedIndex = 0,
    this.onDestinationSelected,
  });
  final int selectedIndex;
  final ValueChanged<int>? onDestinationSelected;
  @override
  Size get preferredSize => const Size.fromHeight(80);
  @override
  Widget build(BuildContext context) => AppBar(
    toolbarHeight: 80,
    automaticallyImplyLeading: false,
    titleSpacing: 40,
    shape: const Border(bottom: BorderSide(color: AppColors.border)),
    title: Row(
      children: [
        const BrandLogo(size: 34),
        if (selectedIndex == 0) ...[
          const SizedBox(width: 20),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 180),
            child: const AreaSelector(compact: true),
          ),
        ],
        const Spacer(),
        ...[
          'Home',
          'Explore',
          'AI Planner',
          'My Trips',
          'Profile',
        ].asMap().entries.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(left: 6),
            child: TextButton(
              onPressed: () => onDestinationSelected?.call(entry.key),
              style: TextButton.styleFrom(
                foregroundColor: selectedIndex == entry.key
                    ? AppColors.primary
                    : AppColors.textSecondary,
                backgroundColor: selectedIndex == entry.key
                    ? AppColors.surfaceVariant
                    : Colors.transparent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 18,
                ),
              ),
              child: Text(entry.value),
            ),
          ),
        ),
      ],
    ),
  );
}
