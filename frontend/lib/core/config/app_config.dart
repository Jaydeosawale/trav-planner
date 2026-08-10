import 'environment.dart';

class AppConfig {
  AppConfig._();

  static const String appName = "Trav Planner";

  static const String appVersion = "1.0.0";

  static const Environment environment = AppEnvironment.current;

  static bool get isDevelopment =>
      environment == Environment.development;

  static bool get isStaging =>
      environment == Environment.staging;

  static bool get isProduction =>
      environment == Environment.production;
}