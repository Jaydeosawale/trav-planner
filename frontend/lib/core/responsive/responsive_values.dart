import 'package:flutter/material.dart';

import 'responsive.dart';

class ResponsiveValues {
  ResponsiveValues._();

  // ==========================================================
  // HERO
  // ==========================================================

  static double heroHeight(BuildContext context) =>
      Responsive.value(
        context: context,
        mobile: 380,
        tablet: 410,
        desktop: 450,
      );

  static double heroTitle(BuildContext context) =>
      Responsive.value(
        context: context,
        mobile: 40,
        tablet: 46,
        desktop: 52,
      );

  static double heroSubtitle(BuildContext context) =>
      Responsive.value(
        context: context,
        mobile: 17,
        tablet: 18,
        desktop: 19,
      );

  // ==========================================================
  // SEARCH BAR
  // ==========================================================

  static double searchBarHeight(BuildContext context) =>
      Responsive.value(
        context: context,
        mobile: 60,
        tablet: 64,
        desktop: 64,
      );

  static double searchBarMaxWidth(BuildContext context) =>
      Responsive.value(
        context: context,
        mobile: double.infinity,
        tablet: 560,
        desktop: 620,
      );

  // ==========================================================
  // DESTINATION CARD
  // ==========================================================

  static double destinationCardWidth(BuildContext context) =>
      Responsive.value(
        context: context,
        mobile: 285,
        tablet: 320,
        desktop: 360,
      );

  static double destinationCardHeight(BuildContext context) =>
      Responsive.value(
        context: context,
        mobile: 390,
        tablet: 430,
        desktop: 470,
      );

  static double destinationImageRadius(BuildContext context) =>
      Responsive.value(
        context: context,
        mobile: 30,
        tablet: 34,
        desktop: 38,
      );

  // ==========================================================
  // CATEGORY CARD
  // ==========================================================

  static double categoryCardWidth(BuildContext context) =>
      Responsive.value(
        context: context,
        mobile: 100,
        tablet: 120,
        desktop: 145,
      );

  static double categoryCardHeight(BuildContext context) =>
      Responsive.value(
        context: context,
        mobile: 120,
        tablet: 135,
        desktop: 150,
      );

  static double categoryIcon(BuildContext context) =>
      Responsive.value(
        context: context,
        mobile: 30,
        tablet: 34,
        desktop: 38,
      );

  // ==========================================================
  // WEATHER CARD
  // ==========================================================

  static double weatherCardHeight(BuildContext context) =>
      Responsive.value(
        context: context,
        mobile: 170,
        tablet: 190,
        desktop: 210,
      );

  // ==========================================================
  // BUTTONS
  // ==========================================================

  static double buttonHeight(BuildContext context) =>
      Responsive.value(
        context: context,
        mobile: 56,
        tablet: 60,
        desktop: 64,
      );

  // ==========================================================
  // ICONS
  // ==========================================================

  static double icon(BuildContext context) =>
      Responsive.value(
        context: context,
        mobile: 24,
        tablet: 26,
        desktop: 30,
      );

  static double largeIcon(BuildContext context) =>
      Responsive.value(
        context: context,
        mobile: 36,
        tablet: 42,
        desktop: 48,
      );

  // ==========================================================
  // SPACING
  // ==========================================================

  static double screenPadding(BuildContext context) =>
      Responsive.value(
        context: context,
        mobile: 20,
        tablet: 28,
        desktop: 40,
      );

  static double sectionSpacing(BuildContext context) =>
      Responsive.value(
        context: context,
        mobile: 32,
        tablet: 40,
        desktop: 52,
      );

  static double cardSpacing(BuildContext context) =>
      Responsive.value(
        context: context,
        mobile: 18,
        tablet: 22,
        desktop: 26,
      );

  // ==========================================================
  // BORDER RADIUS
  // ==========================================================

  static double radius(BuildContext context) =>
      Responsive.value(
        context: context,
        mobile: 24,
        tablet: 28,
        desktop: 32,
      );

  static double largeRadius(BuildContext context) =>
      Responsive.value(
        context: context,
        mobile: 30,
        tablet: 34,
        desktop: 40,
      );

  // ==========================================================
  // TEXT
  // ==========================================================

  static double heading(BuildContext context) =>
      Responsive.value(
        context: context,
        mobile: 28,
        tablet: 32,
        desktop: 36,
      );

  static double subHeading(BuildContext context) =>
      Responsive.value(
        context: context,
        mobile: 16,
        tablet: 17,
        desktop: 18,
      );

  static double body(BuildContext context) =>
      Responsive.value(
        context: context,
        mobile: 14,
        tablet: 15,
        desktop: 16,
      );

  static double caption(BuildContext context) =>
      Responsive.value(
        context: context,
        mobile: 12,
        tablet: 13,
        desktop: 14,
      );
}