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
}
