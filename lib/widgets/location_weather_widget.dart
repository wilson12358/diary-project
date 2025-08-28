import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import '../services/location_service.dart';
import '../services/weather_service.dart';

class LocationWeatherWidget extends StatefulWidget {
  final Map<String, dynamic>? location;
  final Map<String, dynamic>? weather;
  final Function(Map<String, dynamic>? location, Map<String, dynamic>? weather) onDataChanged;

  const LocationWeatherWidget({
    Key? key,
    this.location,
    this.weather,
    required this.onDataChanged,
  }) : super(key: key);

  @override
  State<LocationWeatherWidget> createState() => _LocationWeatherWidgetState();
}

class _LocationWeatherWidgetState extends State<LocationWeatherWidget> {
  final LocationService _locationService = LocationService();
  final WeatherService _weatherService = WeatherService();
  
  bool _isLoading = false;
  bool _hasLocationPermission = false;
  bool _isDisposed = false;
  Map<String, dynamic>? _currentLocation;
  Map<String, dynamic>? _currentWeather;
  Timer? _autoUpdateTimer;

  @override
  void initState() {
    super.initState();
    _currentLocation = widget.location;
    _currentWeather = widget.weather;
    _checkLocationPermission();
    
    // Auto-detect location and weather after a short delay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoDetectLocationAndWeather();
    });
  }

  /// Auto-detect location and weather when widget initializes
  Future<void> _autoDetectLocationAndWeather() async {
    // Wait a bit for the widget to be fully initialized
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (mounted && !_isDisposed && _hasLocationPermission) {
      // Only auto-detect if we don't already have data
      if (_currentLocation == null || _currentWeather == null) {
        if (kDebugMode) {
          print('📍 Auto-detecting location and weather...');
        }
        await _getLocationAndWeather();
      }
      
      // Start periodic auto-updates (every 10 minutes)
      _startAutoUpdateTimer();
    }
  }

  /// Start periodic auto-updates for location and weather
  void _startAutoUpdateTimer() {
    _autoUpdateTimer?.cancel();
    _autoUpdateTimer = Timer.periodic(const Duration(minutes: 10), (timer) {
      if (mounted && !_isDisposed && _hasLocationPermission) {
        if (kDebugMode) {
          print('📍 Auto-updating location and weather...');
        }
        _getLocationAndWeather();
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _checkLocationPermission() async {
    final permission = await _locationService.checkPermission();
    if (mounted && !_isDisposed) {
      setState(() {
        _hasLocationPermission = permission != LocationPermission.denied && 
                                permission != LocationPermission.deniedForever;
      });
    }
  }

  Future<void> _getLocationAndWeather() async {
    if (_isLoading || _isDisposed) return;

    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Get location data
      final locationData = await _locationService.getLocationData();
      
      if (!mounted || _isDisposed) return;
      
      if (locationData != null) {
        setState(() {
          _currentLocation = locationData;
        });

        // Get weather data for the location
        final weatherData = await _weatherService.getCurrentWeather(
          locationData['latitude'],
          locationData['longitude'],
        );

        if (!mounted || _isDisposed) return;

        if (weatherData != null) {
          setState(() {
            _currentWeather = weatherData;
          });
        }

        // Notify parent of data changes
        if (mounted && !_isDisposed) {
          if (kDebugMode) {
            print('📍 LocationWeatherWidget: Notifying parent of data changes');
            print('📍 Location: $_currentLocation');
            print('🌤️ Weather: $_currentWeather');
          }
          widget.onDataChanged(_currentLocation, _currentWeather);
        }
      }
    } catch (e) {
      print('Error getting location and weather: $e');
      if (mounted && !_isDisposed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to get location: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted && !_isDisposed) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _autoUpdateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Compact Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFCA032).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.location_on,
                  color: Color(0xFFFCA032),
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Location & Weather',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!_hasLocationPermission)
                Icon(
                  Icons.location_off,
                  color: Colors.grey[400],
                  size: 16,
                ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Compact Location and Weather Display
          if (_currentLocation != null || _currentWeather != null) ...[
            _buildCompactLocationWeather(),
            const SizedBox(height: 12),
          ],
          
          // Compact Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _hasLocationPermission ? _getLocationAndWeather : null,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.refresh, size: 14),
                  label: Text(_isLoading ? 'Updating...' : 'Update'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFCA032),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _currentLocation != null || _currentWeather != null
                      ? () {
                          setState(() {
                            _currentLocation = null;
                            _currentWeather = null;
                          });
                          widget.onDataChanged(null, null);
                        }
                      : null,
                  icon: const Icon(Icons.clear, size: 14),
                  label: const Text('Clear'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                    side: BorderSide(color: Colors.grey[300]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  ),
                ),
              ),
            ],
          ),
          
          // Permission Warning
          if (!_hasLocationPermission) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning,
                    color: Colors.orange[700],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Location permission required to get weather data',
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build compact location and weather display
  Widget _buildCompactLocationWeather() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey[200]!,
        ),
      ),
      child: Row(
        children: [
          // Location info
          if (_currentLocation != null) ...[
            Icon(
              Icons.location_city,
              color: Colors.blue[600],
              size: 16,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getLocationDisplayText(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ],
          
          // Weather info
          if (_currentWeather != null) ...[
            if (_currentLocation != null) const SizedBox(width: 12),
            Icon(
              Icons.wb_sunny,
              color: Colors.orange[600],
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              '${_currentWeather!['temperature']?.toStringAsFixed(1) ?? ''}°C',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Get compact location display text
  String _getLocationDisplayText() {
    if (_currentLocation == null) return '';
    
    final address = _currentLocation!['address'] as Map<String, dynamic>?;
    final city = address?['city'] ?? '';
    final state = address?['state'] ?? '';
    
    if (city.isNotEmpty && state.isNotEmpty) {
      return '$city, $state';
    } else if (city.isNotEmpty) {
      return city;
    } else {
      return 'Current Location';
    }
  }

  Widget _buildLocationInfo() {
    if (_currentLocation == null) return const SizedBox.shrink();

    final address = _currentLocation!['address'] as Map<String, dynamic>?;
    final city = address?['city'] ?? '';
    final state = address?['state'] ?? '';
    final country = address?['country'] ?? '';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.blue.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.location_city,
            color: Colors.blue[600],
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  city.isNotEmpty ? city : 'Current Location',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                if (state.isNotEmpty || country.isNotEmpty)
                  Text(
                    [state, country].where((s) => s.isNotEmpty).join(', '),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherInfo() {
    if (_currentWeather == null) return const SizedBox.shrink();

    final temp = _currentWeather!['temperature']?.toStringAsFixed(1);
    final description = _currentWeather!['description'] ?? '';
    final humidity = _currentWeather!['humidity'];
    final icon = _currentWeather!['icon'];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.green.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          if (icon != null)
            Image.network(
              _weatherService.getWeatherIconUrl(icon),
              width: 40,
              height: 40,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.wb_sunny,
                color: Colors.green[600],
                size: 40,
              ),
            )
          else
            Icon(
              Icons.wb_sunny,
              color: Colors.green[600],
              size: 40,
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (temp != null)
                  Text(
                    '${temp}°C',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                if (description.isNotEmpty)
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                if (humidity != null)
                  Text(
                    'Humidity: ${humidity}%',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
