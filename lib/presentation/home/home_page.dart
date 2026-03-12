import 'dart:ui';

import '../widgets/traks_logo.dart';
import '../widgets/post_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tracks_app/presentation/blocs/post/post_bloc.dart';
import 'package:tracks_app/presentation/blocs/post/post_state.dart';
import 'package:tracks_app/data/models/post_model.dart';
import 'package:flutter/cupertino.dart';
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
                content: Text(state.errorMessage!),
                backgroundColor: theme.colorScheme.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        extendBody: false,
        body: IndexedStack(
          index: _currentIndex >= pages.length ? 0 : _currentIndex,
          children: pages,
        ),
        bottomNavigationBar: _buildModernNavbar(theme, isVerified),
      ),
    );
  }

  Widget _buildModernNavbar(ThemeData theme, bool isVerified) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.paddingOf(context).bottom, // SafeArea handling
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
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
              ? theme.primaryColor.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: isSelected ? 26 : 24,
              color: isSelected
                  ? theme.primaryColor
                  : theme.iconTheme.color?.withValues(alpha: 0.6),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.primaryColor,
                  fontWeight: FontWeight.bold,
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
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(theme, context),
          _buildFilters(theme),
          CupertinoSliverRefreshControl(
            onRefresh: () async {
              context.read<PostBloc>().add(const FetchPosts());
              await Future.delayed(const Duration(seconds: 1));
            },
          ),
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
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
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
                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                  builder: (context, child) {
                    return Theme(
                      data: theme.copyWith(
                        colorScheme: theme.colorScheme.copyWith(
                          primary: theme.primaryColor,
                          onPrimary: Colors.white,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (picked != null) {
                  setState(() => _selectedDateRange = picked);
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
              color: theme.dividerColor.withValues(alpha: 0.3),
            ),
            const SizedBox(width: 8),

            // Severity Filters
            _buildSeverityPill(theme, 'Critical', Colors.redAccent.shade400),
            const SizedBox(width: 8),
            _buildSeverityPill(theme, 'High', Colors.orangeAccent.shade400),
            const SizedBox(width: 8),
            _buildSeverityPill(theme, 'Medium', Colors.amber.shade400),
            const SizedBox(width: 8),
            _buildSeverityPill(theme, 'Low', Colors.greenAccent.shade400),
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
    final isDark = theme.brightness == Brightness.dark;

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
              ? highlightColor
              : (isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.03)),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? highlightColor
                : theme.dividerColor.withValues(alpha: 0.1),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: highlightColor.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Text(
          severity,
          style: TextStyle(
            color: isSelected
                ? (highlightColor.computeLuminance() > 0.5
                      ? Colors.black87
                      : Colors.white)
                : theme.colorScheme.onSurface.withValues(alpha: 0.8),
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
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : (isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.03)),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.dividerColor.withValues(alpha: 0.1),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? Colors.white
                  : theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
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
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 12, color: Colors.white),
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
      pinned: true,
      floating: true,
      elevation: 0,
      backgroundColor: theme.scaffoldBackgroundColor.withValues(alpha: 0.95),
      leadingWidth: 64,
      leading: Padding(
        padding: const EdgeInsets.only(left: 16.0, top: 10, bottom: 10),
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
                      color: theme.dividerColor.withValues(alpha: 0.1),
                      width: 1.5,
                    ),
                    color: theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.5,
                    ),
                  ),
                  child: CircleAvatar(
                    backgroundColor: Colors.transparent,
                    backgroundImage: photoUrl != null
                        ? NetworkImage(photoUrl)
                        : null,
                    radius: 18,
                    child: photoUrl == null
                        ? Text(
                            initials,
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
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
      centerTitle: false,
      title: const TraksLogo(fontSize: 26),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0, top: 10, bottom: 10),
          child: FilledButton.icon(
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const CreatePostPage()));
            },
            style: FilledButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text(
              'Add Trak',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.1,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
