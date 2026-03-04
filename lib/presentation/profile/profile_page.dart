import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tracks_app/presentation/blocs/auth/auth_bloc.dart';
import 'package:tracks_app/presentation/blocs/auth/auth_event.dart';
import 'package:tracks_app/presentation/blocs/auth/auth_state.dart';
import 'package:tracks_app/core/theme/theme_controller.dart';
import 'package:tracks_app/core/theme/app_colors.dart';
import 'package:tracks_app/presentation/sos/sos_customization_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final theme = Theme.of(context);
        final user = (state is Authenticated) ? state.user : null;

        final displayName = user?.displayName?.isNotEmpty == true
            ? user!.displayName!
            : (user?.email?.isNotEmpty == true
                  ? user!.email!.split('@').first
                  : "Anonymous");

        final email = user?.email ?? "";
        final photoUrl = user?.photoURL;

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 1. Immersive Header
              SliverAppBar(
                expandedHeight: 320,
                pinned: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                stretch: true,
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [
                    StretchMode.zoomBackground,
                    StretchMode.blurBackground,
                  ],
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Subdued Immersive Background Gradient
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              theme.primaryColor.withValues(alpha: 0.15),
                              theme.colorScheme.secondary.withValues(
                                alpha: 0.05,
                              ),
                              theme.scaffoldBackgroundColor,
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),
                      // Glassmorphism Blur Layer
                      ClipRect(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                          child: Container(
                            color: theme.scaffoldBackgroundColor.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                      ),
                      // User Info Layer
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 32.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      theme.primaryColor.withValues(alpha: 0.8),
                                      theme.primaryColor.withValues(alpha: 0.2),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: theme.primaryColor.withValues(
                                        alpha: 0.2,
                                      ),
                                      blurRadius: 24,
                                      spreadRadius: 4,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: theme.scaffoldBackgroundColor,
                                      width: 3,
                                    ),
                                  ),
                                  child: CircleAvatar(
                                    radius: 54,
                                    backgroundColor: theme.colorScheme.surface,
                                    backgroundImage: photoUrl != null
                                        ? NetworkImage(photoUrl)
                                        : null,
                                    child: photoUrl == null
                                        ? Text(
                                            displayName
                                                .substring(0, 1)
                                                .toUpperCase(),
                                            style: theme
                                                .textTheme
                                                .headlineMedium
                                                ?.copyWith(
                                                  color: theme.primaryColor,
                                                ),
                                          )
                                        : null,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                displayName,
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (email.isNotEmpty)
                                Text(
                                  email,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.textTheme.bodyMedium?.color
                                        ?.withValues(alpha: 0.6),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. SOS Button Section (Premium Action Pattern)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFFDC2626,
                          ).withValues(alpha: 0.25),
                          blurRadius: 24,
                          spreadRadius: -4,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        // TODO: Implement SOS action
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(
                          0xFFDC2626,
                        ), // Premium Red 600
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.warning_amber_rounded, size: 28),
                          const SizedBox(width: 12),
                          Text(
                            "Emergency SOS",
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // 3. Settings Section
              SliverToBoxAdapter(
                child: ValueListenableBuilder<ThemeState>(
                  valueListenable: ThemeController.instance,
                  builder: (context, themeState, child) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),
                          _buildSectionTitle(theme, "APPEARANCE"),
                          const SizedBox(height: 16),
                          _buildThemeModeSegmentedControl(
                            theme,
                            themeState.mode,
                          ),
                          const SizedBox(height: 32),
                          _buildSectionTitle(theme, "COLOR THEME"),
                          const SizedBox(height: 16),
                          _buildColorSwatchList(theme, themeState),
                          const SizedBox(height: 48),
                          _buildSectionTitle(theme, "ACCOUNT"),
                          const SizedBox(height: 16),
                          _buildSettingTile(
                            theme: theme,
                            icon: Icons.emergency_share_outlined,
                            title: "SOS Customization",
                            subtitle:
                                "Configure emergency contacts and message",
                            iconColor: const Color(0xFFDC2626),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SosCustomizationPage(),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          _buildSettingTile(
                            theme: theme,
                            icon: Icons.notifications_none_rounded,
                            title: "Notifications",
                            subtitle: "Manage alerts & push configurations",
                          ),
                          const SizedBox(height: 12),
                          _buildSettingTile(
                            theme: theme,
                            icon: Icons.shield_outlined,
                            title: "Privacy & Security",
                            subtitle: "Biometrics, Password, Sessions",
                          ),
                          const SizedBox(height: 12),
                          _buildSettingTile(
                            theme: theme,
                            icon: Icons.logout_rounded,
                            title: "Log Out",
                            iconColor: const Color(0xFFEF4444),
                            textColor: const Color(0xFFEF4444),
                            showChevron: false,
                            onTap: () {
                              context.read<AuthBloc>().add(SignOutRequested());
                            },
                          ),
                          const SizedBox(
                            height: 120,
                          ), // Spacing for Navbar + Floating Button
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Text(
        title,
        style: theme.textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: theme.disabledColor,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required ThemeData theme,
    required IconData icon,
    required String title,
    VoidCallback? onTap,
    String? subtitle,
    Widget? trailing,
    Color? iconColor,
    Color? textColor,
    bool showChevron = true,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 24,
              spreadRadius: -4,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (iconColor ?? theme.primaryColor).withValues(
                  alpha: 0.08,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: iconColor ?? theme.primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: textColor,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 13,
                        color: theme.textTheme.bodyMedium?.color?.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null)
              trailing
            else if (showChevron)
              Icon(
                Icons.chevron_right_rounded,
                color: theme.dividerColor.withValues(alpha: 0.5),
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorSwatchList(ThemeData theme, ThemeState themeState) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 24,
            spreadRadius: -4,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildColorSwatch(
            theme,
            AppColorTheme.teal,
            AppColors.themeTeal,
            themeState,
          ),
          _buildColorSwatch(
            theme,
            AppColorTheme.red,
            AppColors.themeRed,
            themeState,
          ),
          _buildColorSwatch(
            theme,
            AppColorTheme.brown,
            AppColors.themeBrown,
            themeState,
          ),
          _buildColorSwatch(
            theme,
            AppColorTheme.pink,
            AppColors.themePink,
            themeState,
          ),
        ],
      ),
    );
  }

  Widget _buildColorSwatch(
    ThemeData theme,
    AppColorTheme colorTheme,
    Color displayColor,
    ThemeState themeState,
  ) {
    final isSelected = themeState.colorTheme == colorTheme;
    final isDark = themeState.mode == ThemeMode.dark;

    return GestureDetector(
      onTap: () {
        ThemeController.instance.setColorTheme(colorTheme);
      },
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: displayColor,
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(
                  color: isDark ? Colors.white : Colors.black,
                  width: 3,
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: displayColor.withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: isSelected
            ? Icon(Icons.check, color: isDark ? Colors.white : Colors.white)
            : null,
      ),
    );
  }

  Widget _buildThemeModeSegmentedControl(
    ThemeData theme,
    ThemeMode currentMode,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 24,
            spreadRadius: -4,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: SegmentedButton<ThemeMode>(
        segments: const [
          ButtonSegment(
            value: ThemeMode.light,
            icon: Icon(Icons.wb_sunny_rounded, size: 18),
            label: Text("Light"),
          ),
          ButtonSegment(
            value: ThemeMode.system,
            icon: Icon(Icons.brightness_auto_rounded, size: 18),
            label: Text("Auto"),
          ),
          ButtonSegment(
            value: ThemeMode.dark,
            icon: Icon(Icons.nights_stay_rounded, size: 18),
            label: Text("Dark"),
          ),
        ],
        selected: {currentMode},
        onSelectionChanged: (Set<ThemeMode> newSelection) {
          ThemeController.instance.setTheme(newSelection.first);
        },
        style: ButtonStyle(
          visualDensity: VisualDensity.comfortable,
          backgroundColor: WidgetStateProperty.resolveWith<Color>((
            Set<WidgetState> states,
          ) {
            if (states.contains(WidgetState.selected)) {
              return theme.primaryColor.withValues(alpha: 0.15);
            }
            return Colors.transparent;
          }),
          foregroundColor: WidgetStateProperty.resolveWith<Color>((
            Set<WidgetState> states,
          ) {
            if (states.contains(WidgetState.selected)) {
              return theme.primaryColor;
            }
            return theme.colorScheme.onSurface;
          }),
          side: const WidgetStatePropertyAll(BorderSide.none),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ),
    );
  }
}
