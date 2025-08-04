import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  // Naver Map API Keys
  static String get naverMapClientKey {
    return dotenv.env['NAVER_MAP_CLIENT_KEY'] ?? '';
  }

  static String get naverMapClientSecret {
    return dotenv.env['NAVER_MAP_CLIENT_SECRET'] ?? '';
  }

  // Google Maps API Key
  static String get googleMapsApiKey {
    return dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
  }

  // API Configuration
  static String get apiBaseUrl {
    return dotenv.env['API_BASE_URL'] ?? 'https://api.example.com';
  }

  static String get apiVersion {
    return dotenv.env['API_VERSION'] ?? 'v1';
  }

  // App Configuration
  static String get appName {
    return dotenv.env['APP_NAME'] ?? 'PJ Trip';
  }

  static String get appVersion {
    return dotenv.env['APP_VERSION'] ?? '1.0.0';
  }

  static bool get isDebugMode {
    return dotenv.env['DEBUG_MODE'] == 'true';
  }

  // Validation methods
  static bool get isNaverMapConfigured {
    return naverMapClientKey.isNotEmpty;
  }

  static bool get isGoogleMapsConfigured {
    return googleMapsApiKey.isNotEmpty;
  }

  // Helper method to get full API URL
  static String getFullApiUrl(String endpoint) {
    return '$apiBaseUrl/$apiVersion/$endpoint';
  }

  // Validation with error throwing
  static String getRequiredNaverMapClientKey() {
    final key = naverMapClientKey;
    if (key.isEmpty) {
      throw Exception('NAVER_MAP_CLIENT_KEY is required but not configured');
    }
    return key;
  }

  static String getRequiredGoogleMapsApiKey() {
    final key = googleMapsApiKey;
    if (key.isEmpty) {
      throw Exception('GOOGLE_MAPS_API_KEY is required but not configured');
    }
    return key;
  }
}
