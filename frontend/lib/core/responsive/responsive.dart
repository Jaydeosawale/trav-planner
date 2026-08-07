import 'package:flutter/material.dart';

import 'breakpoints.dart';

class Responsive {
  Responsive._();

  static double width(BuildContext context) =>
      MediaQuery.sizeOf(context).width;

  static double height(BuildContext context) =>
      MediaQuery.sizeOf(context).height;

  static bool isMobile(BuildContext context) =>
      width(context) < Breakpoints.mobile;

  static bool isTablet(BuildContext context) =>
      width(context) >= Breakpoints.mobile &&
      width(context) < Breakpoints.tablet;

  static bool isDesktop(BuildContext context) =>
      width(context) >= Breakpoints.tablet;

  static bool isLandscape(BuildContext context) =>
      MediaQuery.orientationOf(context) == Orientation.landscape;

  static bool isPortrait(BuildContext context) =>
      MediaQuery.orientationOf(context) == Orientation.portrait;

  static double value<T>({
    required BuildContext context,
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    if (isDesktop(context)) {
      return desktop ?? tablet ?? mobile;
    }

    if (isTablet(context)) {
      return tablet ?? mobile;
    }

    return mobile;
  }
}