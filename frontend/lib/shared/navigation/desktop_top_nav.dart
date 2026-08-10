import 'package:flutter/material.dart';

import '../widgets/premium_search_bar.dart';


class DesktopTopNav extends StatelessWidget
    implements PreferredSizeWidget {
  final int selectedIndex;
  final ValueChanged<int>? onDestinationSelected;

  const DesktopTopNav({
    super.key,
    this.selectedIndex = 0,
    this.onDestinationSelected,
  });

  @override
  Size get preferredSize => const Size.fromHeight(76);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: 76,
      elevation: 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      automaticallyImplyLeading: false,
      titleSpacing: 24,

      title: Row(
        children: [
          // ======================================================
          // LOGO
          // ======================================================

          const Icon(
            Icons.travel_explore_rounded,
            color: Color(0xFF2563EB),
            size: 30,
          ),

          const SizedBox(width: 9),

          const Text(
            'Trav Planner',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),

          const SizedBox(width: 28),

          // ======================================================
          // WIDE DESKTOP SEARCH
          // ======================================================

             Expanded(
  child: Padding(
    padding: const EdgeInsets.only(
      left: 40,   // 👈 increase = move right
      right: 0,
    ),
    child: Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 300,
          maxWidth: 600,
        ),
        child: const SizedBox(
          height: 48,
          child: PremiumSearchBar(
            compact: true,
          ),
        ),
      ),
    ),
  ),
),

          const SizedBox(width: 24),

          // ======================================================
          // NAVIGATION
          // ======================================================

          _navItem('Home', 0),
          _navItem('Trips', 1),
          _navItem('Explore', 2),
          _navItem('AI', 3),
          _navItem('Saved', 4),
          _navItem('Profile', 5),

          const SizedBox(width: 18),

          // ======================================================
          // SIGN IN
          // ======================================================

          FilledButton(
            onPressed: () {
              onDestinationSelected?.call(5);
            },
            style: FilledButton.styleFrom(
              backgroundColor:
                  const Color(0xFF5067A1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 13,
              ),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(24),
              ),
            ),
            child: const Text(
              'Sign In',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem(
    String title,
    int index,
  ) {
    final selected = selectedIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 2,
      ),
      child: TextButton(
        onPressed: () {
          onDestinationSelected?.call(index);
        },
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: 9,
            vertical: 12,
          ),
          minimumSize: Size.zero,
          tapTargetSize:
              MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: selected
                ? FontWeight.w700
                : FontWeight.w500,
            color: selected
                ? const Color(0xFF2563EB)
                : Colors.black87,
          ),
        ),
      ),
    );
  }
}