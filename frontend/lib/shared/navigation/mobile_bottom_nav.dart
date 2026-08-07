import 'package:flutter/material.dart';

class MobileBottomNav extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;

  const MobileBottomNav({
    super.key,
    this.currentIndex = 0,
    this.onTap,
  });

  @override
  State<MobileBottomNav> createState() =>
      _MobileBottomNavState();
}

class _MobileBottomNavState extends State<MobileBottomNav> {
  late int _selectedIndex;

  final List<(IconData, String)> _items = const [
    (Icons.home_rounded, "Home"),
    (Icons.luggage_rounded, "Trips"),
    (Icons.auto_awesome_rounded, "AI"),
    (Icons.favorite_rounded, "Saved"),
    (Icons.person_rounded, "Profile"),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.currentIndex;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      child: Container(
        height: 74,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .95),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .08),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: List.generate(
            _items.length,
            (index) {
              final item = _items[index];
              final selected = index == _selectedIndex;

              return Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: () {
                    setState(() {
                      _selectedIndex = index;
                    });

                    widget.onTap?.call(index);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFF2563EB)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedScale(
                          duration: const Duration(milliseconds: 250),
                          scale: selected ? 1.15 : 1,
                          child: Icon(
                            item.$1,
                            color: selected
                                ? Colors.white
                                : Colors.grey.shade600,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.$2,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? Colors.white
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}