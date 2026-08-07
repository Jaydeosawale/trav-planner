enum Environment {
  development,
  staging,
  production,
}

class AppEnvironment {
  static const Environment current = Environment.development;
}