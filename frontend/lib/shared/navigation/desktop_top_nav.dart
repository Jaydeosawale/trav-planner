import 'package:flutter/material.dart';
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
