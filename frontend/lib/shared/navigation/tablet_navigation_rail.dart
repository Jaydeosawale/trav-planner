import 'package:flutter/material.dart';

class TabletNavigationRail extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int>? onDestinationSelected;

  const TabletNavigationRail({
    super.key,
    this.selectedIndex = 0,
    this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      selectedIndex: selectedIndex,
      extended: false,
      minWidth: 80,
      labelType: NavigationRailLabelType.all,
      onDestinationSelected:
          onDestinationSelected,
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon:
              Icon(Icons.home_rounded),
          label: Text("Home"),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.luggage_outlined),
          selectedIcon:
              Icon(Icons.luggage_rounded),
          label: Text("Trips"),
        ),
        NavigationRailDestination(
          icon: Icon(
            Icons.auto_awesome_outlined,
          ),
          selectedIcon:
              Icon(Icons.auto_awesome_rounded),
          label: Text("AI"),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.favorite_outline),
          selectedIcon:
              Icon(Icons.favorite_rounded),
          label: Text("Saved"),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon:
              Icon(Icons.person_rounded),
          label: Text("Profile"),
        ),
      ],
    );
  }
}
