import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:genui/genui.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/services/location_service.dart';
import '../../core/services/places_service.dart';
import '../../core/theme/map_style.dart';
import '../../core/theme/theme_controller.dart';
import '../../data/models/post_model.dart';
import '../../injection_container.dart';
import '../../repository/post_repository.dart';
import '../blocs/location/location_cubit.dart';
import '../blocs/map/map_navigation_cubit.dart';
import '../blocs/post/post_bloc.dart';
import '../blocs/search/search_bloc.dart';
import 'genui/incident_post_card_item.dart';
import 'genui/map_ai_service.dart';

enum _MapInputMode { search, ai }

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with WidgetsBindingObserver {
  static const CameraPosition _kDefaultLocation = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  static const String _assistantSurfaceId = 'map_assistant_surface';

  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();
  final TextEditingController _locationSearchController =
      TextEditingController();
  final TextEditingController _aiController = TextEditingController();
  final FocusNode _locationFocusNode = FocusNode();
  final FocusNode _aiFocusNode = FocusNode();
  final LocationService _locationService = sl<LocationService>();
  final PlacesService _placesService = sl<PlacesService>();
  final PostRepository _postRepository = sl<PostRepository>();

  late final Catalog _assistantCatalog;
  late final A2uiMessageProcessor _a2uiProcessor;
  late final MapAiService _mapAiService;

  List<Map<String, dynamic>> _suggestions = [];
  List<PostModel> _nearbyPosts = [];
  List<_ChatEntry> _chatEntries = [];
  CurrentLocationContext? _currentLocationContext;
  bool _isSearching = false;
  bool _showSuggestions = false;
  bool _isTrafficEnabled = false;
  bool _isAiLoading = false;
  bool _isAiPanelExpanded = false;
  bool _isRefreshingCurrentLocation = false;
  _MapInputMode _mode = _MapInputMode.search;
  String? _currentLocationContextKey;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _assistantCatalog = CoreCatalogItems.asCatalog().copyWith([
      incidentPostCardItem,
    ], catalogId: 'tracks.map.ai');
    _a2uiProcessor = A2uiMessageProcessor(catalogs: [_assistantCatalog]);
    _mapAiService = MapAiService(
      placesService: _placesService,
      postRepository: _postRepository,
    );
    _checkLocationStatus();
    _setInitialLocation();
    _locationFocusNode.addListener(() {
      if (!_locationFocusNode.hasFocus && mounted) {
        setState(() => _showSuggestions = false);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _debounce?.cancel();
    _locationSearchController.dispose();
    _aiController.dispose();
    _locationFocusNode.dispose();
    _aiFocusNode.dispose();
    _a2uiProcessor.dispose();
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
    if (enabled) {
      await _setInitialLocation();
    }
  }

  Future<void> _setInitialLocation() async {
    final locationCubit = context.read<LocationCubit>();
    final lastKnownLat = locationCubit.state.lastKnownLat;
    final lastKnownLng = locationCubit.state.lastKnownLng;

    if (lastKnownLat != null && lastKnownLng != null) {
      final knownLocation = LatLng(lastKnownLat, lastKnownLng);
      await _focusMap(knownLocation, zoom: 15);
      unawaited(_ensureCurrentLocationContext(currentLocation: knownLocation));
    }

    final enabled = await _locationService.isLocationServiceEnabled();
    if (!enabled) return;

    try {
      final position = await _locationService.getCurrentPosition();
      locationCubit.updateLocation(position.latitude, position.longitude);
      final currentLocation = LatLng(position.latitude, position.longitude);
      await _focusMap(currentLocation, zoom: 15);
      unawaited(
        _ensureCurrentLocationContext(
          currentLocation: currentLocation,
          forceRefresh: true,
        ),
      );
    } catch (_) {}
  }

  Future<void> _focusMap(LatLng target, {double zoom = 15}) async {
    try {
      final controller = await _controller.future;
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: target, zoom: zoom),
        ),
      );
    } catch (_) {}
  }

  Future<LatLng?> _resolveCurrentLocation() async {
    final locationCubit = context.read<LocationCubit>();
    final lastKnownLat = locationCubit.state.lastKnownLat;
    final lastKnownLng = locationCubit.state.lastKnownLng;
    if (lastKnownLat != null && lastKnownLng != null) {
      final currentLocation = LatLng(lastKnownLat, lastKnownLng);
      if (_currentLocationContext == null) {
        unawaited(
          _ensureCurrentLocationContext(currentLocation: currentLocation),
        );
      }
      return currentLocation;
    }

    final enabled = await _locationService.isLocationServiceEnabled();
    if (!enabled) return null;

    try {
      final position = await _locationService.getCurrentPosition();
      locationCubit.updateLocation(position.latitude, position.longitude);
      final currentLocation = LatLng(position.latitude, position.longitude);
      unawaited(
        _ensureCurrentLocationContext(
          currentLocation: currentLocation,
          forceRefresh: true,
        ),
      );
      return currentLocation;
    } catch (_) {
      return null;
    }
  }

  Future<CurrentLocationContext?> _ensureCurrentLocationContext({
    LatLng? currentLocation,
    bool forceRefresh = false,
  }) async {
    final location = currentLocation ?? await _resolveCurrentLocation();
    if (location == null) {
      if (mounted) {
        setState(() {
          _currentLocationContext = null;
          _currentLocationContextKey = null;
          _isRefreshingCurrentLocation = false;
        });
      }
      return null;
    }

    final locationKey =
        '${location.latitude.toStringAsFixed(5)},${location.longitude.toStringAsFixed(5)}';
    if (!forceRefresh &&
        _currentLocationContext != null &&
        _currentLocationContextKey == locationKey) {
      return _currentLocationContext;
    }

    if (mounted) {
      setState(() {
        _isRefreshingCurrentLocation = true;
        _currentLocationContextKey = locationKey;
        _currentLocationContext = CurrentLocationContext(
          lat: location.latitude,
          lng: location.longitude,
          label: _currentLocationContext?.label,
        );
      });
    }

    final label = await _placesService.reverseGeocodeLocation(
      lat: location.latitude,
      lng: location.longitude,
    );
    final resolvedContext = CurrentLocationContext(
      lat: location.latitude,
      lng: location.longitude,
      label: label,
    );

    if (!mounted) {
      return resolvedContext;
    }

    if (_currentLocationContextKey == locationKey) {
      setState(() {
        _currentLocationContext = resolvedContext;
        _isRefreshingCurrentLocation = false;
      });
    }

    return resolvedContext;
  }

  void _toggleMode(_MapInputMode mode) {
    if (_mode == mode) return;

    setState(() {
      _mode = mode;
      _showSuggestions = false;
      _suggestions = [];
      _isSearching = false;
      _isAiPanelExpanded = mode == _MapInputMode.ai;
    });

    if (mode == _MapInputMode.search) {
      FocusScope.of(context).requestFocus(_locationFocusNode);
    } else {
      unawaited(_ensureCurrentLocationContext());
      FocusScope.of(context).requestFocus(_aiFocusNode);
    }
  }

  void _onSearchChanged(String query) {
    if (_mode != _MapInputMode.search) return;

    if (_debounce?.isActive ?? false) {
      _debounce!.cancel();
    }

    _debounce = Timer(const Duration(milliseconds: 350), () async {
      if (query.trim().isEmpty) {
        if (!mounted) return;
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
      if (!mounted) return;

      setState(() {
        _suggestions = suggestions;
        _isSearching = false;
      });
    });
  }

  Future<void> _selectSuggestion(Map<String, dynamic> suggestion) async {
    final placeId = suggestion['placeId'];
    final description = suggestion['text']?['text'] as String? ?? '';
    final locationState = context.read<LocationCubit>().state;
    final navigationCubit = context.read<MapNavigationCubit>();

    setState(() {
      _locationSearchController.text = description;
      _suggestions = [];
      _showSuggestions = false;
    });

    FocusScope.of(context).unfocus();

    final details = await _placesService.getPlaceDetails(placeId);
    if (details == null) return;

    final destination = LatLng(details['lat']!, details['lng']!);
    await _focusMap(destination);
    if (!mounted) return;

    if (locationState.lastKnownLat != null &&
        locationState.lastKnownLng != null) {
      await navigationCubit.startNavigation(
        origin: LatLng(
          locationState.lastKnownLat!,
          locationState.lastKnownLng!,
        ),
        destination: destination,
        destinationName: description,
      );
    }
  }

  Future<void> _sendAiPrompt() async {
    final prompt = _aiController.text.trim();
    if (prompt.isEmpty || _isAiLoading) return;

    FocusScope.of(context).unfocus();
    _aiController.clear();
    setState(() {
      _chatEntries = [..._chatEntries, _ChatEntry(text: prompt, isUser: true)];
      _isAiLoading = true;
    });

    try {
      final currentLocationContext = await _ensureCurrentLocationContext();
      final response = await _mapAiService.sendPrompt(
        prompt,
        resolveCurrentLocation: _resolveCurrentLocation,
        currentLocationContext: currentLocationContext,
      );

      if (!mounted) return;

      setState(() {
        _chatEntries = [
          ..._chatEntries,
          _ChatEntry(text: response.assistantText, isUser: false),
        ];
        _nearbyPosts = response.posts;
      });

      if (response.usedTool) {
        _renderAssistantSurface(
          posts: response.posts,
          summary: response.assistantText,
          resolvedLabel: response.resolvedLabel,
        );

        if (response.lat != null && response.lng != null) {
          await _focusMap(LatLng(response.lat!, response.lng!), zoom: 14.5);
        }
      } else {
        _clearAssistantSurface();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _chatEntries = [
          ..._chatEntries,
          _ChatEntry(
            text: e.toString().replaceFirst('Bad state: ', ''),
            isUser: false,
          ),
        ];
      });
      _clearAssistantSurface();
    } finally {
      if (mounted) {
        setState(() => _isAiLoading = false);
      }
    }
  }

  Future<void> _openExternalNavigation(MapNavigationActive state) async {
    final origin = await _resolveCurrentLocation();
    final destination =
        '${state.destination.latitude},${state.destination.longitude}';

    final uri = Uri.parse(
      origin == null
          ? 'https://www.google.com/maps/dir/?api=1&destination=$destination&travelmode=driving'
          : 'https://www.google.com/maps/dir/?api=1&origin=${origin.latitude},${origin.longitude}&destination=$destination&travelmode=driving',
    );

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open navigation app.')),
      );
    }
  }

  void _resetAiConversation() {
    setState(() {
      _chatEntries = [];
      _nearbyPosts = [];
      _isAiLoading = false;
    });
    _aiController.clear();
    _mapAiService.resetConversation();
    _clearAssistantSurface();
  }

  void _clearAssistantSurface() {
    _a2uiProcessor.handleMessage(
      SurfaceDeletion(surfaceId: _assistantSurfaceId),
    );
  }

  void _renderAssistantSurface({
    required List<PostModel> posts,
    required String summary,
    String? resolvedLabel,
  }) {
    final components = <Component>[];
    final childIds = <String>[];

    components.add(
      Component(
        id: 'root',
        componentProperties: {
          'Column': {
            'children': {'explicitList': childIds},
            'alignment': 'stretch',
          },
        },
      ),
    );

    if (summary.trim().isNotEmpty) {
      childIds.add('summary_text');
      components.add(
        Component(
          id: 'summary_text',
          componentProperties: {
            'Text': {
              'text': {'literalString': summary},
              'usageHint': 'h5',
            },
          },
        ),
      );
    }

    if (resolvedLabel != null && resolvedLabel.trim().isNotEmpty) {
      childIds.add('location_text');
      components.add(
        Component(
          id: 'location_text',
          componentProperties: {
            'Text': {
              'text': {'literalString': 'Area: $resolvedLabel'},
              'usageHint': 'caption',
            },
          },
        ),
      );
    }

    if (posts.isEmpty) {
      childIds.add('empty_state');
      components.add(
        Component(
          id: 'empty_state',
          componentProperties: {
            'Text': {
              'text': {
                'literalString':
                    'No nearby incident posts were returned for this location.',
              },
            },
          },
        ),
      );
    } else {
      for (var index = 0; index < posts.length; index++) {
        final post = posts[index];
        final componentId = 'post_card_$index';
        childIds.add(componentId);
        components.add(
          Component(
            id: componentId,
            componentProperties: {
              'IncidentPostCard': {
                'incidentType': post.incidentType,
                'content': post.content,
                'severity': post.severity,
                'timestamp': post.timestamp,
                'address': post.address.formattedAddress ?? '',
                'imageUrl': post.absoluteImageUrl,
                'confirmCount': post.confirmCount,
                'replyCount': post.replyCount,
              },
            },
          ),
        );
      }
    }

    _a2uiProcessor.handleMessage(
      SurfaceUpdate(surfaceId: _assistantSurfaceId, components: components),
    );
    _a2uiProcessor.handleMessage(
      BeginRendering(
        surfaceId: _assistantSurfaceId,
        root: 'root',
        catalogId: _assistantCatalog.catalogId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final keyboardLift = keyboardInset > 0 ? keyboardInset + 12 : 16.0;
    final screenHeight = MediaQuery.sizeOf(context).height;

    final locationState = context.watch<LocationCubit>().state;
    final searchState = context.watch<SearchBloc>().state;
    final postState = context.watch<PostBloc>().state;
    final navState = context.watch<MapNavigationCubit>().state;
    final assistantSurface = _a2uiProcessor
        .getSurfaceNotifier(_assistantSurfaceId)
        .value;
    final hasAssistantSurface =
        assistantSurface != null && assistantSurface.rootComponentId != null;

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

    final Map<String, dynamic> allPostsMap = {};
    for (final post in postState.posts) {
      allPostsMap[post.id] = post;
    }
    for (final item in searchState.results) {
      if (item is PostModel) {
        allPostsMap[item.id] = item;
      } else if (item is Map<String, dynamic>) {
        try {
          final parsed = PostModel.fromJson(item);
          allPostsMap[parsed.id] = parsed;
        } catch (_) {}
      }
    }
    for (final post in _nearbyPosts) {
      allPostsMap[post.id] = post;
    }

    final showSuggestions =
        _mode == _MapInputMode.search && (_showSuggestions || _isSearching);
    final showAiPanel =
        _mode == _MapInputMode.ai &&
        (_chatEntries.isNotEmpty || _isAiLoading || hasAssistantSurface);
    final showAiLocationCard = _mode == _MapInputMode.ai && !showAiPanel;
    final aiPanelHeight = _resolveAiPanelHeight(
      screenHeight: screenHeight,
      keyboardInset: keyboardInset,
    );

    final overlayHeight =
        76 +
        (showSuggestions ? 240 : 0) +
        (showAiLocationCard ? 64 : 0) +
        (showAiPanel ? aiPanelHeight.round() : 0) +
        (navState is MapNavigationActive ? 132 : 0);

    final markers = _createMarkers(allPostsMap.values.toList());

    return Scaffold(
      body: Stack(
        children: [
          ValueListenableBuilder<ThemeState>(
            valueListenable: ThemeController.instance,
            builder: (context, themeState, child) {
              if (_controller.isCompleted) {
                _controller.future.then((googleController) {
                  googleController.setMapStyle(MapStyle.getStyle(context));
                });
              }

              final polylines = <Polyline>{};
              if (navState is MapNavigationActive) {
                polylines.add(
                  Polyline(
                    polylineId: const PolylineId('route'),
                    points: navState.polylinePoints,
                    color: theme.primaryColor,
                    width: 5,
                  ),
                );
              }

              return GoogleMap(
                mapType: MapType.normal,
                initialCameraPosition: initialPos,
                onMapCreated: (controller) {
                  if (!_controller.isCompleted) {
                    _controller.complete(controller);
                  }
                  controller.setMapStyle(MapStyle.getStyle(context));
                },
                onTap: (_) {
                  FocusScope.of(context).unfocus();
                  if (_showSuggestions) {
                    setState(() => _showSuggestions = false);
                  }
                },
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                trafficEnabled: _isTrafficEnabled,
                markers: markers,
                polylines: polylines,
                padding: EdgeInsets.only(
                  top: 24,
                  bottom: overlayHeight.toDouble(),
                ),
              );
            },
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 16,
            right: 20,
            child: _buildFloatingActions(theme),
          ),
          if (navState is MapNavigationActive)
            Positioned(
              left: 16,
              right: 16,
              bottom: keyboardLift + 92,
              child: _buildNavigationCard(theme, navState),
            ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: AnimatedPadding(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.only(bottom: keyboardInset),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showAiPanel) _buildAiPanel(theme, isDark, aiPanelHeight),
                  if (showAiLocationCard)
                    _buildAiLocationContext(theme, isDark, embedded: false),
                  if (showSuggestions) _buildSuggestionsList(theme, isDark),
                  _buildBottomComposer(theme),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomComposer(ThemeData theme) {
    final isAiMode = _mode == _MapInputMode.ai;
    final controller = isAiMode ? _aiController : _locationSearchController;

    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 0.5,
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    key: ValueKey(_mode),
                    controller: controller,
                    focusNode: isAiMode ? _aiFocusNode : _locationFocusNode,
                    onChanged: isAiMode ? null : _onSearchChanged,
                    onSubmitted: (_) {
                      if (isAiMode) {
                        _sendAiPrompt();
                      }
                    },
                    textInputAction: isAiMode
                        ? TextInputAction.send
                        : TextInputAction.search,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.2,
                    ),
                    decoration: InputDecoration(
                      hintText: isAiMode
                          ? 'Ask AI about incidents...'
                          : 'Search location...',
                      hintStyle: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.hintColor.withValues(alpha: 0.5),
                        fontWeight: FontWeight.w400,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _buildModeToggle(),
                const SizedBox(width: 8),
                _buildSendButton(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSendButton(ThemeData theme) {
    final isAiMode = _mode == _MapInputMode.ai;
    final isLoading = isAiMode ? _isAiLoading : _isSearching;

    return GestureDetector(
      onTap: isLoading
          ? null
          : (isAiMode
                ? _sendAiPrompt
                : null), // Search happens auto on change, but button can trigger if needed
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.8,
          ),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: isLoading
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.colorScheme.primary,
                  ),
                )
              : Icon(
                  isAiMode ? Icons.arrow_upward_rounded : Icons.search_rounded,
                  size: 20,
                  color: isAiMode
                      ? const Color(0xFFE87722)
                      : const Color(0xFF12786F),
                ),
        ),
      ),
    );
  }

  Widget _buildModeToggle() {
    final theme = Theme.of(context);
    final isSearch = _mode == _MapInputMode.search;
    final color = isSearch ? const Color(0xFF12786F) : const Color(0xFFE87722);

    return PopupMenuButton<_MapInputMode>(
      initialValue: _mode,
      onSelected: _toggleMode,
      offset: const Offset(0, -110),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: _MapInputMode.search,
          child: Row(
            children: [
              const Icon(
                Icons.map_outlined,
                size: 18,
                color: Color(0xFF12786F),
              ),
              const SizedBox(width: 10),
              Text(
                'Map',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF12786F),
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: _MapInputMode.ai,
          child: Row(
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                size: 18,
                color: Color(0xFFE87722),
              ),
              const SizedBox(width: 10),
              Text(
                'AI',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFE87722),
                ),
              ),
            ],
          ),
        ),
      ],
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSearch ? Icons.map_outlined : Icons.auto_awesome_rounded,
              size: 16,
              color: color,
            ),
            const SizedBox(width: 6),
            Text(
              isSearch ? 'Map' : 'AI',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: color),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionsList(ThemeData theme, bool isDark) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 240),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surface.withValues(alpha: 0.96)
            : Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: ListView.separated(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            itemCount: _suggestions.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              indent: 60,
              color: theme.dividerColor.withValues(alpha: 0.08),
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
                leading: const Icon(Icons.location_on_rounded),
                title: Text(
                  mainText,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(secondaryText),
                onTap: () => _selectSuggestion(suggestion),
              );
            },
          ),
        ),
      ),
    );
  }

  double _resolveAiPanelHeight({
    required double screenHeight,
    required double keyboardInset,
  }) {
    final collapsedHeight = keyboardInset > 0 ? 240.0 : 260.0;
    final expandedHeight = keyboardInset > 0
        ? (screenHeight * 0.5).clamp(300.0, 420.0)
        : (screenHeight * 0.62).clamp(340.0, 520.0);

    return _isAiPanelExpanded ? expandedHeight : collapsedHeight;
  }

  Widget _buildAiPanel(ThemeData theme, bool isDark, double panelHeight) {
    return Container(
      constraints: BoxConstraints(maxHeight: panelHeight),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surface.withValues(alpha: 0.96)
            : Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.13),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            constraints: BoxConstraints(maxHeight: panelHeight),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome_rounded,
                        color: Color(0xFFE87722),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Map AI',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => setState(
                          () => _isAiPanelExpanded = !_isAiPanelExpanded,
                        ),
                        tooltip: _isAiPanelExpanded
                            ? 'Collapse chat'
                            : 'Expand chat',
                        icon: Icon(
                          _isAiPanelExpanded
                              ? Icons.fullscreen_exit_rounded
                              : Icons.open_in_full_rounded,
                          color: const Color(0xFFE87722),
                        ),
                      ),
                      TextButton(
                        onPressed: _resetAiConversation,
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildAiLocationContext(theme, isDark, embedded: true),
                  const SizedBox(height: 8),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        for (final entry in _chatEntries)
                          _buildChatBubble(theme, entry),
                        if (_isAiLoading) _buildTypingBubble(theme),
                        ValueListenableBuilder<UiDefinition?>(
                          valueListenable: _a2uiProcessor.getSurfaceNotifier(
                            _assistantSurfaceId,
                          ),
                          builder: (context, definition, child) {
                            if (definition == null ||
                                definition.rootComponentId == null) {
                              return const SizedBox.shrink();
                            }

                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: GenUiSurface(
                                host: _a2uiProcessor,
                                surfaceId: _assistantSurfaceId,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAiLocationContext(
    ThemeData theme,
    bool isDark, {
    required bool embedded,
  }) {
    final label = _currentLocationContext?.label?.trim();
    final locationText = switch ((
      _currentLocationContext,
      _isRefreshingCurrentLocation,
    )) {
      (_, true) => 'Locating your current position...',
      (null, false) => 'Current location unavailable',
      _ when label != null && label.isNotEmpty => label,
      _ =>
        '${_currentLocationContext!.lat.toStringAsFixed(4)}, ${_currentLocationContext!.lng.toStringAsFixed(4)}',
    };

    return Container(
      margin: EdgeInsets.only(bottom: embedded ? 0 : 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.48)
            : const Color(0xFFFFF4EB).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE87722).withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFE87722).withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.my_location_rounded,
              color: Color(0xFFE87722),
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Current Location for AI',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFE87722),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  locationText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _isRefreshingCurrentLocation
                ? null
                : () => _ensureCurrentLocationContext(forceRefresh: true),
            icon: _isRefreshingCurrentLocation
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh current location',
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(ThemeData theme, _ChatEntry entry) {
    final alignment = entry.isUser
        ? Alignment.centerRight
        : Alignment.centerLeft;
    final bubbleColor = entry.isUser
        ? theme.colorScheme.primary
        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.85);
    final textColor = entry.isUser
        ? Colors.white
        : theme.textTheme.bodyMedium?.color;

    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          entry.text,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: textColor,
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
      ),
    );
  }

  Widget _buildTypingBubble(ThemeData theme) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.85,
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildFloatingActions(ThemeData theme) {
    return Column(
      children: [
        _buildGlassIconBtn(
          theme,
          _isTrafficEnabled ? Icons.traffic_rounded : Icons.traffic_outlined,
          color: _isTrafficEnabled ? theme.primaryColor : null,
          onTap: () => setState(() => _isTrafficEnabled = !_isTrafficEnabled),
        ),
        const SizedBox(height: 12),
        _buildGlassIconBtn(
          theme,
          Icons.my_location_rounded,
          color: theme.primaryColor,
          onTap: _setInitialLocation,
        ),
      ],
    );
  }

  Widget _buildNavigationCard(ThemeData theme, MapNavigationActive state) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          color: theme.scaffoldBackgroundColor.withValues(alpha: 0.92),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.destinationName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${state.duration} (${state.distance})',
                          style: const TextStyle(color: Colors.greenAccent),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () =>
                        context.read<MapNavigationCubit>().cancelNavigation(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _openExternalNavigation(state),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Start Navigation',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Set<Marker> _createMarkers(List<dynamic> results) {
    final markers = <Marker>{};
    for (final item in results) {
      double? lat;
      double? lng;
      String id = '';
      String title = 'Incident';
      String snippet = '';

      if (item is PostModel) {
        id = item.id;
        lat = (item.location?['lat'] as num?)?.toDouble();
        lng = (item.location?['lng'] as num?)?.toDouble();
        title = item.incidentType;
        snippet = item.content;
      } else if (item is Map<String, dynamic>) {
        id = item['id']?.toString() ?? '';
        lat = (item['lat'] as num?)?.toDouble();
        lng = (item['lng'] as num?)?.toDouble();
        title = item['incidentType']?.toString() ?? title;
        snippet = item['content']?.toString() ?? snippet;
      }

      if (id.isEmpty || lat == null || lng == null) continue;

      markers.add(
        Marker(
          markerId: MarkerId(id),
          position: LatLng(lat, lng),
          infoWindow: InfoWindow(title: title, snippet: snippet),
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
            width: 52,
            height: 52,
            color: theme.scaffoldBackgroundColor.withValues(alpha: 0.86),
            child: Icon(icon, color: color ?? theme.iconTheme.color),
          ),
        ),
      ),
    );
  }
}

class _ChatEntry {
  const _ChatEntry({required this.text, required this.isUser});

  final String text;
  final bool isUser;
}
