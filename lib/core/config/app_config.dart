enum AppFlavor { dev, prod }

class AppConfig {
  final AppFlavor flavor;
  final String apiBaseUrl;

  const AppConfig({
    required this.flavor,
    required this.apiBaseUrl,
  });

  bool get isDev => flavor == AppFlavor.dev;
  bool get isProd => flavor == AppFlavor.prod;

  factory AppConfig.fromEnvironment({required AppFlavor defaultFlavor}) {
    const envStr = String.fromEnvironment('ENV', defaultValue: '');
    AppFlavor resolvedFlavor = defaultFlavor;
    if (envStr.isNotEmpty) {
      final lower = envStr.toLowerCase();
      if (lower == 'prod' || lower == 'production') {
        resolvedFlavor = AppFlavor.prod;
      } else if (lower == 'dev' || lower == 'development') {
        resolvedFlavor = AppFlavor.dev;
      }
    }

    const explicitUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (explicitUrl.isNotEmpty) {
      return AppConfig(flavor: resolvedFlavor, apiBaseUrl: explicitUrl);
    }

    final defaultUrl = resolvedFlavor == AppFlavor.dev
        ? 'http://127.0.0.1:8000'
        : 'https://fpl-lens.onrender.com';

    return AppConfig(flavor: resolvedFlavor, apiBaseUrl: defaultUrl);
  }
}
