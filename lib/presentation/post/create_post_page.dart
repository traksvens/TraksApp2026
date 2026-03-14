import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tracks_app/core/services/location_service.dart';
import 'package:tracks_app/core/services/places_service.dart';
import 'package:tracks_app/data/models/address_model.dart';
import 'package:tracks_app/data/models/post_model.dart';
import 'package:tracks_app/presentation/blocs/post/post_bloc.dart';
import 'package:tracks_app/presentation/blocs/post/post_event.dart';
import 'package:tracks_app/presentation/blocs/post/post_state.dart';
import 'package:tracks_app/presentation/blocs/auth/auth_bloc.dart';
import 'package:tracks_app/presentation/blocs/auth/auth_state.dart';
import 'package:tracks_app/injection_container.dart' as di;
import 'dart:async';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _contentController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  File? _selectedFile;
  bool _useCurrentLocation = true;
  Map<String, double>? _manualLocation;
  String _manualLocationName = '';
  final TextEditingController _locationSearchController =
      TextEditingController();
  List<Map<String, dynamic>> _locationSuggestions = [];
  Timer? _debounceTimer;

  String _incidentType = 'traffic';
  String _severity = 'medium';
  bool _isSubmitting = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final Map<String, IconData> _incidentIcons = {
    'traffic': Icons.traffic_rounded,
    'accident': Icons.car_crash_rounded,
    'fire': Icons.local_fire_department_rounded,
    'flood': Icons.flood_rounded,
    'other': Icons.campaign_rounded,
  };

  @override
  void initState() {
    super.initState();
    _checkInitialLocation();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutQuart,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutQuart),
    );

    _animController.forward();
  }

  Future<void> _checkInitialLocation() async {
    try {
      final locationService = di.sl<LocationService>();
      final permission = await locationService.checkPermission();
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        if (mounted) setState(() => _useCurrentLocation = true);
      } else {
        if (mounted) setState(() => _useCurrentLocation = false);
      }
    } catch (_) {
      if (mounted) setState(() => _useCurrentLocation = false);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _contentController.dispose();
    _locationSearchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedFile = File(image.path);
      });
    }
  }

  void _submitPost() async {
    if (_contentController.text.trim().isEmpty) return;

    setState(() {
      _isSubmitting = true;
    });

    Map<String, dynamic>? locationMap;

    if (_useCurrentLocation) {
      try {
        final locationService = di.sl<LocationService>();
        final position = await locationService.getCurrentPosition();
        locationMap = {'lat': position.latitude, 'lng': position.longitude};
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Could not fetch current location. Posting without it.',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } else if (_manualLocation != null) {
      locationMap = Map<String, dynamic>.from(_manualLocation!);
    }

    if (!mounted) return;

    // Get current user ID and metadata
    final authState = context.read<AuthBloc>().state;
    String userId = 'anonymous';
    String? userName;
    String? userAvatarUrl;

    if (authState is Authenticated) {
      final user = authState.user;
      userId = user.uid; // Always keep UID for identification

      if (user.displayName != null && user.displayName!.isNotEmpty) {
        userName = user.displayName;
      } else if (user.email != null && user.email!.isNotEmpty) {
        userName = user.email!.split('@').first;
      }

      if (user.photoURL != null && user.photoURL!.isNotEmpty) {
        userAvatarUrl = user.photoURL;
      }
    }

    final post = PostModel(
      id: '',
      userId: userId,
      userName: userName,
      userAvatarUrl: userAvatarUrl,
      severity: _severity,
      timestamp: DateTime.now().toIso8601String(),
      confirmCount: 0,
      refuteCount: 0,
      incidentType: _incidentType,
      replyCount: 0,
      ratedBy: const {},
      address: AddressModel(
        city: _manualLocationName,
      ), // Store the name if manual
      content: _contentController.text.trim(),
      location: locationMap,
    );

    if (mounted) {
      context.read<PostBloc>().add(CreatePost(post: post, file: _selectedFile));
    }
  }

  void _onLocationChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      if (query.length < 3) {
        setState(() => _locationSuggestions = []);
        return;
      }
      final suggestions =
          await di.sl<PlacesService>().getAutocompleteSuggestions(query);
      if (mounted) {
        setState(() => _locationSuggestions = suggestions);
      }
    });
  }

  void _selectLocation(Map<String, dynamic> suggestion) async {
    final placeId = suggestion['placeId'];
    final description = suggestion['text']['text'];

    // Clear keyboard and suggestions
    FocusScope.of(context).unfocus();
    setState(() {
      _locationSearchController.text = description;
      _locationSuggestions = [];
      _manualLocationName = description;
    });

    final details = await di.sl<PlacesService>().getPlaceDetails(placeId);
    if (details != null && mounted) {
      setState(() {
        _manualLocation = details;
      });
    }
  }

  Future<void> _toggleLocation() async {
    if (!_useCurrentLocation) {
      // Trying to enable current location
      try {
        final locationService = di.sl<LocationService>();
        await locationService.getCurrentPosition();
        setState(() {
          _useCurrentLocation = true;
          _manualLocation = null;
          _locationSearchController.clear();
          _locationSuggestions = [];
        });
      } catch (e) {
        if (mounted) {
          final theme = Theme.of(context);
          final isServiceDisabled = e.toString().contains(
                'Location services are disabled',
              );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isServiceDisabled
                    ? 'Location services are turned off.'
                    : 'Location permission required: $e',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: theme.colorScheme.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              action: isServiceDisabled
                  ? SnackBarAction(
                      label: 'TURN ON',
                      textColor: theme.colorScheme.onSurface,
                      onPressed: () async =>
                          await Geolocator.openLocationSettings(),
                    )
                  : null,
            ),
          );
        }
      }
    } else {
      setState(() => _useCurrentLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocListener<PostBloc, PostState>(
      listenWhen: (prev, curr) => prev.formStatus != curr.formStatus,
      listener: (context, state) {
        if (state.formStatus == PostFormStatus.success) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Report posted successfully!',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: theme.colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          );
        } else if (state.formStatus == PostFormStatus.failure) {
          setState(() {
            _isSubmitting = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.errorMessage ?? 'Submission failed',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: theme.colorScheme.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'New Report',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: theme.scaffoldBackgroundColor,
          surfaceTintColor: Colors.transparent,
          actions: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: _isSubmitting || _contentController.text.isEmpty
                      ? []
                      : [
                          BoxShadow(
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          )
                        ],
                ),
                child: FilledButton(
                  onPressed: _isSubmitting || _contentController.text.isEmpty
                      ? null
                      : _submitPost,
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    disabledBackgroundColor:
                        theme.colorScheme.surfaceContainerHighest,
                    foregroundColor: theme.colorScheme.onPrimary,
                    disabledForegroundColor:
                        theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                  ),
                  child: _isSubmitting
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(theme.colorScheme.onSurface),
                          ),
                        )
                      : const Text(
                          'Post',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                ),
              ),
            ),
          ],
        ),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      // Location Context Pill
                      const SizedBox(height: 12),

                      // Toggle section
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Current Location",
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  "Auto-attach your GPS coordinates",
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.hintColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _useCurrentLocation,
                            onChanged: (_) => _toggleLocation(),
                          ),
                        ],
                      ),

                      if (!_useCurrentLocation) ...[
                        const SizedBox(height: 16),
                        TextField(
                          controller: _locationSearchController,
                          onChanged: _onLocationChanged,
                          decoration: InputDecoration(
                            hintText: "Search incident location...",
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              size: 20,
                            ),
                            filled: true,
                            fillColor: theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.3),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                          ),
                        ),
                        if (_locationSuggestions.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: theme.dividerColor.withValues(
                                  alpha: 0.1,
                                ),
                              ),
                            ),
                            child: ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _locationSuggestions.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final suggestion = _locationSuggestions[index];
                                return ListTile(
                                  onTap: () => _selectLocation(suggestion),
                                  title: Text(
                                    suggestion['text']['text'] ?? '',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  subtitle: Text(
                                    suggestion['structuredFormat']
                                            ?['secondaryText']?['text'] ??
                                        '',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: theme.hintColor,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                      ],

                      const SizedBox(height: 16),

                      // Main Input
                      TextField(
                        controller: _contentController,
                        maxLines: null,
                        minLines: 3,
                        keyboardType: TextInputType.multiline,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontSize: 24,
                          fontWeight: FontWeight.w400,
                          height: 1.3,
                        ),
                        decoration: InputDecoration(
                          hintText: "What's happening?",
                          hintStyle: theme.textTheme.headlineSmall?.copyWith(
                            color: theme.hintColor.withValues(alpha: 0.5),
                            fontWeight: FontWeight.w400,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),

                      const SizedBox(height: 24),

                      // Image Preview
                      if (_selectedFile != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Stack(
                              children: [
                                Image.file(
                                  _selectedFile!,
                                  width: double.infinity,
                                  height: 250,
                                  fit: BoxFit.cover,
                                ),
                                Positioned(
                                  top: 12,
                                  right: 12,
                                  child: GestureDetector(
                                    onTap: () =>
                                        setState(() => _selectedFile = null),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.surface.withValues(
                                          alpha: 0.6,
                                        ),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: theme.colorScheme.onSurface
                                              .withValues(alpha: 0.24),
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.close_rounded,
                                        color: theme.colorScheme.onSurface,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Controls Section
                      Text(
                        "DETAILS",
                        style: theme.textTheme.labelSmall?.copyWith(
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.bold,
                          color: theme.hintColor,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Horizontal Scrollable Incident Types
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        clipBehavior: Clip.none,
                        child: Row(
                          children: _incidentIcons.entries.map((entry) {
                            final isSelected = _incidentType == entry.key;
                            return Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _incidentType = entry.key),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? theme.colorScheme.primary
                                        : theme
                                            .colorScheme.surfaceContainerHighest
                                            .withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSelected
                                          ? theme.colorScheme.primary
                                          : Colors.transparent,
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: theme.colorScheme.primary
                                                  .withValues(alpha: 0.3),
                                              blurRadius: 12,
                                              offset: const Offset(0, 4),
                                            ),
                                          ]
                                        : [],
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        entry.value,
                                        size: 18,
                                        color: isSelected
                                            ? theme.colorScheme.onPrimary
                                            : theme.colorScheme.onSurface
                                                .withValues(alpha: 0.8),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        entry.key.toUpperCase(),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                          letterSpacing: 0.5,
                                          color: isSelected
                                              ? theme.colorScheme.onPrimary
                                              : theme.colorScheme.onSurface
                                                  .withValues(alpha: 0.8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Severity Selector (Custom Segmented Control)
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          children: ['low', 'medium', 'high'].map((severityKey) {
                            final isSelected = _severity == severityKey;
                            final color = severityKey == 'low'
                                ? theme.colorScheme.primary
                                : severityKey == 'medium'
                                    ? theme.colorScheme.secondary
                                    : theme.colorScheme.error;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _severity = severityKey),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeOutCubic,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        isSelected ? color : Colors.transparent,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: color.withValues(
                                                alpha: 0.4,
                                              ),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : [],
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    severityKey.toUpperCase(),
                                    style: TextStyle(
                                      color: isSelected
                                          ? theme.colorScheme.onSurface
                                          : theme.colorScheme.onSurface
                                              .withValues(alpha: 0.6),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      const SizedBox(height: 120),
                    ],
                  ),
                ),

                // Helper Bar (Keyboard accessory style)
                Container(
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 12,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 12,
                  ),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor.withValues(alpha: 0.8),
                    border: Border(
                      top: BorderSide(
                        color: theme.dividerColor.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton.filled(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.add_photo_alternate_rounded,
                            size: 20),
                        style: IconButton.styleFrom(
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                          foregroundColor: theme.colorScheme.onSurface,
                          shape: const CircleBorder(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: _toggleLocation,
                        icon: Icon(
                          _useCurrentLocation
                              ? Icons.location_on_rounded
                              : Icons.location_off_rounded,
                          size: 20,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: _useCurrentLocation
                              ? theme.colorScheme.primary
                                  .withValues(alpha: 0.15)
                              : theme.colorScheme.surfaceContainerHighest,
                          foregroundColor: _useCurrentLocation
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                          shape: const CircleBorder(),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        "${_contentController.text.length} chars",
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.hintColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
