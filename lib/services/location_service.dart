import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Result of location detection
class LocationResult {
  final String? provinceCode;
  final String? provinceName;
  final String? errorMessage;
  final bool isSuccess;

  const LocationResult._({
    this.provinceCode,
    this.provinceName,
    this.errorMessage,
    required this.isSuccess,
  });

  factory LocationResult.success({
    required String provinceCode,
    required String provinceName,
  }) {
    return LocationResult._(
      provinceCode: provinceCode,
      provinceName: provinceName,
      isSuccess: true,
    );
  }

  factory LocationResult.error(String message) {
    return LocationResult._(
      errorMessage: message,
      isSuccess: false,
    );
  }
}

/// Service for detecting user location and mapping to Canadian province
class LocationService {
  static const String _cachedProvinceCodeKey = 'cached_province_code';
  static const String _cachedProvinceNameKey = 'cached_province_name';
  static const String _cachedTimestampKey = 'cached_location_timestamp';

  // Cache duration: 24 hours
  static const Duration _cacheDuration = Duration(hours: 24);

  /// Province code to full name mapping
  static const Map<String, String> _provinceCodeToName = {
    'AB': 'Alberta',
    'BC': 'British Columbia',
    'MB': 'Manitoba',
    'NB': 'New Brunswick',
    'NL': 'Newfoundland and Labrador',
    'NS': 'Nova Scotia',
    'NT': 'Northwest Territories',
    'NU': 'Nunavut',
    'ON': 'Ontario',
    'PE': 'Prince Edward Island',
    'QC': 'Quebec',
    'SK': 'Saskatchewan',
    'YT': 'Yukon',
  };

  /// Province name variations to standard code mapping
  static const Map<String, String> _provinceNameToCode = {
    // Full names
    'alberta': 'AB',
    'british columbia': 'BC',
    'manitoba': 'MB',
    'new brunswick': 'NB',
    'newfoundland and labrador': 'NL',
    'newfoundland': 'NL',
    'labrador': 'NL',
    'nova scotia': 'NS',
    'northwest territories': 'NT',
    'nunavut': 'NU',
    'ontario': 'ON',
    'prince edward island': 'PE',
    'quebec': 'QC',
    'saskatchewan': 'SK',
    'yukon': 'YT',
    'yukon territory': 'YT',
    // Common abbreviations
    'ab': 'AB',
    'bc': 'BC',
    'mb': 'MB',
    'nb': 'NB',
    'nl': 'NL',
    'nf': 'NL', // Old abbreviation
    'ns': 'NS',
    'nt': 'NT',
    'nu': 'NU',
    'on': 'ON',
    'pe': 'PE',
    'pei': 'PE',
    'qc': 'QC',
    'pq': 'QC', // Old abbreviation
    'sk': 'SK',
    'yt': 'YT',
  };

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      return false;
    }
  }

  /// Request location permission
  Future<bool> requestPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      return permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    } catch (e) {
      return false;
    }
  }

  /// Check current permission status
  Future<LocationPermission> checkPermission() async {
    try {
      return await Geolocator.checkPermission();
    } catch (e) {
      return LocationPermission.denied;
    }
  }

  /// Get cached location result if still valid
  Future<LocationResult?> getCachedLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_cachedTimestampKey);

      if (timestamp == null) return null;

      final cachedTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final now = DateTime.now();

      if (now.difference(cachedTime) > _cacheDuration) {
        return null;
      }

      final provinceCode = prefs.getString(_cachedProvinceCodeKey);
      final provinceName = prefs.getString(_cachedProvinceNameKey);

      if (provinceCode != null && provinceName != null) {
        return LocationResult.success(
          provinceCode: provinceCode,
          provinceName: provinceName,
        );
      }
    } catch (e) {
      // Ignore cache errors
    }
    return null;
  }

  /// Save location result to cache
  Future<void> _cacheLocation(String provinceCode, String provinceName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cachedProvinceCodeKey, provinceCode);
      await prefs.setString(_cachedProvinceNameKey, provinceName);
      await prefs.setInt(
        _cachedTimestampKey,
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      // Ignore cache errors
    }
  }

  /// Clear cached location
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cachedProvinceCodeKey);
      await prefs.remove(_cachedProvinceNameKey);
      await prefs.remove(_cachedTimestampKey);
    } catch (e) {
      // Ignore cache errors
    }
  }

  /// Detect current location and return province
  Future<LocationResult> detectProvince({bool useCache = true}) async {
    // Check cache first
    if (useCache) {
      final cached = await getCachedLocation();
      if (cached != null) {
        return cached;
      }
    }

    // Check if location services are enabled
    final serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationResult.error(
        'Location services are disabled. Please enable location services in your device settings.',
      );
    }

    // Check and request permission
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return LocationResult.error(
          'Location permission denied. Please grant location access to detect your province automatically.',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return LocationResult.error(
        'Location permission permanently denied. Please enable location access in your device settings.',
      );
    }

    // Get current position
    Position position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } catch (e) {
      return LocationResult.error(
        'Unable to get current location. Please try again or select province manually.',
      );
    }

    // Reverse geocode to get address
    List<Placemark> placemarks;
    try {
      placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
    } catch (e) {
      return LocationResult.error(
        'Unable to determine location details. Please select province manually.',
      );
    }

    if (placemarks.isEmpty) {
      return LocationResult.error(
        'No location information found. Please select province manually.',
      );
    }

    final placemark = placemarks.first;

    // Check if in Canada
    final country = placemark.country?.toLowerCase() ?? '';
    final isoCountryCode = placemark.isoCountryCode?.toUpperCase() ?? '';

    if (country != 'canada' && isoCountryCode != 'CA') {
      return LocationResult.error(
        'You appear to be outside Canada. This app is designed for Canadian tax calculations.',
      );
    }

    // Get province from administrative area
    final adminArea = placemark.administrativeArea ?? '';

    if (adminArea.isEmpty) {
      return LocationResult.error(
        'Unable to determine province from location. Please select province manually.',
      );
    }

    // Convert province name to code
    final provinceCode = _getProvinceCode(adminArea);

    if (provinceCode == null) {
      return LocationResult.error(
        'Unrecognized province: $adminArea. Please select province manually.',
      );
    }

    final provinceName = _provinceCodeToName[provinceCode]!;

    // Cache the result
    await _cacheLocation(provinceCode, provinceName);

    return LocationResult.success(
      provinceCode: provinceCode,
      provinceName: provinceName,
    );
  }

  /// Convert province name or abbreviation to standard code
  String? _getProvinceCode(String input) {
    final normalized = input.toLowerCase().trim();

    // Direct lookup
    if (_provinceNameToCode.containsKey(normalized)) {
      return _provinceNameToCode[normalized];
    }

    // Partial match for longer names
    for (final entry in _provinceNameToCode.entries) {
      if (normalized.contains(entry.key) || entry.key.contains(normalized)) {
        return entry.value;
      }
    }

    return null;
  }

  /// Get province name from code
  static String? getProvinceName(String code) {
    return _provinceCodeToName[code.toUpperCase()];
  }

  /// Check if a province code is valid
  static bool isValidProvinceCode(String code) {
    return _provinceCodeToName.containsKey(code.toUpperCase());
  }

  /// Get all provinces as a list of (code, name) pairs
  static List<MapEntry<String, String>> getAllProvinces() {
    return _provinceCodeToName.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
  }
}
