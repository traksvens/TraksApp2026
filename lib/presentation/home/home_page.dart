import 'dart:async';
import 'dart:ui';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';

import '../widgets/traks_logo.dart';
import '../widgets/post_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tracks_app/presentation/blocs/post/post_bloc.dart';
import 'package:tracks_app/presentation/blocs/post/post_state.dart';
import 'package:tracks_app/data/models/post_model.dart';
import 'package:tracks_app/presentation/blocs/post/post_event.dart';

import 'package:tracks_app/presentation/map/map_page.dart';
import 'package:tracks_app/presentation/blocs/auth/auth_bloc.dart';
import 'package:tracks_app/presentation/blocs/auth/auth_state.dart';
import 'package:tracks_app/presentation/post/create_post_page.dart';
import 'package:tracks_app/presentation/profile/profile_page.dart';
import 'package:tracks_app/presentation/widgets/post_loading_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tracks_app/presentation/subscription/subscription_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // If no user is logged in, fallback to a basic unverified layout.
      return _buildScaffold(context, theme, false);
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        bool isVerified = false;
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data();
          isVerified =
              data?['isVerified'] == true || data?['verified'] == 'True';
        }

        // Safety check: if currently on the premium tab but just got verified, jump to home
        if (isVerified && _currentIndex > 2) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() => _currentIndex = 0);
            }
          });
        }

        return _buildScaffold(context, theme, isVerified);
      },
    );
  }

  Widget _buildScaffold(
    BuildContext context,
    ThemeData theme,
    bool isVerified,
  ) {
    // Pages defined here to access context/setState
    final List<Widget> pages = [
      _HomeFeed(onProfileTap: () => setState(() => _currentIndex = 2)),
      const MapPage(),
      const ProfilePage(),
      if (!isVerified) const SubscriptionPage(),
    ];

    return MultiBlocListener(
      listeners: [
        BlocListener<PostBloc, PostState>(
          listenWhen: (previous, current) =>
              previous.errorMessage != current.errorMessage &&
              current.errorMessage != null,
          listener: (context, state) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.errorMessage!,
                  style: const TextStyle(fontFamily: 'Inter'),
                ),
                backgroundColor: theme.colorScheme.error, // Canopi Error Red
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16), // Rounded snackbar
                ),
              ),
            );
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor, // Canopi Dark Theme
        extendBody: true, // Crucial for floating navbar over content
        body: Stack(
          children: [
            // Ambient Radial Glow Backdrop
            Positioned(
              top: -100,
              left: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      theme.colorScheme.primary.withValues(alpha: 0.15),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 1.0],
                  ),
                ),
              ),
            ),

            IndexedStack(
              index: _currentIndex >= pages.length ? 0 : _currentIndex,
              children: pages,
            ),
          ],
        ),
        bottomNavigationBar: _buildModernNavbar(theme, isVerified),
      ),
    );
  }

  Widget _buildModernNavbar(ThemeData theme, bool isVerified) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        bottom: MediaQuery.paddingOf(context).bottom +
            20, // SafeArea + floating offset
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32), // Pill shape
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20), // Glassmorphism
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(
                  icon: Icons.home_rounded,
                  label: 'Home',
                  index: 0,
                  theme: theme,
                ),
                _buildNavItem(
                  icon: Icons.map_rounded,
                  label: 'Map',
                  index: 1,
                  theme: theme,
                ),
                _buildNavItem(
                  icon: Icons.person_rounded,
                  label: 'Profile',
                  index: 2,
                  theme: theme,
                ),
                if (!isVerified)
                  _buildNavItem(
                    icon: Icons.workspace_premium_rounded,
                    label: 'Premium',
                    index: 3,
                    theme: theme,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required ThemeData theme,
  }) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
                  .withValues(alpha: 0.15) // Canopi Green Accent
              : Colors.transparent,
          borderRadius: BorderRadius.circular(32),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: isSelected ? 26 : 24,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HomeFeed extends StatefulWidget {
  final VoidCallback onProfileTap;
  const _HomeFeed({required this.onProfileTap});

  @override
  State<_HomeFeed> createState() => _HomeFeedState();
}

class _HomeFeedState extends State<_HomeFeed> {
  // Filter State
  String? _selectedSeverity;
  DateTimeRange? _selectedDateRange;

  /// Filters posts based on selected severity and date range.
  List<PostModel> _filterPosts(List<PostModel> posts) {
    return posts.where((post) {
      if (_selectedSeverity != null &&
          post.severity.toLowerCase() != _selectedSeverity!.toLowerCase()) {
        return false;
      }

      if (_selectedDateRange != null) {
        final postDate = DateTime.tryParse(post.timestamp);
        if (postDate == null) return true;

        final start = _selectedDateRange!.start;
        final end = _selectedDateRange!.end
            .add(const Duration(days: 1))
            .subtract(const Duration(milliseconds: 1));

        if (postDate.isBefore(start) || postDate.isAfter(end)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: () async {
          final completer = Completer<void>();
          context.read<PostBloc>().add(FetchPosts(completer: completer));
          await completer.future;
        },
        backgroundColor: theme.colorScheme.surface,
        color: theme.colorScheme.primary,
        strokeWidth: 2.5,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            _buildAppBar(theme, context),
            _buildFilters(theme),
            SliverPadding(
              padding: const EdgeInsets.only(top: 8),
              sliver: BlocBuilder<PostBloc, PostState>(
                buildWhen: (prev, curr) =>
                    prev.status != curr.status || prev.posts != curr.posts,
                builder: (context, state) {
                  if (state.status == PostStatus.loading) {
                    return const PostLoadingWidget();
                  } else if (state.status == PostStatus.failure) {
                    return SliverFillRemaining(
                      child: Center(child: Text('Error: ${state.errorMessage}')),
                    );
                  } else if (state.posts.isEmpty) {
                    return const SliverFillRemaining(
                      child: Center(child: Text('No posts yet')),
                    );
                  }

                  // Apply Filters
                  final filteredPosts = _filterPosts(state.posts);

                  if (filteredPosts.isEmpty) {
                    return const SliverFillRemaining(
                      child: Center(child: Text('No posts match your filters')),
                    );
                  }

                  return SliverList.separated(
                    addAutomaticKeepAlives: false,
                    itemCount: filteredPosts.length,
                    itemBuilder: (context, index) {
                      return PostWidget(post: filteredPosts[index]);
                    },
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 4),
                  );
                },
              ),
            ),
            // Add spacing at bottom to ensure last items are scrollable above the solid navbar
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters(ThemeData theme) {
    return SliverToBoxAdapter(
      child: Container(
        height: 48,
        margin: const EdgeInsets.only(bottom: 12, top: 4),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          children: [
            // Date Filter Pill
            _buildFilterPill(
              context,
              label: _selectedDateRange == null
                  ? 'Date'
                  : '${_selectedDateRange!.start.month}/${_selectedDateRange!.start.day} - ${_selectedDateRange!.end.month}/${_selectedDateRange!.end.day}',
              icon: Icons.calendar_today_rounded,
              isSelected: _selectedDateRange != null,
              onTap: () async {
                final values = await showCalendarDatePicker2Dialog(
                  context: context,
                  config: CalendarDatePicker2WithActionButtonsConfig(
                    calendarType: CalendarDatePicker2Type.range,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    selectedDayHighlightColor: theme.colorScheme.primary,
                    weekdayLabels: [
                      'Sun',
                      'Mon',
                      'Tue',
                      'Wed',
                      'Thu',
                      'Fri',
                      'Sat'
                    ],
                    weekdayLabelTextStyle: TextStyle(
                      fontFamily: 'Inter',
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.54),
                      fontWeight: FontWeight.w600,
                    ),
                    controlsTextStyle: TextStyle(
                      fontFamily: 'Inter',
                      color: theme.colorScheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    dayTextStyle: TextStyle(
                      fontFamily: 'Inter',
                      color: theme.colorScheme.onSurface,
                    ),
                    selectedDayTextStyle: TextStyle(
                      fontFamily: 'Inter',
                      color: theme.scaffoldBackgroundColor,
                      fontWeight: FontWeight.bold,
                    ),
                    yearTextStyle: TextStyle(
                      fontFamily: 'Inter',
                      color: theme.colorScheme.onSurface,
                    ),
                    cancelButtonTextStyle: TextStyle(
                      fontFamily: 'Inter',
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.54),
                      fontWeight: FontWeight.w600,
                    ),
                    okButtonTextStyle: TextStyle(
                      fontFamily: 'Inter',
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  dialogSize: const Size(325, 400),
                  value: _selectedDateRange != null
                      ? [_selectedDateRange!.start, _selectedDateRange!.end]
                      : [],
                  borderRadius: BorderRadius.circular(24),
                  dialogBackgroundColor: theme.colorScheme.surface,
                );

                if (values != null && values.isNotEmpty) {
                  setState(() {
                    if (values.length == 2 && values[1] != null) {
                      _selectedDateRange =
                          DateTimeRange(start: values[0]!, end: values[1]!);
                    } else {
                      // If only one date selected or same date twice, set range to that single day
                      _selectedDateRange =
                          DateTimeRange(start: values[0]!, end: values[0]!);
                    }
                  });
                }
              },
              onClear: _selectedDateRange != null
                  ? () => setState(() => _selectedDateRange = null)
                  : null,
            ),
            const SizedBox(width: 8),

            // Vertical Divider
            Container(
              width: 1,
              height: 20,
              margin: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
              color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
            ),
            const SizedBox(width: 8),

            // Severity Filters
            _buildSeverityPill(theme, 'Critical', theme.colorScheme.error),
            const SizedBox(width: 8),
            _buildSeverityPill(theme, 'High', theme.colorScheme.secondary),
            const SizedBox(width: 8),
            _buildSeverityPill(theme, 'Medium', theme.colorScheme.tertiary),
            const SizedBox(width: 8),
            _buildSeverityPill(theme, 'Low', theme.colorScheme.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildSeverityPill(
    ThemeData theme,
    String severity,
    Color highlightColor,
  ) {
    final isSelected = _selectedSeverity == severity;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedSeverity = isSelected ? null : severity;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 0),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? highlightColor.withValues(alpha: 0.15)
              : theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.6), // Frosted glass dark
          borderRadius: BorderRadius.circular(32), // Pill shape squircle
          border: Border.all(
            color: isSelected
                ? highlightColor.withValues(alpha: 0.5)
                : theme.colorScheme.onSurface.withValues(alpha: 0.08),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: highlightColor.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: theme.colorScheme.surface.withValues(alpha: 0.1),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Text(
          severity,
          style: TextStyle(
            fontFamily: 'Inter',
            color: isSelected
                ? highlightColor
                : theme.colorScheme.onSurface.withValues(alpha: 0.7),
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 14,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterPill(
    BuildContext context, {
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {

    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.15)
              : theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.6), // Frosted glass dark
          borderRadius: BorderRadius.circular(32), // Pill shape squircle
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary.withValues(alpha: 0.5)
                : theme.colorScheme.onSurface.withValues(alpha: 0.08),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: theme.colorScheme.surface.withValues(alpha: 0.1),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.9),
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 14,
                letterSpacing: 0.2,
              ),
            ),
            if (onClear != null && isSelected) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onClear,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.close,
                      size: 12, color: theme.colorScheme.primary),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(ThemeData theme, BuildContext context) {
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      floating: false,
      elevation: 0,
      backgroundColor: Colors.transparent,
      centerTitle: true,
      leading: Padding(
        padding: const EdgeInsets.only(left: 16.0, top: 8, bottom: 8),
        child: GestureDetector(
          onTap: widget.onProfileTap,
          child: Hero(
            tag: 'home_profile_avatar',
            child: BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                String? photoUrl;
                String initials = "U";

                if (state is Authenticated) {
                  photoUrl = state.user.photoURL;
                  if (state.user.email != null &&
                      state.user.email!.isNotEmpty) {
                    initials = state.user.email![0].toUpperCase();
                  }
                }

                return Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                      width: 1.5,
                    ),
                    color: theme.colorScheme.surfaceContainerHighest,
                  ),
                  child: CircleAvatar(
                    backgroundColor: Colors.transparent,
                    backgroundImage:
                        photoUrl != null ? NetworkImage(photoUrl) : null,
                    radius: 18,
                    child: photoUrl == null
                        ? Text(
                            initials,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          )
                        : null,
                  ),
                );
              },
            ),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0, top: 8, bottom: 8),
          child: Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IconButton.filled(
              onPressed: () {
                Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CreatePostPage()));
              },
              icon: const Icon(Icons.add_rounded, size: 22),
              style: IconButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.scaffoldBackgroundColor,
                minimumSize: const Size(44, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14), // Modern squircle-like
                ),
              ),
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(bottom: 12),
        centerTitle: true,
        title: LayoutBuilder(
          builder: (context, constraints) {
            // Calculate a scaling factor based on the height
            // Expanded height is 140, collapsed is ~56 + status bar
            final double height = constraints.maxHeight;
            final bool isCollapsed = height <= kToolbarHeight + (MediaQuery.of(context).padding.top);
            
            return TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 42, end: isCollapsed ? 26 : 42),
              duration: const Duration(milliseconds: 200),
              builder: (context, size, child) {
                return TraksLogo(fontSize: size);
              },
            );
          },
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Glassmorphism background
            ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: Container(
                  color: theme.scaffoldBackgroundColor.withValues(alpha: 0.85),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
