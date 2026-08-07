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
        border: Border.all(
          color: Colors.white30,
        ),
      ),
      child: const TextField(
        style: TextStyle(
          color: Colors.white,
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(
            Icons.search,
            color: Colors.white,
          ),
          hintText: "Where do you want to go?",
          hintStyle: TextStyle(
            color: Colors.white70,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }
}