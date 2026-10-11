import 'package:trav_planner/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class SearchBarWidget extends StatelessWidget {
  const SearchBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.25),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.surface),
      ),
      child: const TextField(
        style: TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.search, color: AppColors.textPrimary),
          hintText: "Where do you want to go?",
          hintStyle: TextStyle(color: AppColors.textSecondary),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
