enum Environment { development, staging, production }

class AppEnvironment {
  static const _name = String.fromEnvironment('APP_ENV', defaultValue: 'development');
  static const Environment current = _name == 'production'
      ? Environment.production
      : _name == 'staging' ? Environment.staging : Environment.development;
}
