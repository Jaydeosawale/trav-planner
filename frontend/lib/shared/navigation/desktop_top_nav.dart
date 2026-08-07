import 'package:flutter/material.dart';

class DesktopTopNav extends StatelessWidget
    implements PreferredSizeWidget {
  const DesktopTopNav({super.key});

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
      titleSpacing: 32,
      title: Row(
        children: [
          const Icon(
            Icons.travel_explore_rounded,
            color: Color(0xFF2563EB),
            size: 30,
          ),

          const SizedBox(width: 10),

          const Text(
            "Trav Planner",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),

          const Spacer(),

          _navItem("Home"),
          _navItem("Trips"),
          _navItem("Explore"),
          _navItem("AI"),
          _navItem("Saved"),
          _navItem("Profile"),

          const SizedBox(width: 20),

          FilledButton(
            onPressed: () {},
            child: const Text("Sign In"),
          ),
        ],
      ),
    );
  }

  Widget _navItem(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: TextButton(
        onPressed: () {},
        child: Text(title),
      ),
    );
  }
}