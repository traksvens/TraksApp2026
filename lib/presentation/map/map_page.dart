import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/services/location_service.dart';
import '../../core/services/places_service.dart';
import '../../injection_container.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/post/post_bloc.dart';
import '../blocs/search/search_bloc.dart';
import '../blocs/location/location_cubit.dart';
import '../../data/models/post_model.dart';
import '../../core/theme/map_style.dart';
import '../../core/theme/theme_controller.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with WidgetsBindingObserver {
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();
  bool _isLocationServiceEnabled = true;
  final TextEditingController _searchController = TextEditingController();
  final LocationService _locationService = sl<LocationService>();
  final PlacesService _placesService = sl<PlacesService>();

  List<Map<String, dynamic>> _suggestions = [];
  bool _isSearching = false;
  bool _showSuggestions = false;
  Timer? _debounce;

  static const CameraPosition _kDefaultLocation = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkLocationStatus();
    _setInitialLocation();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkLocationStatus();
    }
  }

  Future<void> _checkLocationStatus() async {
    final enabled = await _locationService.isLocationServiceEnabled();
    setState(() => _isLocationServiceEnabled = enabled);
    if (enabled) {
      // If enabled, refresh location
      _setInitialLocation();
    }
  }

  Future<void> _setInitialLocation() async {
    // 1. Try to restore last known location immediately
    final locationCubit = context.read<LocationCubit>();
    if (locationCubit.state.lastKnownLat != null &&
        locationCubit.state.lastKnownLng != null) {
      // We don't animate here because we want to set it as 'initial' if possible,
      // or just move there if we haven't yet.
      // But if map controller is ready, we can move.
      try {
        final GoogleMapController controller = await _controller.future;
        controller.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(
              locationCubit.state.lastKnownLat!,
              locationCubit.state.lastKnownLng!,
            ),
            15,
          ),
        );
      } catch (_) {}
    }

    // 2. Check service and get fresh location
    final enabled = await _locationService.isLocationServiceEnabled();
    setState(() => _isLocationServiceEnabled = enabled);

    if (!enabled) return;

    try {
      final position = await _locationService.getCurrentPosition();

      // Update Cubit
      locationCubit.updateLocation(position.latitude, position.longitude);

      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 15,
          ),
        ),
      );
    } catch (e) {
      // Fallback or show error
      print("Location fetch error: $e");
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.isEmpty) {
        setState(() {
          _suggestions = [];
          _isSearching = false;
          _showSuggestions = false;
        });
        return;
      }

      setState(() {
        _isSearching = true;
        _showSuggestions = true;
      });
      final suggestions = await _placesService.getAutocompleteSuggestions(
        query,
      );
      print(
        'DEBUG: Found ${suggestions.length} suggestions for query "$query"',
      );
      if (suggestions.isNotEmpty) {
        print('DEBUG: First suggestion: ${suggestions.first['description']}');
      }
      setState(() {
        _suggestions = suggestions;
        _isSearching = false;
      });
    });
  }

  Future<void> _selectSuggestion(Map<String, dynamic> suggestion) async {
    final placeId = suggestion['placeId'];
    final description = suggestion['text']?['text'] ?? '';

    setState(() {
      _searchController.text = description;
      _suggestions = [];
      _showSuggestions = false;
    });

    FocusScope.of(context).unfocus();

    final details = await _placesService.getPlaceDetails(placeId);
    if (details != null) {
      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(details['lat']!, details['lng']!),
          15,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Builder(
        builder: (context) {
          final searchState = context.watch<SearchBloc>().state;
          final postState = context.watch<PostBloc>().state;
          final locationState = context.watch<LocationCubit>().state;

          final initialPos =
              (locationState.lastKnownLat != null &&
                  locationState.lastKnownLng != null)
              ? CameraPosition(
                  target: LatLng(
                    locationState.lastKnownLat!,
                    locationState.lastKnownLng!,
                  ),
                  zoom: 15,
                )
              : _kDefaultLocation;

          // Merge all available posts from both Bloc states to ensure universal visibility
          final Map<String, dynamic> allPostsMap = {};

          // 1. Add posts from global feed
          for (var p in postState.posts) {
            allPostsMap[p.id] = p;
          }

          // 2. Add/Override with search results (might have fresher or raw vector data)
          for (var item in searchState.results) {
            String? id;
            if (item is PostModel) {
              id = item.id;
            } else if (item is Map<String, dynamic>) {
              id = item['id']?.toString();
            }
            if (id != null) {
              allPostsMap[id] = item;
            }
          }

          final markers = _createMarkers(allPostsMap.values.toList());
          print(
            'DEBUG: Universal Map Coverage - Merged ${allPostsMap.length} unique items',
          );

          return Stack(
            children: [
              ValueListenableBuilder<ThemeState>(
                valueListenable: ThemeController.instance,
                builder: (context, themeState, child) {
                  // If the map is already built, explicitly push the new style directly to the active controller
                  if (_controller.isCompleted) {
                    _controller.future.then((googleController) {
                      googleController.setMapStyle(MapStyle.getStyle(context));
                    });
                  }

                  return GoogleMap(
                    mapType: MapType.normal,
                    initialCameraPosition: initialPos,
                    onMapCreated: (GoogleMapController controller) {
                      if (!_controller.isCompleted) {
                        _controller.complete(controller);
                      }
                      controller.setMapStyle(MapStyle.getStyle(context));
                    },
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    markers: markers,
                    padding: const EdgeInsets.only(top: 100),
                  );
                },
              ),

              // Floating Search Bar
              Positioned(
                top: MediaQuery.of(context).padding.top + 10,
                left: 16,
                right: 16,
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            height: 54,
                            color: theme.scaffoldBackgroundColor.withOpacity(
                              0.85,
                            ),
                            child: TextField(
                              controller: _searchController,
                              onChanged: _onSearchChanged,
                              style: theme.textTheme.bodyLarge,
                              decoration: InputDecoration(
                                hintText: "Search location...",
                                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.hintColor.withOpacity(0.5),
                                ),
                                prefixIcon: Icon(
                                  Icons.search_rounded,
                                  color: theme.primaryColor,
                                ),
                                suffixIcon: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (_isSearching)
                                      const Padding(
                                        padding: EdgeInsets.all(12.0),
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      ),
                                    if (_searchController.text.isNotEmpty)
                                      IconButton(
                                        icon: const Icon(Icons.close_rounded),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() {
                                            _suggestions = [];
                                            _showSuggestions = false;
                                          });
                                        },
                                      ),
                                  ],
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 15,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Suggestions List
                    if (_showSuggestions &&
                        (_suggestions.isNotEmpty || _isSearching))
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        constraints: const BoxConstraints(maxHeight: 350),
                        decoration: BoxDecoration(
                          color: isDark
                              ? theme.colorScheme.surface.withOpacity(0.95)
                              : Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: theme.dividerColor.withOpacity(0.05),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 30,
                              offset: const Offset(0, 15),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: _suggestions.isEmpty && !_isSearching
                                ? Padding(
                                    padding: const EdgeInsets.all(20.0),
                                    child: Text(
                                      "No results found",
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(color: theme.hintColor),
                                      textAlign: TextAlign.center,
                                    ),
                                  )
                                : ListView.separated(
                                    padding: EdgeInsets.zero,
                                    shrinkWrap: true,
                                    itemCount: _suggestions.length,
                                    separatorBuilder: (context, index) =>
                                        Divider(
                                          height: 1,
                                          indent: 60,
                                          color: theme.dividerColor.withOpacity(
                                            0.05,
                                          ),
                                        ),
                                    itemBuilder: (context, index) {
                                      final suggestion = _suggestions[index];
                                      final mainText =
                                          suggestion['structuredFormat']?['mainText']?['text'] ??
                                          suggestion['text']?['text'] ??
                                          'Unknown location';
                                      final secondaryText =
                                          suggestion['structuredFormat']?['secondaryText']?['text'] ??
                                          '';

                                      return ListTile(
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 20,
                                              vertical: 4,
                                            ),
                                        leading: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: theme.primaryColor
                                                .withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.location_on_rounded,
                                            size: 20,
                                            color: theme.primaryColor,
                                          ),
                                        ),
                                        title: Text(
                                          mainText,
                                          style: theme.textTheme.titleSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        subtitle: Text(
                                          secondaryText,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: theme.hintColor,
                                              ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        onTap: () =>
                                            _selectSuggestion(suggestion),
                                      );
                                    },
                                  ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Floating Action Buttons (Right Side)
              Positioned(
                right: 20,
                bottom: 110, // Increased to avoid navbar
                child: Column(
                  children: [
                    _buildGlassIconBtn(
                      theme,
                      Icons.add,
                      onTap: () async {
                        final GoogleMapController controller =
                            await _controller.future;
                        controller.animateCamera(CameraUpdate.zoomIn());
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildGlassIconBtn(
                      theme,
                      Icons.remove,
                      onTap: () async {
                        final GoogleMapController controller =
                            await _controller.future;
                        controller.animateCamera(CameraUpdate.zoomOut());
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildGlassIconBtn(
                      theme,
                      Icons.my_location,
                      color: theme.primaryColor,
                      onTap: () => _setInitialLocation(),
                    ),
                  ],
                ),
              ),
              // Location Service Warning
              if (!_isLocationServiceEnabled)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 80,
                  left: 16,
                  right: 16,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.9),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.location_off_rounded,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "Location services are off",
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () =>
                                  _locationService.openLocationSettings(),
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.2,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                "Turn On",
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Set<Marker> _createMarkers(List<dynamic> results) {
    final markers = <Marker>{};

    for (final item in results) {
      String id = '';
      double? lat;
      double? lng;
      String severity = 'medium';
      String title = 'Incident';
      String snippet = '';

      if (item is PostModel) {
        id = item.id;
        lat = item.location?['lat'] as double?;
        lng = item.location?['lng'] as double?;
        severity = item.severity;
        title = item.incidentType;
        snippet = item.content;
      } else if (item is Map<String, dynamic>) {
        // Handle raw vector search result (match)
        id = item['id']?.toString() ?? UniqueKey().toString();
        final metadata = item['metadata'] as Map<String, dynamic>?;

        if (metadata != null) {
          lat = metadata['lat'] as double?;
          lng = metadata['lng'] as double?;
          severity = metadata['severity']?.toString() ?? 'medium';
          title = metadata['incidentType']?.toString() ?? 'Incident';
          snippet = metadata['text']?.toString() ?? '';
        } else {
          // Check top level if metadata is missing (depends on serialization)
          lat = item['lat'] as double?;
          lng = item['lng'] as double?;
        }
      }

      if (lat == null || lng == null) continue;

      double hue;
      switch (severity.toLowerCase()) {
        case 'critical':
          hue = BitmapDescriptor.hueRed;
          break;
        case 'high':
          hue = BitmapDescriptor.hueOrange;
          break;
        case 'medium':
          hue = BitmapDescriptor.hueYellow;
          break;
        case 'low':
          hue = BitmapDescriptor.hueGreen;
          break;
        default:
          hue = BitmapDescriptor.hueAzure;
      }

      markers.add(
        Marker(
          markerId: MarkerId(id),
          position: LatLng(lat, lng),
          icon: BitmapDescriptor.defaultMarkerWithHue(hue),
          infoWindow: InfoWindow(
            title: '[${severity.toUpperCase()}] $title',
            snippet: snippet,
          ),
        ),
      );
    }

    return markers;
  }

  Widget _buildGlassIconBtn(
    ThemeData theme,
    IconData icon, {
    Color? color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 50,
            height: 50,
            color: theme.scaffoldBackgroundColor.withOpacity(0.8),
            child: Icon(icon, color: color ?? theme.iconTheme.color),
          ),
        ),
      ),
    );
  }
}
